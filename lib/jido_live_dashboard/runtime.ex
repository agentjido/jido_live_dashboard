defmodule JidoLiveDashboard.Runtime do
  @moduledoc """
  Runtime introspection for Jido infrastructure.

  Provides functions to query running Jido processes including AgentServers,
  WorkerPools, and InstanceManagers. Used by dashboard pages to display
  live process information.

  ## Usage

      # List all running agent servers
      {:ok, agents} = JidoLiveDashboard.Runtime.list_agent_servers()

      # Get status for a specific agent
      {:ok, status} = JidoLiveDashboard.Runtime.get_agent_status(pid)

      # Get worker pool status
      {:ok, pools} = JidoLiveDashboard.Runtime.list_worker_pools(MyApp.Jido, [:fast_search])
  """

  @type agent_info :: %{
          pid: pid(),
          id: term(),
          module: module() | nil,
          alive: boolean()
        }

  @type pool_status :: %{
          name: atom(),
          state: atom(),
          available: non_neg_integer(),
          overflow: non_neg_integer(),
          checked_out: non_neg_integer()
        }

  @type manager_stats :: %{
          name: atom(),
          count: non_neg_integer(),
          keys: [term()]
        }

  # ---------------------------------------------------------------------------
  # Agent Servers
  # ---------------------------------------------------------------------------

  @doc """
  Lists all running AgentServer processes from the default supervisor.

  Returns a list of basic agent info maps suitable for list views.
  """
  @spec list_agent_servers() :: {:ok, [agent_info()]}
  def list_agent_servers do
    list_agent_servers(Jido.AgentSupervisor)
  end

  @doc """
  Lists all running AgentServer processes from a specific supervisor.

  Accepts either a supervisor name atom or a Jido instance atom.
  """
  @spec list_agent_servers(atom()) :: {:ok, [agent_info()]}
  def list_agent_servers(supervisor_or_instance) when is_atom(supervisor_or_instance) do
    supervisor = resolve_supervisor(supervisor_or_instance)

    case Process.whereis(supervisor) do
      nil ->
        {:ok, []}

      _pid ->
        agents =
          case DynamicSupervisor.which_children(supervisor) do
            children when is_list(children) ->
              children
              |> Enum.filter(fn {_id, pid, _type, _modules} -> is_pid(pid) end)
              |> Enum.map(&child_to_agent_info/1)

            _ ->
              []
          end

        {:ok, agents}
    end
  rescue
    _ -> {:ok, []}
  catch
    :exit, _ -> {:ok, []}
  end

  @doc """
  Gets the full status for a specific AgentServer process.

  Uses Jido.AgentServer.status/1 for lightweight introspection.
  """
  @spec get_agent_status(pid()) :: {:ok, map()} | {:error, term()}
  def get_agent_status(pid) when is_pid(pid) do
    if Process.alive?(pid) do
      case Jido.AgentServer.status(pid) do
        {:ok, status} -> {:ok, status_to_map(status)}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :not_alive}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc """
  Gets the full state for a specific AgentServer process.

  WARNING: This can return large payloads. Use sparingly (detail views only).
  """
  @spec get_agent_state(pid()) :: {:ok, map()} | {:error, term()}
  def get_agent_state(pid) when is_pid(pid) do
    if Process.alive?(pid) do
      case Jido.AgentServer.state(pid) do
        {:ok, state} -> {:ok, state_to_map(state)}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :not_alive}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  # ---------------------------------------------------------------------------
  # Worker Pools
  # ---------------------------------------------------------------------------

  @doc """
  Lists worker pool status for the given Jido instance and pool names.

  ## Examples

      {:ok, pools} = JidoLiveDashboard.Runtime.list_worker_pools(MyApp.Jido, [:fast_search, :planner])
  """
  @spec list_worker_pools(atom(), [atom()]) :: {:ok, [pool_status()]}
  def list_worker_pools(jido_instance, pool_names) when is_atom(jido_instance) and is_list(pool_names) do
    pools =
      Enum.map(pool_names, fn pool_name ->
        try do
          status = Jido.Agent.WorkerPool.status(jido_instance, pool_name)
          Map.put(status, :name, pool_name)
        rescue
          _ -> %{name: pool_name, state: :error, available: 0, overflow: 0, checked_out: 0}
        catch
          :exit, _ -> %{name: pool_name, state: :error, available: 0, overflow: 0, checked_out: 0}
        end
      end)

    {:ok, pools}
  end

  # ---------------------------------------------------------------------------
  # Instance Managers
  # ---------------------------------------------------------------------------

  @doc """
  Lists instance manager stats for the given manager names.

  ## Examples

      {:ok, managers} = JidoLiveDashboard.Runtime.list_instance_managers([:sessions, :rooms])
  """
  @spec list_instance_managers([atom()]) :: {:ok, [manager_stats()]}
  def list_instance_managers(manager_names) when is_list(manager_names) do
    managers =
      Enum.map(manager_names, fn name ->
        try do
          stats = Jido.Agent.InstanceManager.stats(name)
          Map.put(stats, :name, name)
        rescue
          _ -> %{name: name, count: 0, keys: []}
        end
      end)

    {:ok, managers}
  end

  # ---------------------------------------------------------------------------
  # Supervisor Info
  # ---------------------------------------------------------------------------

  @doc """
  Gets information about a supervisor.
  """
  @spec supervisor_info(atom()) :: {:ok, map()} | {:error, term()}
  def supervisor_info(supervisor) when is_atom(supervisor) do
    case Process.whereis(supervisor) do
      nil ->
        {:error, :not_found}

      pid ->
        children = DynamicSupervisor.which_children(supervisor)

        {:ok,
         %{
           pid: pid,
           alive: Process.alive?(pid),
           child_count: length(children),
           name: supervisor
         }}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc """
  Checks if Jido infrastructure is running.
  """
  @spec jido_running?() :: boolean()
  def jido_running? do
    case Process.whereis(Jido.AgentSupervisor) do
      nil -> false
      pid -> Process.alive?(pid)
    end
  end

  @doc """
  Gets Discovery catalog summary if available.
  """
  @spec discovery_summary() :: {:ok, map()} | {:error, term()}
  def discovery_summary do
    case Jido.Discovery.catalog() do
      {:ok, catalog} ->
        components = catalog.components

        {:ok,
         %{
           last_updated: catalog.last_updated,
           actions: length(Map.get(components, :actions, [])),
           agents: length(Map.get(components, :agents, [])),
           skills: length(Map.get(components, :skills, [])),
           sensors: length(Map.get(components, :sensors, [])),
           demos: length(Map.get(components, :demos, []))
         }}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    _ -> {:error, :discovery_not_available}
  end

  # ---------------------------------------------------------------------------
  # Internal
  # ---------------------------------------------------------------------------

  defp resolve_supervisor(name) do
    cond do
      # Check if it's already a supervisor name
      String.contains?(Atom.to_string(name), "Supervisor") ->
        name

      # Try to resolve as Jido instance
      function_exported?(Jido, :agent_supervisor_name, 1) ->
        Jido.agent_supervisor_name(name)

      true ->
        name
    end
  end

  defp child_to_agent_info({id, pid, _type, modules}) do
    %{
      pid: pid,
      id: id,
      module: List.first(modules),
      alive: Process.alive?(pid)
    }
  end

  defp status_to_map(status) do
    %{
      agent_module: status.agent_module,
      agent_id: status.agent_id,
      pid: status.pid,
      snapshot: snapshot_to_map(status.snapshot),
      raw_state: inspect(status.raw_state, limit: 50, pretty: true)
    }
  end

  defp snapshot_to_map(nil), do: nil

  defp snapshot_to_map(snapshot) when is_map(snapshot) do
    Map.from_struct(snapshot)
  rescue
    _ -> inspect(snapshot)
  end

  defp snapshot_to_map(snapshot), do: inspect(snapshot)

  defp state_to_map(state) do
    %{
      id: state.id,
      agent_module: state.agent_module,
      status: state.status,
      queue_size: state.queue_size,
      children_count: map_size(state.children || %{}),
      attachments_count: MapSet.size(state.attachments || MapSet.new())
    }
  rescue
    _ -> %{raw: inspect(state, limit: 100)}
  end
end
