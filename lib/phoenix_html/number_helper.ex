defmodule Phoenix.HTML.NumberHelper do
  @moduledoc """
  Provides helper functions for number transformations
  """

  @default_delimiter ","
  @default_separator "."
  @default_precision 3

  @doc """
  Formats a number grouping thousands using the delimiter.

  Function accepts following options:

    * `:delimiter` - The thousands delimiter (defaults to “,”).

    * `:separator` - The separator between the integer and fractional digits (defaults to “.”).

  Examples:

      iex> number_with_delimiter(12345)
      "12,345"
      iex> number_with_delimiter(12345, delimiter: " ")
      "12 345"
      iex> number_with_delimiter(12345.678, delimiter: " ", separator: ",")
      "12 345,678"
  """
  @spec number_with_delimiter(number, Keyword.t) :: binary
  def number_with_delimiter(number, opts \\ [])

  def number_with_delimiter(number, opts) when is_integer(number) do
    put_delimiter(number, opts[:delimiter])
  end

  def number_with_delimiter(number, opts) when is_float(number) do
    [integer, fraction] = split_float(number)
    join_with_separator(put_delimiter(integer, opts[:delimiter]), fraction, opts[:separator])
  end

  @doc """
  Formats a number with the specified level of precision.

  Function accepts following options:

    * `:precision` - The precision of the number (defaults to 3).

    * `:delimiter` - The thousands delimiter (defaults to “,”)

    * `:separator` - The separator between the integer and fractional digits (defaults to “.”).

  Examples:

      iex> number_with_precision(12.3456)
      "12.345"
      iex> number_with_precision(123)
      "123.000"
      iex> number_with_precision(12.3456, precision: 1)
      "12.3"
      iex> number_with_precision(12.345, precision: 0)
      "12"
  """
  @spec number_with_precision(number, Keyword.t) :: binary
  def number_with_precision(number, opts \\ [])

  def number_with_precision(number, opts) when is_integer(number) do
    left = put_delimiter(number, opts[:delimiter])
    right = string_with_zeros(opts[:precision])
    join_with_separator(left, right, opts[:separator])
  end

  def number_with_precision(number, opts) when is_float(number) do
    [integer, fraction] = split_float(number)
    left = put_delimiter(integer, opts[:delimiter])
    right = adjust_string_to_size(fraction, opts[:precision])

    if String.length(right) > 0 do
      join_with_separator(left, right, opts[:separator])
    else
      left
    end
  end

  defp put_delimiter(number, nil = _delimiter), do: put_delimiter(number, @default_delimiter)

  defp put_delimiter(number, delimiter) when is_integer(number) do
    number
    |> Integer.to_char_list
    |> put_delimiter(delimiter)
  end

  defp put_delimiter(number, delimiter) when is_list(number) do
    number
    |> Enum.reverse
    |> Enum.chunk(3, 3, [])
    |> Enum.join(delimiter)
    |> String.reverse
  end

  defp put_delimiter(number, delimiter) when is_binary(number) do
    number
    |> String.to_char_list
    |> put_delimiter(delimiter)
  end

  defp join_with_separator(left, right, nil = _separator) do
    join_with_separator(left, right, @default_separator)
  end

  defp join_with_separator(left, right, separator) do
    left <> separator <> right
  end

  defp split_float(float) when is_float(float) do
    float
    |> to_string
    |> String.split(".")
  end

  defp string_with_zeros(nil), do: string_with_zeros(@default_precision)

  defp string_with_zeros(count) do
    Enum.join(List.duplicate("0", count))
  end

  defp adjust_string_to_size(_string, 0), do: ""
  defp adjust_string_to_size(string, nil), do: adjust_string_to_size(string, @default_precision)

  defp adjust_string_to_size(string, size) do
    string_length = String.length(string)

    cond do
      string_length == size -> string
      string_length > size -> String.slice(string, 0..(size - 1))
      string_length < size -> string <> string_with_zeros(size - string_length)
    end
  end

end
