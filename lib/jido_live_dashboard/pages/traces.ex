defmodule JidoLiveDashboard.Pages.Traces do
  @moduledoc """
  Traces page for viewing Jido telemetry events.

  Displays recent telemetry events from the trace buffer with
  correlation by trace_id for debugging signal flows.
  """

  use Phoenix.LiveDashboard.PageBuilder

  alias JidoLiveDashboard.TraceBuffer

  @impl true
  def menu_link(_session, _opts) do
    {:ok, "Traces"}
  end

  @impl true
  def render(assigns) do
    {:ok, stats} = TraceBuffer.stats()
    {:ok, events} = TraceBuffer.list_events(limit: 100)

    # Group events by trace_id for the trace list view
    trace_groups = group_by_trace(events)

    # Check if viewing a specific trace
    selected_trace_id = assigns[:params]["trace_id"]
    selected_trace_events = get_trace_events(selected_trace_id)

    assigns =
      assigns
      |> Map.put(:stats, stats)
      |> Map.put(:events, events)
      |> Map.put(:trace_groups, trace_groups)
      |> Map.put(:selected_trace_id, selected_trace_id)
      |> Map.put(:selected_trace_events, selected_trace_events)

    ~H"""
    <div class="phx-dashboard-header">
      <h1>Jido Traces</h1>
      <p class="text-gray-600">View telemetry events and trace correlation</p>
    </div>

    <!-- Stats Banner -->
    <div class="px-4 py-2 bg-gray-50 border-b text-sm text-gray-600 flex justify-between items-center">
      <div>
        Events: <%= @stats.count %> / <%= @stats.max_size %>
        <span class="mx-2">|</span>
        Unique traces: <%= @stats.trace_count %>
        <span class="mx-2">|</span>
        Memory: <%= format_bytes(@stats.memory_bytes) %>
      </div>
      <button
        phx-click="clear_traces"
        class="text-xs px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200"
      >
        Clear Buffer
      </button>
    </div>

    <div class="p-4">
      <%= if @selected_trace_id do %>
        <!-- Trace Detail View -->
        <div class="mb-4">
          <button
            phx-click="nav"
            phx-value-trace_id=""
            class="text-blue-600 hover:text-blue-800 text-sm"
          >
            ← Back to all events
          </button>
        </div>

        <div class="bg-white shadow rounded-lg overflow-hidden">
          <div class="px-4 py-3 bg-gray-50 border-b">
            <h2 class="text-lg font-semibold">Trace: <%= @selected_trace_id %></h2>
            <p class="text-sm text-gray-500"><%= length(@selected_trace_events) %> events</p>
          </div>

          <%= if length(@selected_trace_events) > 0 do %>
            <div class="divide-y divide-gray-200">
              <%= for event <- @selected_trace_events do %>
                <div class="p-4 hover:bg-gray-50">
                  <div class="flex items-start justify-between">
                    <div>
                      <span class={"inline-block text-xs px-2 py-0.5 rounded mr-2 #{event_type_class(event.event)}"}>
                        <%= format_event_name(event.event) %>
                      </span>
                      <span class="text-xs text-gray-500"><%= format_time(event.timestamp) %></span>
                    </div>
                    <%= if event.agent_id do %>
                      <span class="text-xs bg-blue-100 text-blue-800 px-2 py-0.5 rounded">
                        <%= event.agent_id %>
                      </span>
                    <% end %>
                  </div>

                  <%= if event.span_id do %>
                    <div class="mt-1 text-xs text-gray-500">
                      span: <%= event.span_id %>
                      <%= if event.parent_span_id do %>
                        <span class="mx-1">→</span>
                        parent: <%= event.parent_span_id %>
                      <% end %>
                    </div>
                  <% end %>

                  <%= if map_size(event.measurements) > 0 do %>
                    <div class="mt-2">
                      <div class="text-xs text-gray-500 mb-1">Measurements:</div>
                      <div class="flex flex-wrap gap-2">
                        <%= for {key, value} <- event.measurements do %>
                          <span class="text-xs bg-gray-100 px-2 py-0.5 rounded">
                            <%= key %>: <%= format_measurement(key, value) %>
                          </span>
                        <% end %>
                      </div>
                    </div>
                  <% end %>

                  <%= if map_size(event.metadata) > 0 do %>
                    <details class="mt-2">
                      <summary class="text-xs text-gray-500 cursor-pointer">Metadata</summary>
                      <pre class="mt-1 text-xs bg-gray-50 p-2 rounded overflow-x-auto"><%= inspect(event.metadata, pretty: true, limit: 20) %></pre>
                    </details>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% else %>
            <div class="p-8 text-center text-gray-500">
              No events found for this trace.
            </div>
          <% end %>
        </div>

      <% else %>
        <!-- Events List View -->
        <%= if length(@events) > 0 do %>
          <div class="bg-white shadow rounded-lg overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Time</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Event</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Agent</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Trace</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Duration</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for event <- @events do %>
                  <tr class="hover:bg-gray-50">
                    <td class="px-4 py-2 whitespace-nowrap text-xs text-gray-500">
                      <%= format_time(event.timestamp) %>
                    </td>
                    <td class="px-4 py-2 whitespace-nowrap">
                      <span class={"inline-block text-xs px-2 py-0.5 rounded #{event_type_class(event.event)}"}>
                        <%= format_event_name(event.event) %>
                      </span>
                    </td>
                    <td class="px-4 py-2 whitespace-nowrap text-sm text-gray-900">
                      <%= event.agent_id || "—" %>
                    </td>
                    <td class="px-4 py-2 whitespace-nowrap">
                      <%= if event.trace_id do %>
                        <button
                          phx-click="nav"
                          phx-value-trace_id={event.trace_id}
                          class="text-xs text-blue-600 hover:text-blue-800 font-mono"
                        >
                          <%= String.slice(event.trace_id, 0..7) %>...
                        </button>
                      <% else %>
                        <span class="text-xs text-gray-400">—</span>
                      <% end %>
                    </td>
                    <td class="px-4 py-2 whitespace-nowrap text-xs text-gray-500">
                      <%= format_duration(event.measurements[:duration]) %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>

          <!-- Trace Groups Summary -->
          <%= if length(@trace_groups) > 0 do %>
            <div class="mt-6 bg-white shadow rounded-lg overflow-hidden">
              <div class="px-4 py-3 bg-gray-50 border-b">
                <h2 class="text-lg font-semibold">Recent Traces</h2>
                <p class="text-sm text-gray-500">Grouped by trace_id</p>
              </div>

              <div class="divide-y divide-gray-200">
                <%= for {trace_id, group_events} <- Enum.take(@trace_groups, 10) do %>
                  <div class="px-4 py-3 hover:bg-gray-50 flex justify-between items-center">
                    <div>
                      <button
                        phx-click="nav"
                        phx-value-trace_id={trace_id}
                        class="font-mono text-sm text-blue-600 hover:text-blue-800"
                      >
                        <%= trace_id %>
                      </button>
                      <span class="text-xs text-gray-500 ml-2">
                        <%= length(group_events) %> events
                      </span>
                    </div>
                    <div class="text-xs text-gray-500">
                      <%= format_time(List.first(group_events).timestamp) %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

        <% else %>
          <div class="bg-white shadow rounded-lg p-8 text-center">
            <p class="text-gray-500">No telemetry events captured yet.</p>
            <p class="text-sm text-gray-400 mt-2">
              Events will appear here as Jido processes signals and executes directives.
            </p>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp get_trace_events(nil), do: []

  defp get_trace_events(trace_id) do
    case TraceBuffer.get_trace(trace_id) do
      {:ok, events} -> events
      _ -> []
    end
  end

  defp group_by_trace(events) do
    events
    |> Enum.filter(& &1.trace_id)
    |> Enum.group_by(& &1.trace_id)
    |> Enum.sort_by(fn {_id, evts} -> -List.first(evts).id end)
  end

  defp format_event_name(event) when is_list(event) do
    event
    |> Enum.drop(1)
    |> Enum.map(&Atom.to_string/1)
    |> Enum.join(".")
  end

  defp format_event_name(event), do: inspect(event)

  defp event_type_class(event) when is_list(event) do
    cond do
      :exception in event -> "bg-red-100 text-red-800"
      :stop in event -> "bg-green-100 text-green-800"
      :start in event -> "bg-blue-100 text-blue-800"
      true -> "bg-gray-100 text-gray-800"
    end
  end

  defp event_type_class(_), do: "bg-gray-100 text-gray-800"

  defp format_time(nil), do: "—"

  defp format_time(dt) do
    Calendar.strftime(dt, "%H:%M:%S.%f")
    |> String.slice(0..11)
  end

  defp format_duration(nil), do: "—"
  defp format_duration(ns) when is_integer(ns) and ns < 1_000, do: "#{ns}ns"
  defp format_duration(ns) when is_integer(ns) and ns < 1_000_000, do: "#{Float.round(ns / 1_000, 1)}μs"
  defp format_duration(ns) when is_integer(ns), do: "#{Float.round(ns / 1_000_000, 2)}ms"
  defp format_duration(_), do: "—"

  defp format_measurement(:duration, value), do: format_duration(value)
  defp format_measurement(:system_time, value) when is_integer(value), do: "#{div(value, 1_000_000)}ms"
  defp format_measurement(_key, value) when is_integer(value), do: Integer.to_string(value)
  defp format_measurement(_key, value) when is_float(value), do: Float.to_string(Float.round(value, 2))
  defp format_measurement(_key, value), do: inspect(value)

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_bytes(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_bytes(bytes), do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"
end
