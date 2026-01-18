defmodule JidoLiveDashboard.TraceBufferTest do
  use ExUnit.Case, async: false

  alias JidoLiveDashboard.TraceBuffer

  describe "TraceBuffer" do
    test "stats/0 returns buffer statistics" do
      assert {:ok, stats} = TraceBuffer.stats()
      assert is_integer(stats.count)
      assert is_integer(stats.max_size)
      assert is_integer(stats.trace_count)
      assert is_integer(stats.memory_bytes)
    end

    test "list_events/1 returns empty list initially" do
      TraceBuffer.clear()
      assert {:ok, []} = TraceBuffer.list_events()
    end

    test "record_event/3 stores events" do
      TraceBuffer.clear()

      TraceBuffer.record_event(
        [:jido, :agent_server, :signal, :start],
        %{system_time: 123},
        %{agent_id: "test-agent", trace_id: "trace-123"}
      )

      # Give it a moment to process
      Process.sleep(10)

      assert {:ok, events} = TraceBuffer.list_events()
      assert length(events) >= 1

      event = List.first(events)
      assert event.agent_id == "test-agent"
      assert event.trace_id == "trace-123"
    end

    test "get_trace/1 filters by trace_id" do
      TraceBuffer.clear()

      TraceBuffer.record_event(
        [:jido, :agent_server, :signal, :start],
        %{},
        %{trace_id: "unique-trace-abc"}
      )

      TraceBuffer.record_event(
        [:jido, :agent_server, :signal, :stop],
        %{},
        %{trace_id: "unique-trace-abc"}
      )

      TraceBuffer.record_event(
        [:jido, :agent_server, :signal, :start],
        %{},
        %{trace_id: "other-trace"}
      )

      Process.sleep(10)

      assert {:ok, events} = TraceBuffer.get_trace("unique-trace-abc")
      assert length(events) == 2
      assert Enum.all?(events, &(&1.trace_id == "unique-trace-abc"))
    end

    test "clear/0 removes all events" do
      TraceBuffer.record_event([:test], %{}, %{})
      Process.sleep(10)

      :ok = TraceBuffer.clear()

      assert {:ok, []} = TraceBuffer.list_events()
    end
  end
end
