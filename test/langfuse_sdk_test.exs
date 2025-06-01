defmodule LangfuseSdkTest do
  use ExUnit.Case

  alias LangfuseSdk.Tracing.{Trace, Event, Span, Generation, Score}

  describe "LangfuseSdk structure validation" do
    test "creates trace from factory data" do
      trace_data = LangfuseSdk.Factory.trace_data()
      trace = Trace.new(trace_data)

      assert %Trace{} = trace
      assert trace.name == trace_data.name
      assert trace.input == trace_data.input
      assert trace.output == trace_data.output
      assert trace.id != nil
    end

    test "creates event from factory data" do
      event_data = LangfuseSdk.Factory.event_data()
      event = Event.new(event_data)

      assert %Event{} = event
      assert event.name == event_data.name
      assert event.input == event_data.input
      assert event.id != nil
    end

    test "creates span from factory data" do
      span_data = LangfuseSdk.Factory.span_data()
      span = Span.new(span_data)

      assert %Span{} = span
      assert span.name == span_data.name
      assert span.input == span_data.input
      assert span.id != nil
    end

    test "creates generation from factory data" do
      generation_data = LangfuseSdk.Factory.generation_data()
      generation = Generation.new(generation_data)

      assert %Generation{} = generation
      assert generation.name == generation_data.name
      assert generation.model == generation_data.model
      assert generation.id != nil
    end

    test "creates score from factory data" do
      trace_id = "test-trace-123"
      score_data = LangfuseSdk.Factory.score_data(trace_id)
      score = Score.new(score_data)

      assert %Score{} = score
      assert score.trace_id == trace_id
      assert score.name == score_data.name
      assert score.value == score_data.value
      assert score.id != nil
    end

    test "handles span updates" do
      span_data = LangfuseSdk.Factory.span_data()
      span = Span.new(span_data)
      updated_span = %{span | name: "updated-span"}

      assert updated_span.name == "updated-span"
      assert updated_span.id == span.id
    end

    test "handles generation updates" do
      generation_data = LangfuseSdk.Factory.generation_data()
      generation = Generation.new(generation_data)
      updated_generation = %{generation | name: "updated-generation"}

      assert updated_generation.name == "updated-generation"
      assert updated_generation.id == generation.id
    end

    test "creates multiple items with related IDs" do
      trace_data = LangfuseSdk.Factory.trace_data()
      trace = Trace.new(trace_data)

      event_data = LangfuseSdk.Factory.event_data(trace.id)
      event = Event.new(event_data)

      span_data = LangfuseSdk.Factory.span_data(trace.id)
      span = Span.new(span_data)

      generation_data = LangfuseSdk.Factory.generation_data(trace.id)
      generation = Generation.new(generation_data)

      score_data = LangfuseSdk.Factory.score_data(trace.id)
      score = Score.new(score_data)

      # Verify all items are properly structured
      items = [trace, event, span, score, generation]

      assert length(items) == 5
      assert Enum.all?(items, fn item -> item.id != nil end)
      assert event.trace_id == trace.id
      assert span.trace_id == trace.id
      assert generation.trace_id == trace.id
      assert score.trace_id == trace.id
    end
  end

  # Note: Integration tests with actual API calls are moved to separate
  # test files to avoid network dependencies in unit tests
end
