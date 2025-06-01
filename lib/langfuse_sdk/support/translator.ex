defmodule LangfuseSdk.Support.Translator do
  @moduledoc """
  This module's purpose is to automatically translate each response type from the generated API.
  It exposes a single function called `translate` that receives the type and the value to parse.
  """

  defmodule Inflex.Camelize do
    @moduledoc false

    @camelize_regex ~r/(?:^|[-_])|(?=[A-Z][a-z])/

    def camelize(word, option \\ :upper) do
      case Regex.split(@camelize_regex, to_string(word)) do
        words ->
          words
          |> Enum.filter(&(&1 != ""))
          |> camelize_list(option)
          |> Enum.join()
      end
    end

    defp camelize_list([], _), do: []

    defp camelize_list([h | tail], :lower) do
      [lowercase(h)] ++ camelize_list(tail, :upper)
    end

    defp camelize_list([h | tail], :upper) do
      [capitalize(h)] ++ camelize_list(tail, :upper)
    end

    def capitalize(word), do: String.capitalize(word)
    def lowercase(word), do: String.downcase(word)
  end

  def translate(nil, body), do: body
  def translate(:map, body), do: body
  def translate({:string, :generic}, body), do: body
  def translate(:boolean, body), do: body
  def translate(:integer, body) when is_binary(body), do: String.to_integer(body)
  def translate(:integer, body), do: body
  def translate({:string, :date_time}, body), do: NaiveDateTime.from_iso8601!(body)

  def translate({LangfuseSdk.Generated.TraceWithFullDetails, :t}, body), do: body

  # Explicitly match on `:t` so we can make easly distringuish between raw values
  # and modules / structs. This is mainly necessary to safely call `__fields__/1`.
  def translate({module, :t}, body) do
    fields = module.__fields__(:t)

    translated =
      Map.new(fields, fn
        {field, {module, type}} ->
          item = get_field(body, field)
          translated = translate({module, type}, item)
          {field, translated}

        {field, [{module, type}]} ->
          items = get_field(body, field)
          translated = Enum.map(items, &translate({module, type}, &1))
          {field, translated}

        {field, type} ->
          item = get_field(body, field)
          translated = translate(type, item)
          {field, translated}
      end)

    struct!(module, translated)
  end

  def translate(type, _body), do: raise("Response translation not implemented: #{inspect(type)}")

  # Get the camel-case version of the field from the API payload
  # so we can properly map to the internal Elixir representation.
  defp get_field(body, field), do: body[Inflex.Camelize.camelize(field, :lower)]
end
