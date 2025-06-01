defmodule LangfuseSdk.ErrorHandlingTest do
  use ExUnit.Case, async: true

  alias LangfuseSdk.Tracing.{Trace, Event, Span, Generation, Score}

  describe "error handling - structure validation" do
    test "creates trace with nil values without crashing" do
      # Test with nil values that should be handled gracefully
      trace_data = %{name: nil, input: nil}
      trace = Trace.new(trace_data)

      # Should create struct without crashing
      assert %Trace{} = trace
      assert trace.name == nil
      assert trace.input == nil
    end

    test "creates event with missing trace_id" do
      # Test with missing required trace_id for related entities
      event_data = %{name: "test-event", input: "test"}
      event = Event.new(event_data)

      # Should create struct without crashing
      assert %Event{} = event
      assert event.name == "test-event"
      assert event.trace_id == nil
    end

    test "creates generation with missing model" do
      # Test with missing optional fields
      generation_data = %{name: "test-generation"}
      generation = Generation.new(generation_data)

      # Should create struct without crashing
      assert %Generation{} = generation
      assert generation.model == nil
    end

    test "creates span with timing data" do
      # Test span creation with various timing configurations
      span_data = %{
        name: "test-span",
        start_time: DateTime.utc_now()
      }

      span = Span.new(span_data)

      assert %Span{} = span
      assert span.name == "test-span"
    end

    test "creates score with different data types" do
      # Test score creation with various value types
      score_data = %{
        name: "test-score",
        value: 0.95,
        data_type: "NUMERIC"
      }

      score = Score.new(score_data)

      assert %Score{} = score
      assert score.value == 0.95
      assert score.data_type == "NUMERIC"
    end
  end

  describe "data structure validation" do
    test "handles empty input data" do
      trace = Trace.new(%{})

      # Should have default values
      assert trace.id != nil
      assert %DateTime{} = trace.timestamp
    end

    test "preserves provided IDs" do
      custom_id = "custom-trace-id"
      trace = Trace.new(%{id: custom_id})

      assert trace.id == custom_id
    end

    test "handles complex nested input data" do
      complex_input = %{
        "messages" => [
          %{"role" => "user", "content" => "Hello"},
          %{"role" => "assistant", "content" => "Hi there!"}
        ],
        "metadata" => %{"source" => "test"}
      }

      generation = Generation.new(%{input: complex_input})

      assert generation.input == complex_input
    end
  end
end
