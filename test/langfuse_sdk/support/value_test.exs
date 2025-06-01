defmodule LangfuseSdk.Support.ValueTest do
  use ExUnit.Case, async: true

  alias LangfuseSdk.Support.Value

  describe "force_new/3" do
    test "sets value when key doesn't exist" do
      map = %{}
      result = Value.force_new(map, :name, "test")
      assert result.name == "test"
    end

    test "sets value when key exists but is nil" do
      map = %{name: nil}
      result = Value.force_new(map, :name, "test")
      assert result.name == "test"
    end

    test "preserves existing value when not nil" do
      map = %{name: "existing"}
      result = Value.force_new(map, :name, "test")
      assert result.name == "existing"
    end
  end

  describe "cast_params/2" do
    test "casts simple params" do
      params = %{name: "test", value: 42}
      permitted = [:name, :value]
      result = Value.cast_params(params, permitted)

      assert result == [name: "test", value: 42]
    end

    test "filters out nil values" do
      params = %{name: "test", value: nil, other: "keep"}
      permitted = [:name, :value, :other]
      result = Value.cast_params(params, permitted)

      assert result == [name: "test", other: "keep"]
    end

    test "handles alias mapping" do
      params = %{trace_id: "123", traceId: "456"}
      permitted = [{:trace_id, :traceId}]
      result = Value.cast_params(params, permitted)

      # Should prefer the first key
      assert result == [trace_id: "123"]
    end

    test "uses alias when primary key is missing" do
      params = %{traceId: "456"}
      permitted = [{:trace_id, :traceId}]
      result = Value.cast_params(params, permitted)

      assert result == [trace_id: "456"]
    end

    test "filters unknown keys" do
      params = %{name: "test", unknown: "ignored"}
      permitted = [:name]
      result = Value.cast_params(params, permitted)

      assert result == [name: "test"]
    end
  end
end
