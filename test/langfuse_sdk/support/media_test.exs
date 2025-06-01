defmodule LangfuseSdk.Support.MediaTest do
  use ExUnit.Case, async: true

  alias LangfuseSdk.Support.Media
  alias LangfuseSdk.Tracing.Generation

  describe "replace_image_urls/1" do
    test "handles generation without image URLs" do
      generation =
        Generation.new(%{
          trace_id: "trace-123",
          name: "test-generation",
          input: "simple text input",
          output: "simple text output"
        })

      result = Media.replace_image_urls(generation)

      assert result.input == "simple text input"
      assert result.output == "simple text output"
    end

    test "handles generation with non-list input/output" do
      generation =
        Generation.new(%{
          trace_id: "trace-123",
          name: "test-generation",
          input: %{"role" => "user", "content" => "text"},
          output: %{"role" => "assistant", "content" => "response"}
        })

      result = Media.replace_image_urls(generation)

      assert result.input == %{"role" => "user", "content" => "text"}
      assert result.output == %{"role" => "assistant", "content" => "response"}
    end

    test "handles generation with list input but no image URLs" do
      generation =
        Generation.new(%{
          trace_id: "trace-123",
          name: "test-generation",
          input: [
            %{"role" => "user", "content" => "Hello"}
          ]
        })

      result = Media.replace_image_urls(generation)

      assert result.input == [%{"role" => "user", "content" => "Hello"}]
    end

    test "handles generation with string content in list" do
      generation =
        Generation.new(%{
          trace_id: "trace-123",
          name: "test-generation",
          input: [
            %{"role" => "user", "content" => "Hello world"}
          ]
        })

      result = Media.replace_image_urls(generation)

      assert result.input == [%{"role" => "user", "content" => "Hello world"}]
    end

    test "preserves non-image content entries" do
      generation =
        Generation.new(%{
          trace_id: "trace-123",
          name: "test-generation",
          input: [
            %{
              "role" => "user",
              "content" => [
                %{"type" => "text", "text" => "Describe this image"},
                %{"type" => "other", "data" => "some data"}
              ]
            }
          ]
        })

      result = Media.replace_image_urls(generation)

      expected_content = [
        %{"type" => "text", "text" => "Describe this image"},
        %{"type" => "other", "data" => "some data"}
      ]

      assert [%{"content" => ^expected_content}] = result.input
    end
  end

  # Note: Tests involving actual image URLs and network calls are skipped
  # in unit tests to avoid dependencies on external services
end
