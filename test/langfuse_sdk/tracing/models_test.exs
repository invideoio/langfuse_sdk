defmodule LangfuseSdk.Tracing.ModelsTest do
  use ExUnit.Case, async: true

  alias LangfuseSdk.Tracing.{Trace, Event, Span, Generation, Score}

  describe "Trace.new/1" do
    test "creates trace with default values" do
      trace = Trace.new()

      assert trace.id != nil
      assert %DateTime{} = trace.timestamp
    end

    test "creates trace with provided data" do
      data = %{name: "test-trace", user_id: "user-123"}
      trace = Trace.new(data)

      assert trace.name == "test-trace"
      assert trace.user_id == "user-123"
      assert trace.id != nil
    end

    test "preserves existing id if provided" do
      data = %{id: "custom-id", name: "test"}
      trace = Trace.new(data)

      assert trace.id == "custom-id"
    end
  end

  describe "Event.new/1" do
    test "creates event with default values" do
      event = Event.new()

      assert event.id != nil
      assert %DateTime{} = event.timestamp
    end

    test "creates event with trace_id" do
      data = %{trace_id: "trace-123", name: "test-event"}
      event = Event.new(data)

      assert event.trace_id == "trace-123"
      assert event.name == "test-event"
    end
  end

  describe "Span.new/1" do
    test "creates span with default values" do
      span = Span.new()

      assert span.id != nil
      assert %DateTime{} = span.timestamp
    end

    test "creates span with timing data" do
      start_time = DateTime.utc_now()

      data = %{
        trace_id: "trace-123",
        name: "test-span",
        start_time: start_time
      }

      span = Span.new(data)

      assert span.start_time == start_time
    end
  end

  describe "Generation.new/1" do
    test "creates generation with default values" do
      generation = Generation.new()

      assert generation.id != nil
      assert %DateTime{} = generation.timestamp
    end

    test "creates generation with model info" do
      data = %{
        trace_id: "trace-123",
        name: "test-generation",
        model: "gpt-4",
        input: "test input"
      }

      generation = Generation.new(data)

      assert generation.model == "gpt-4"
      assert generation.input == "test input"
    end
  end

  describe "Score.new/1" do
    test "creates score with default values" do
      score = Score.new()

      assert score.id != nil
      assert %DateTime{} = score.timestamp
    end

    test "creates score with numeric value" do
      data = %{
        trace_id: "trace-123",
        name: "accuracy",
        value: 0.95,
        data_type: "NUMERIC"
      }

      score = Score.new(data)

      assert score.value == 0.95
      assert score.data_type == "NUMERIC"
    end
  end
end
