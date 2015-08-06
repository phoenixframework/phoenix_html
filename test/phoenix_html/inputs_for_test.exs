defmodule Phoenix.HTML.InputsForTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML
  import Phoenix.HTML.Form

  @doc """
  A function that executes `inputs_for/4` and
  extracts its inner contents for assertion.
  """
  def safe_inputs_for(field, opts \\ [], fun) do
    mark = "--PLACEHOLDER--"

    conn =
      Plug.Test.conn(:get, "/foo", %{"search" => %{
        "date" => %{"year" => "2020", "month" => "4", "day" => "17"},
        "dates" => %{"0" => %{"year" => "2010", "month" => "4", "day" => "17"},
                     "1" => %{"year" => "2020", "month" => "4", "day" => "17"}}
      }})

    contents =
      safe_to_string form_for(conn, "/", [name: :search], fn f ->
        html_escape [mark, inputs_for(f, field, opts, fun), mark]
      end)

    [_, inner, _] = String.split(contents, mark)
    inner
  end

  ## Cardinality one

  test "one: inputs_for/4 without default and field is not present" do
    contents =
      safe_inputs_for(:unknown, fn f ->
        refute f.index
        text_input f, :year
      end)

    assert contents ==
           ~s(<input id="search_unknown_year" name="search[unknown][year]" type="text">)
  end

  test "one: inputs_for/4 does not generate index" do
    safe_inputs_for(:unknown, fn f ->
      refute f.index
      "ok"
    end)
  end

  test "one: inputs_for/4 without default and field is present" do
    contents =
      safe_inputs_for(:date, fn f ->
        text_input f, :year
      end)

    assert contents ==
           ~s(<input id="search_date_year" name="search[date][year]" type="text" value="2020">)
  end

  test "one: inputs_for/4 with default and field is not present" do
    contents =
      safe_inputs_for(:unknown, [default: %{year: 2015}], fn f ->
        text_input f, :year
      end)

    assert contents ==
           ~s(<input id="search_unknown_year" name="search[unknown][year]" type="text" value="2015">)
  end

  test "one: inputs_for/4 with default and field is present" do
    contents =
      safe_inputs_for(:date, [default: %{year: 2015}], fn f ->
        text_input f, :year
      end)

    assert contents ==
           ~s(<input id="search_date_year" name="search[date][year]" type="text" value="2020">)
  end

  test "one: inputs_for/4 with custom name and id" do
    contents =
      safe_inputs_for(:date, [name: :foo, id: :bar], fn f ->
        text_input f, :year
      end)

    assert contents ==
           ~s(<input id="bar_year" name="foo[year]" type="text" value="2020">)
  end

  ## Cardinality many

  test "many: inputs_for/4 with default and field is not present" do
    contents =
      safe_inputs_for(:unknown, [default: [%{year: 2012}, %{year: 2018}]], fn f ->
        assert f.index in [0, 1]
        text_input f, :year
      end)

    assert contents ==
           ~s(<input id="search_unknown_0_year" name="search[unknown][0][year]" type="text" value="2012">) <>
           ~s(<input id="search_unknown_1_year" name="search[unknown][1][year]" type="text" value="2018">)
  end

  test "many: inputs_for/4 generates indexes" do
    safe_inputs_for(:unknown, [default: [%{year: 2012}]], fn f ->
      assert f.index == 0
      "ok"
    end)

    safe_inputs_for(:unknown, [default: [%{year: 2012}, %{year: 2018}]], fn f ->
      assert f.index in [0, 1]
      "ok"
    end)
  end

  test "many: inputs_for/4 with default and field is present" do
    contents =
      safe_inputs_for(:dates, [default: [%{year: 2012}, %{year: 2018}]], fn f ->
        text_input f, :year
      end)

    assert contents ==
           ~s(<input id="search_dates_0_year" name="search[dates][0][year]" type="text" value="2010">) <>
           ~s(<input id="search_dates_1_year" name="search[dates][1][year]" type="text" value="2020">)
  end

  test "many: inputs_for/4 with name and id" do
    contents =
      safe_inputs_for(:dates, [default: [%{year: 2012}, %{year: 2018}], name: :foo, id: :bar], fn f ->
        text_input f, :year
      end)

    assert contents ==
           ~s(<input id="bar_0_year" name="foo[0][year]" type="text" value="2010">) <>
           ~s(<input id="bar_1_year" name="foo[1][year]" type="text" value="2020">)
  end

  @prepend_append [prepend: [%{year: 2008}], append: [%{year: 2022}],
                   default: [%{year: 2012}, %{year: 2018}]]

  test "many: inputs_for/4 with prepend/append and field is not present" do
    contents =
      safe_inputs_for(:unknown, @prepend_append, fn f ->
        text_input f, :year
      end)

    assert contents ==
           ~s(<input id="search_unknown_0_year" name="search[unknown][0][year]" type="text" value="2008">) <>
           ~s(<input id="search_unknown_1_year" name="search[unknown][1][year]" type="text" value="2012">) <>
           ~s(<input id="search_unknown_2_year" name="search[unknown][2][year]" type="text" value="2018">) <>
           ~s(<input id="search_unknown_3_year" name="search[unknown][3][year]" type="text" value="2022">)
  end

  test "many: inputs_for/4 with prepend/append and field is present" do
    contents =
      safe_inputs_for(:dates, @prepend_append, fn f ->
        text_input f, :year
      end)

    assert contents ==
           ~s(<input id="search_dates_0_year" name="search[dates][0][year]" type="text" value="2010">) <>
           ~s(<input id="search_dates_1_year" name="search[dates][1][year]" type="text" value="2020">)
  end
end
