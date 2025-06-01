defmodule LangfuseSdk.IngestorTest do
  use ExUnit.Case, async: true

  alias LangfuseSdk.Ingestor
  alias LangfuseSdk.Tracing.{Trace, Event, Span, Generation, Score}

  describe "to_event/2" do
    test "converts trace to create event" do
      trace = Trace.new(%{name: "test-trace", user_id: "user-123"})
      event = Ingestor.to_event(trace, :create)

      assert event["type"] == "trace-create"
      assert event["id"] == trace.id
      assert event["body"]["name"] == "test-trace"
      assert event["body"]["userId"] == "user-123"
    end

    test "converts event to create event" do
      event_data = Event.new(%{trace_id: "trace-123", name: "test-event"})
      event = Ingestor.to_event(event_data, :create)

      assert event["type"] == "event-create"
      assert event["body"]["traceId"] == "trace-123"
      assert event["body"]["name"] == "test-event"
    end

    test "converts span to create event" do
      span = Span.new(%{trace_id: "trace-123", name: "test-span"})
      event = Ingestor.to_event(span, :create)

      assert event["type"] == "span-create"
      assert event["body"]["traceId"] == "trace-123"
      assert event["body"]["name"] == "test-span"
    end

    test "converts span to update event" do
      span = Span.new(%{trace_id: "trace-123", name: "test-span"})
      event = Ingestor.to_event(span, :update)

      assert event["type"] == "span-update"
    end

    test "converts generation to create event" do
      generation =
        Generation.new(%{
          trace_id: "trace-123",
          name: "test-generation",
          model: "gpt-4"
        })

      event = Ingestor.to_event(generation, :create)

      assert event["type"] == "generation-create"
      assert event["body"]["model"] == "gpt-4"
    end

    test "converts generation to update event" do
      generation = Generation.new(%{trace_id: "trace-123", model: "gpt-4"})
      event = Ingestor.to_event(generation, :update)

      assert event["type"] == "generation-update"
    end

    test "converts score to create event" do
      score =
        Score.new(%{
          trace_id: "trace-123",
          name: "accuracy",
          value: 0.95
        })

      event = Ingestor.to_event(score, :create)

      assert event["type"] == "score-create"
      assert event["body"]["value"] == 0.95
    end
  end

  describe "event structure" do
    test "includes required fields for all event types" do
      trace = Trace.new(%{name: "test"})
      event = Ingestor.to_event(trace, :create)

      assert Map.has_key?(event, "type")
      assert Map.has_key?(event, "id")
      assert Map.has_key?(event, "timestamp")
      assert Map.has_key?(event, "metadata")
      assert Map.has_key?(event, "body")
    end

    test "body contains correct fields for traces" do
      trace =
        Trace.new(%{
          name: "test-trace",
          input: "input",
          output: "output",
          session_id: "session-123",
          version: "1.0",
          tags: ["tag1", "tag2"],
          public: true
        })

      event = Ingestor.to_event(trace, :create)

      body = event["body"]
      assert body["name"] == "test-trace"
      assert body["input"] == "input"
      assert body["output"] == "output"
      assert body["sessionId"] == "session-123"
      assert body["version"] == "1.0"
      assert body["tags"] == ["tag1", "tag2"]
      assert body["public"] == true
    end
  end
end
