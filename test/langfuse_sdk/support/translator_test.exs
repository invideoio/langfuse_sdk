defmodule LangfuseSdk.Support.TranslatorTest do
  use ExUnit.Case, async: true

  alias LangfuseSdk.Support.Translator

  describe "translate/2" do
    test "handles nil type" do
      body = %{"key" => "value"}
      result = Translator.translate(nil, body)
      assert result == body
    end

    test "handles map type" do
      body = %{"key" => "value"}
      result = Translator.translate(:map, body)
      assert result == body
    end

    test "handles string generic type" do
      body = "test string"
      result = Translator.translate({:string, :generic}, body)
      assert result == body
    end

    test "handles boolean type" do
      result = Translator.translate(:boolean, true)
      assert result == true
    end

    test "handles integer type with integer input" do
      result = Translator.translate(:integer, 42)
      assert result == 42
    end

    test "handles integer type with string input" do
      result = Translator.translate(:integer, "42")
      assert result == 42
    end

    test "handles datetime type" do
      datetime_string = "2023-01-01T12:00:00"
      result = Translator.translate({:string, :date_time}, datetime_string)
      assert %NaiveDateTime{} = result
    end

    test "handles special TraceWithFullDetails type" do
      body = %{"id" => "123"}
      result = Translator.translate({LangfuseSdk.Generated.TraceWithFullDetails, :t}, body)
      assert result == body
    end

    test "raises error for unimplemented types" do
      assert_raise RuntimeError, ~r/Response translation not implemented/, fn ->
        Translator.translate(:unknown_type, %{})
      end
    end
  end
end
