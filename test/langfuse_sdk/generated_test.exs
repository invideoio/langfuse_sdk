defmodule LangfuseSdk.GeneratedTest do
  @moduledoc """
  Tests for generated code structure validation (without network calls).
  """
  use ExUnit.Case

  describe "LangfuseSdk.Generated payload structure" do
    test "ingestion_batch payload structure" do
      payload = LangfuseSdk.PayloadFixtures.ingestion_batch()

      # Verify payload has expected structure
      assert Map.has_key?(payload, "metadata")
      assert Map.has_key?(payload, "batch")
      assert is_list(payload["batch"])
    end

    test "batch item structure" do
      payload = LangfuseSdk.PayloadFixtures.ingestion_batch()
      [batch_item | _] = payload["batch"]

      # Verify batch item has expected structure
      assert Map.has_key?(batch_item, "id")
      assert Map.has_key?(batch_item, "type")
      assert Map.has_key?(batch_item, "body")
      assert batch_item["type"] == "trace-create"
    end
  end

  # Note: Network-dependent tests are skipped to avoid external dependencies
  # Integration tests with actual API calls should be in separate test files
end
