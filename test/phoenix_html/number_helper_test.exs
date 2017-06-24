defmodule Phoenix.HTML.NumberHelperTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML.NumberHelper

  test "number_with_delimiter" do
    assert number_with_delimiter(123) == "123"
    assert number_with_delimiter(12345) == "12,345"
    assert number_with_delimiter(12345, delimiter: ":") == "12:345"
    assert number_with_delimiter(123.456) == "123.456"
    assert number_with_delimiter(12345.678) == "12,345.678"
    assert number_with_delimiter(12345.678, delimiter: " ") == "12 345.678"
    assert number_with_delimiter(12345.678, delimiter: " ", separator: ",") == "12 345,678"
  end

  test "number_with_precision" do
    assert number_with_precision(123) == "123.000"
    assert number_with_precision(12345) == "12,345.000"
    assert number_with_precision(12345, delimiter: " ") == "12 345.000"
    assert number_with_precision(12345, precision: 5) == "12,345.00000"
    assert number_with_precision(12345, delimiter: " ", separator: ",") == "12 345,000"

    assert number_with_precision(123.456, precision: 0) == "123"
    assert number_with_precision(123.456, precision: 2) == "123.45"
    assert number_with_precision(123.456, precision: 5) == "123.45600"  
  end
end
