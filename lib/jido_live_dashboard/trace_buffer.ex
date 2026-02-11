defmodule JidoLiveDashboard.TraceBuffer do
  @moduledoc """
  ETS-backed ring buffer for storing Jido telemetry events.

  TraceBuffer automatically attaches to Jido telemetry events and stores them
  in a ring buffer for inspection via the dashboard. Events are correlated
  by trace_id/span_id when available.

  ## Configuration

      config :jido_live_dashboard,
        trace_buffer_size: 500  # default

  ## Usage

      # List recent events
      {:ok, events} = JidoLiveDashboard.TraceBuffer.list_events(limit: 100)

      # Get all events for a trace
      {:ok, events} = JidoLiveDashboard.TraceBuffer.get_trace("trace-id-here")

      # Get buffer statistics
      {:ok, stats} = JidoLiveDashboard.TraceBuffer.stats()
  """

  use GenServer

  require Logger

  @table_name :jido_live_dashboard_traces
  @default_buffer_size 500

  @telemetry_events [
    [:jido, :agent_server, :signal, :start],
    [:jido, :agent_server, :signal, :stop],
    [:jido, :agent_server, :signal, :exception],
    [:jido, :agent_server, :directive, :start],
    [:jido, :agent_server, :directive, :stop],
    [:jido, :agent_server, :directive, :exception],
    [:jido, :agent, :cmd, :start],
    [:jido, :agent, :cmd, :stop],
    [:jido, :agent, :cmd, :exception],
    [:jido, :agent, :strategy, :init, :start],
    [:jido, :agent, :strategy, :init, :stop],
    [:jido, :agent, :strategy, :cmd, :start],
    [:jido, :agent, :strategy, :cmd, :stop]
  ]

  @type event :: %{
          id: integer(),
          timestamp: DateTime.t(),
          event: [atom()],
          measurements: map(),
          metadata: map(),
          trace_id: String.t() | nil,
          span_id: String.t() | nil,
          parent_span_id: String.t() | nil,
          agent_id: String.t() | nil
        }

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Starts the TraceBuffer GenServer.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Lists recent events from the buffer.

  ## Options

  - `:limit` - Maximum number of events to return (default: 100)
  - `:offset` - Number of events to skip (default: 0)

  ## Examples

      {:ok, events} = JidoLiveDashboard.TraceBuffer.list_events(limit: 50)
  """
  @spec list_events(keyword()) :: {:ok, [event()]}
  def list_events(opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    offset = Keyword.get(opts, :offset, 0)

    events =
      @table_name
      |> :ets.tab2list()
      |> Enum.sort_by(fn {id, _event} -> -id end)
      |> Enum.drop(offset)
      |> Enum.take(limit)
      |> Enum.map(fn {_id, event} -> event end)

    {:ok, events}
  rescue
    ArgumentError -> {:ok, []}
  end

  @doc """
  Gets all events for a specific trace_id.

  ## Examples

      {:ok, events} = JidoLiveDashboard.TraceBuffer.get_trace("abc123")
  """
  @spec get_trace(String.t()) :: {:ok, [event()]}
  def get_trace(trace_id) when is_binary(trace_id) do
    events =
      @table_name
      |> :ets.tab2list()
      |> Enum.filter(fn {_id, event} -> event.trace_id == trace_id end)
      |> Enum.sort_by(fn {id, _event} -> id end)
      |> Enum.map(fn {_id, event} -> event end)

    {:ok, events}
  rescue
    ArgumentError -> {:ok, []}
  end

  @doc """
  Gets events for a specific agent_id.

  ## Examples

      {:ok, events} = JidoLiveDashboard.TraceBuffer.get_agent_events("agent-123")
  """
  @spec get_agent_events(String.t()) :: {:ok, [event()]}
  def get_agent_events(agent_id) when is_binary(agent_id) do
    events =
      @table_name
      |> :ets.tab2list()
      |> Enum.filter(fn {_id, event} -> event.agent_id == agent_id end)
      |> Enum.sort_by(fn {id, _event} -> -id end)
      |> Enum.map(fn {_id, event} -> event end)

    {:ok, events}
  rescue
    ArgumentError -> {:ok, []}
  end

  @doc """
  Returns buffer statistics.

  ## Examples

      {:ok, %{count: 150, max_size: 500, trace_count: 12}} = JidoLiveDashboard.TraceBuffer.stats()
  """
  @spec stats() :: {:ok, map()}
  def stats do
    info = :ets.info(@table_name)
    count = Keyword.get(info, :size, 0)

    trace_ids =
      @table_name
      |> :ets.tab2list()
      |> Enum.map(fn {_id, event} -> event.trace_id end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    max_size = Application.get_env(:jido_live_dashboard, :trace_buffer_size, @default_buffer_size)

    {:ok,
     %{
       count: count,
       max_size: max_size,
       trace_count: length(trace_ids),
       memory_bytes: Keyword.get(info, :memory, 0) * :erlang.system_info(:wordsize)
     }}
  rescue
    ArgumentError -> {:ok, %{count: 0, max_size: @default_buffer_size, trace_count: 0, memory_bytes: 0}}
  end

  @doc """
  Clears all events from the buffer.
  """
  @spec clear() :: :ok
  def clear do
    :ets.delete_all_objects(@table_name)
    :ok
  rescue
    ArgumentError -> :ok
  end

  @doc """
  Manually record an event (primarily for testing).
  """
  @spec record_event([atom()], map(), map()) :: :ok
  def record_event(event_name, measurements, metadata) do
    GenServer.cast(__MODULE__, {:record, event_name, measurements, metadata})
  end

  # ---------------------------------------------------------------------------
  # GenServer Callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(opts) do
    table = :ets.new(@table_name, [:named_table, :ordered_set, :public, read_concurrency: true])

    max_size =
      Keyword.get(
        opts,
        :buffer_size,
        Application.get_env(:jido_live_dashboard, :trace_buffer_size, @default_buffer_size)
      )

    attach_telemetry()

    {:ok, %{table: table, counter: 0, max_size: max_size}}
  end

  @impl true
  def handle_cast({:record, event_name, measurements, metadata}, state) do
    state = insert_event(state, event_name, measurements, metadata)
    {:noreply, state}
  end

  @impl true
  def handle_info({:telemetry_event, event_name, measurements, metadata}, state) do
    state = insert_event(state, event_name, measurements, metadata)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, _state) do
    :telemetry.detach("jido-live-dashboard-trace-buffer")
    :ok
  end

  # ---------------------------------------------------------------------------
  # Internal
  # ---------------------------------------------------------------------------

  defp attach_telemetry do
    :telemetry.attach_many(
      "jido-live-dashboard-trace-buffer",
      @telemetry_events,
      &__MODULE__.handle_telemetry_event/4,
      nil
    )
  end

  @doc false
  def handle_telemetry_event(event_name, measurements, metadata, _config) do
    if Process.whereis(__MODULE__) do
      send(__MODULE__, {:telemetry_event, event_name, measurements, metadata})
    end
  end

  defp insert_event(state, event_name, measurements, metadata) do
    counter = state.counter + 1

    event = %{
      id: counter,
      timestamp: DateTime.utc_now(),
      event: event_name,
      measurements: measurements,
      metadata: sanitize_metadata(metadata),
      trace_id: extract_trace_id(metadata),
      span_id: extract_span_id(metadata),
      parent_span_id: extract_parent_span_id(metadata),
      agent_id: extract_agent_id(metadata)
    }

    :ets.insert(@table_name, {counter, event})

    # Prune old events if over max size
    state = %{state | counter: counter}
    maybe_prune(state)
  end

  defp maybe_prune(%{counter: counter, max_size: max_size} = state) when counter > max_size do
    cutoff = counter - max_size
    :ets.select_delete(@table_name, [{{:"$1", :_}, [{:"=<", :"$1", cutoff}], [true]}])
    state
  end

  defp maybe_prune(state), do: state

  defp extract_trace_id(metadata) do
    metadata[:trace_id] || get_in(metadata, [:trace, :trace_id]) || nil
  end

  defp extract_span_id(metadata) do
    metadata[:span_id] || get_in(metadata, [:trace, :span_id]) || nil
  end

  defp extract_parent_span_id(metadata) do
    metadata[:parent_span_id] || get_in(metadata, [:trace, :parent_span_id]) || nil
  end

  defp extract_agent_id(metadata) do
    case metadata[:agent_id] do
      nil -> nil
      id when is_binary(id) -> id
      id -> inspect(id)
    end
  end

  defp sanitize_metadata(metadata) do
    metadata
    |> Map.new()
    |> Map.drop([:trace])
    |> Enum.map(fn {k, v} -> {k, sanitize_value(v)} end)
    |> Map.new()
  end

  defp sanitize_value(v) when is_pid(v), do: inspect(v)
  defp sanitize_value(v) when is_reference(v), do: inspect(v)
  defp sanitize_value(v) when is_function(v), do: inspect(v)
  defp sanitize_value(v) when is_port(v), do: inspect(v)
  defp sanitize_value(%{__struct__: _} = v), do: inspect(v)

  defp sanitize_value(v) when is_map(v) do
    Enum.map(v, fn {k, val} -> {k, sanitize_value(val)} end) |> Map.new()
  end

  defp sanitize_value(v) when is_list(v), do: Enum.map(v, &sanitize_value/1)
  defp sanitize_value(v), do: v
end
