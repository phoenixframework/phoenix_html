defmodule Phoenix.HTML.FormTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML
  import Phoenix.HTML.Form
  doctest Phoenix.HTML.Form

  @doc """
  A function that executes `form_for/4` and
  extracts its inner contents for assertion.
  """
  def safe_form(fun, opts \\ []) do
    mark = "--PLACEHOLDER--"

    contents =
      safe_to_string form_for(conn(), "/", [name: :search] ++ opts, fn f ->
        html_escape [mark, fun.(f), mark]
      end)

    [_, inner, _] = String.split(contents, mark)
    inner
  end

  defp conn do
    Plug.Test.conn(:get, "/foo", %{"search" => %{
      "key" => "value",
      "alt_key" => nil,
      "datetime" => %{"year" => "2020", "month" => "4", "day" => "17",
                      "hour" => "2",   "min" => "11", "sec" => "13"}
    }})
  end

  ## form_for/4

  test "form_for/4 with connection" do
    conn = conn()

    form = safe_to_string form_for(conn, "/", [name: :search], fn f ->
      assert f.impl == Phoenix.HTML.FormData.Plug.Conn
      assert f.name == "search"
      assert f.source == conn
      assert f.params["key"] == "value"
      ""
    end)

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" method="post">)
    assert form =~ ~s(<input name="_utf8" type="hidden" value="✓">)
  end

  test "form_for/4 with custom options" do
    form = safe_to_string form_for(conn(), "/", [name: :search, method: :put, multipart: true], fn f ->
      refute f.options[:name]
      assert f.options[:multipart] == true
      assert f.options[:method] == :put
      ""
    end)

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" enctype="multipart/form-data" method="post">)
    assert form =~ ~s(<input name="_method" type="hidden" value="put">)
  end

  test "form_for/4 is html safe" do
    form = safe_to_string form_for(conn(), "/", [name: :search], fn _ -> "<>" end)
    assert form =~ ~s(&lt;&gt;</form>)
  end

  test "form_for/4 with type and validations"  do
    form = safe_to_string form_for(conn(), "/", [name: :search], fn f ->
      assert input_type(f, :hello) == :text_input
      assert input_type(f, :email) == :email_input
      assert input_type(f, :search) == :search_input
      assert input_type(f, :password) == :password_input
      assert input_type(f, :special_url) == :url_input
      assert input_type(f, :number, %{"number" => :number_input}) == :number_input
      assert input_validations(f, :hello) == []
      ""
    end)

    assert form =~ "<form"
  end

  ## text_input/3

  test "text_input/3" do
    assert safe_to_string(text_input(:search, :key)) ==
           ~s(<input id="search_key" name="search[key]" type="text">)

    assert safe_to_string(text_input(:search, :key, value: "foo", id: "key", name: "search[key][]")) ==
           ~s(<input id="key" name="search[key][]" type="text" value="foo">)
  end

  test "text_input/3 with form" do
    assert safe_form(&text_input(&1, :key)) ==
           ~s(<input id="search_key" name="search[key]" type="text" value="value">)

    assert safe_form(&text_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
           ~s(<input id="key" name="search[key][]" type="text" value="foo">)
  end

  test "text_input/3 with form and model data" do
    assert safe_form(&text_input(put_in(&1.model[:key], "original"), :key)) ==
           ~s(<input id="search_key" name="search[key]" type="text" value="value">)

    assert safe_form(&text_input(put_in(&1.model[:no_key], "original"), :no_key)) ==
           ~s(<input id="search_no_key" name="search[no_key]" type="text" value="original">)

    assert safe_form(&text_input(put_in(&1.model[:alt_key], "original"), :alt_key)) ==
           ~s(<input id="search_alt_key" name="search[alt_key]" type="text">)
  end

  ## textarea/3

  test "textarea/3" do
    assert safe_to_string(textarea(:search, :key)) ==
           ~s(<textarea id="search_key" name="search[key]">\n</textarea>)

    assert safe_to_string(textarea(:search, :key)) ==
           ~s(<textarea id="search_key" name="search[key]">\n</textarea>)

    assert safe_to_string(textarea(:search, :key, id: "key", name: "search[key][]")) ==
           ~s(<textarea id="key" name="search[key][]">\n</textarea>)
  end

  test "textarea/3 with form" do
    assert safe_form(&textarea(&1, :key)) ==
           ~s(<textarea id="search_key" name="search[key]">\nvalue</textarea>)

    assert safe_form(&textarea(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
           ~s(<textarea id="key" name="search[key][]">\nfoo</textarea>)
  end

  ## number_input/3

  test "number_input/3" do
    assert safe_to_string(number_input(:search, :key)) ==
           ~s(<input id="search_key" name="search[key]" type="number">)

    assert safe_to_string(number_input(:search, :key, value: "foo", id: "key", name: "search[key][]")) ==
           ~s(<input id="key" name="search[key][]" type="number" value="foo">)
  end

  test "number_input/3 with form" do
    assert safe_form(&number_input(&1, :key)) ==
           ~s(<input id="search_key" name="search[key]" type="number" value="value">)

    assert safe_form(&number_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
           ~s(<input id="key" name="search[key][]" type="number" value="foo">)
  end

  ## hidden_input/3

  test "hidden_input/3" do
    assert safe_to_string(hidden_input(:search, :key)) ==
           ~s(<input id="search_key" name="search[key]" type="hidden">)

    assert safe_to_string(hidden_input(:search, :key, value: "foo", id: "key", name: "search[key][]")) ==
           ~s(<input id="key" name="search[key][]" type="hidden" value="foo">)
  end

  test "hidden_input/3 with form" do
    assert safe_form(&hidden_input(&1, :key)) ==
           ~s(<input id="search_key" name="search[key]" type="hidden" value="value">)

    assert safe_form(&hidden_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
           ~s(<input id="key" name="search[key][]" type="hidden" value="foo">)
  end

  ## email_input/3

  test "email_input/3" do
    assert safe_to_string(email_input(:search, :key)) ==
           ~s(<input id="search_key" name="search[key]" type="email">)

    assert safe_to_string(email_input(:search, :key, value: "foo", id: "key", name: "search[key][]")) ==
           ~s(<input id="key" name="search[key][]" type="email" value="foo">)
  end

  test "email_input/3 with form" do
    assert safe_form(&email_input(&1, :key)) ==
           ~s(<input id="search_key" name="search[key]" type="email" value="value">)

    assert safe_form(&email_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
           ~s(<input id="key" name="search[key][]" type="email" value="foo">)
  end

  ## password_input/3

  test "password_input/3" do
    assert safe_to_string(password_input(:search, :key)) ==
           ~s(<input id="search_key" name="search[key]" type="password">)

    assert safe_to_string(password_input(:search, :key, value: "foo", id: "key", name: "search[key][]")) ==
           ~s(<input id="key" name="search[key][]" type="password" value="foo">)
  end

  test "password_input/3 with form" do
    assert safe_form(&password_input(&1, :key)) ==
           ~s(<input id="search_key" name="search[key]" type="password" value="value">)

    assert safe_form(&password_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
           ~s(<input id="key" name="search[key][]" type="password" value="foo">)
  end

  ## file_input/3

  test "file_input/3" do
    assert safe_to_string(file_input(:search, :key)) ==
           ~s(<input id="search_key" name="search[key]" type="file">)

    assert safe_to_string(file_input(:search, :key, id: "key", name: "search[key][]")) ==
           ~s(<input id="key" name="search[key][]" type="file">)
  end

  test "file_input/3 with form" do
    assert_raise ArgumentError, fn ->
      safe_form(&file_input(&1, :key))
    end

    assert safe_form(&file_input(&1, :key), multipart: true) ==
          ~s(<input id="search_key" name="search[key]" type="file">)
  end

  ## url_input/3

  test "url_input/3" do
    assert safe_to_string(url_input(:search, :key)) ==
          ~s(<input id="search_key" name="search[key]" type="url">)

    assert safe_to_string(url_input(:search, :key, value: "foo", id: "key", name: "search[key][]")) ==
          ~s(<input id="key" name="search[key][]" type="url" value="foo">)
  end

  test "url_input/3 with form" do
    assert safe_form(&url_input(&1, :key)) ==
          ~s(<input id="search_key" name="search[key]" type="url" value="value">)

    assert safe_form(&url_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
          ~s(<input id="key" name="search[key][]" type="url" value="foo">)
  end

  ## search_input/3

  test "search_input/3" do
    assert safe_to_string(search_input(:search, :key)) ==
          ~s(<input id="search_key" name="search[key]" type="search">)

    assert safe_to_string(search_input(:search, :key, value: "foo", id: "key", name: "search[key][]")) ==
          ~s(<input id="key" name="search[key][]" type="search" value="foo">)
  end

  test "search_input/3 with form" do
    assert safe_form(&search_input(&1, :key)) ==
          ~s(<input id="search_key" name="search[key]" type="search" value="value">)

    assert safe_form(&search_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
          ~s(<input id="key" name="search[key][]" type="search" value="foo">)
  end

  ## telephone_input/3

  test "telephone_input/3" do
    assert safe_to_string(telephone_input(:search, :key)) ==
          ~s(<input id="search_key" name="search[key]" type="tel">)

    assert safe_to_string(telephone_input(:search, :key, value: "foo", id: "key", name: "search[key][]")) ==
          ~s(<input id="key" name="search[key][]" type="tel" value="foo">)
  end

  test "telephone_input/3 with form" do
    assert safe_form(&telephone_input(&1, :key)) ==
          ~s(<input id="search_key" name="search[key]" type="tel" value="value">)

    assert safe_form(&telephone_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
          ~s(<input id="key" name="search[key][]" type="tel" value="foo">)
  end

  ## range_input/3

  test "range_input/3" do
    assert safe_to_string(range_input(:search, :key)) ==
          ~s(<input id="search_key" name="search[key]" type="range">)

    assert safe_to_string(range_input(:search, :key, value: "foo", id: "key", name: "search[key][]")) ==
          ~s(<input id="key" name="search[key][]" type="range" value="foo">)
  end

  test "range_input/3 with form" do
    assert safe_form(&range_input(&1, :key)) ==
          ~s(<input id="search_key" name="search[key]" type="range" value="value">)

    assert safe_form(&range_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
          ~s(<input id="key" name="search[key][]" type="range" value="foo">)
  end

  ## submit/2

  test "submit/2" do
    assert safe_to_string(submit("Submit")) ==
          ~s(<input type="submit" value="Submit">)

    assert safe_to_string(submit("Submit", class: "btn")) ==
          ~s(<input class="btn" type="submit" value="Submit">)
  end

  ## reset/2

  test "reset/2" do
    assert safe_to_string(reset("Reset")) ==
          ~s(<input type="reset" value="Reset">)

    assert safe_to_string(reset("Reset", class: "btn")) ==
          ~s(<input class="btn" type="reset" value="Reset">)
  end

  ## radio_button/4

  test "radio_button/4" do
    assert safe_to_string(radio_button(:search, :key, "admin")) ==
          ~s(<input id="search_key_admin" name="search[key]" type="radio" value="admin">)

    assert safe_to_string(radio_button(:search, :key, "admin", checked: true)) ==
          ~s(<input checked="checked" id="search_key_admin" name="search[key]" type="radio" value="admin">)
  end

  test "radio_button/4 with form" do
    assert safe_form(&radio_button(&1, :key, :admin)) ==
          ~s(<input id="search_key_admin" name="search[key]" type="radio" value="admin">)

    assert safe_form(&radio_button(&1, :key, :value)) ==
          ~s(<input checked="checked" id="search_key_value" name="search[key]" type="radio" value="value">)

    assert safe_form(&radio_button(&1, :key, :value, checked: false)) ==
          ~s(<input id="search_key_value" name="search[key]" type="radio" value="value">)
  end

  ## checkbox/3

  test "checkbox/3" do
    assert safe_to_string(checkbox(:search, :key)) ==
           ~s(<input name="search[key]" type="hidden" value="false">) <>
           ~s(<input id="search_key" name="search[key]" type="checkbox" value="true">)

    assert safe_to_string(checkbox(:search, :key, value: "true")) ==
           ~s(<input name="search[key]" type="hidden" value="false">) <>
           ~s(<input checked="checked" id="search_key" name="search[key]" type="checkbox" value="true">)

    assert safe_to_string(checkbox(:search, :key, checked: true)) ==
           ~s(<input name="search[key]" type="hidden" value="false">) <>
           ~s(<input checked="checked" id="search_key" name="search[key]" type="checkbox" value="true">)

    assert safe_to_string(checkbox(:search, :key, value: "true", checked: false)) ==
           ~s(<input name="search[key]" type="hidden" value="false">) <>
           ~s(<input id="search_key" name="search[key]" type="checkbox" value="true">)

    assert safe_to_string(checkbox(:search, :key, value: 0, checked_value: 1, unchecked_value: 0)) ==
           ~s(<input name="search[key]" type="hidden" value="0">) <>
           ~s(<input id="search_key" name="search[key]" type="checkbox" value="1">)

    assert safe_to_string(checkbox(:search, :key, value: 1, checked_value: 1, unchecked_value: 0)) ==
           ~s(<input name="search[key]" type="hidden" value="0">) <>
           ~s(<input checked="checked" id="search_key" name="search[key]" type="checkbox" value="1">)
  end

  test "checkbox/3 with form" do
    assert safe_form(&checkbox(&1, :key)) ==
           ~s(<input name="search[key]" type="hidden" value="false">) <>
           ~s(<input id="search_key" name="search[key]" type="checkbox" value="true">)

    assert safe_form(&checkbox(&1, :key, value: true)) ==
           ~s(<input name="search[key]" type="hidden" value="false">) <>
           ~s(<input checked="checked" id="search_key" name="search[key]" type="checkbox" value="true">)

    assert safe_form(&checkbox(&1, :key, checked_value: :value, unchecked_value: :novalue)) ==
           ~s(<input name="search[key]" type="hidden" value="novalue">) <>
           ~s(<input checked="checked" id="search_key" name="search[key]" type="checkbox" value="value">)
  end

  # select/4

  test "select/4" do
    assert safe_to_string(select(:search, :key, ~w(foo bar))) ==
           ~s(<select id="search_key" name="search[key]">) <>
           ~s(<option value="foo">foo</option>) <>
           ~s(<option value="bar">bar</option>) <>
           ~s(</select>)

    assert safe_to_string(select(:search, :key, [Foo: "foo", Bar: "bar"])) ==
           ~s(<select id="search_key" name="search[key]">) <>
           ~s(<option value="foo">Foo</option>) <>
           ~s(<option value="bar">Bar</option>) <>
           ~s(</select>)

    assert safe_to_string(select(:search, :key, [Foo: "foo", Bar: "bar"], prompt: "Choose your destiny")) ==
           ~s(<select id="search_key" name="search[key]">) <>
           ~s(<option value="">Choose your destiny</option>) <>
           ~s(<option value="foo">Foo</option>) <>
           ~s(<option value="bar">Bar</option>) <>
           ~s(</select>)

    assert safe_to_string(select(:search, :key, ~w(foo bar), value: "foo")) =~
           ~s(<option selected="selected" value="foo">foo</option>)

    assert safe_to_string(select(:search, :key, ~w(foo bar), default: "foo")) =~
           ~s(<option selected="selected" value="foo">foo</option>)
  end

  test "select/4 with form" do
    assert safe_form(&select(&1, :key, ~w(value novalue), default: "novalue")) ==
           ~s(<select id="search_key" name="search[key]">) <>
           ~s(<option selected="selected" value="value">value</option>) <>
           ~s(<option value="novalue">novalue</option>) <>
           ~s(</select>)

    assert safe_form(&select(&1, :other, ~w(value novalue), default: "novalue")) ==
           ~s(<select id="search_other" name="search[other]">) <>
           ~s(<option value="value">value</option>) <>
           ~s(<option selected="selected" value="novalue">novalue</option>) <>
           ~s(</select>)

    assert safe_form(&select(&1, :key, ~w(value novalue), value: "novalue")) ==
           ~s(<select id="search_key" name="search[key]">) <>
           ~s(<option value="value">value</option>) <>
           ~s(<option selected="selected" value="novalue">novalue</option>) <>
           ~s(</select>)
  end

  # multiple_select/4

  test "multiple_select/4" do
    assert safe_to_string(multiple_select(:search, :key, ~w(foo bar))) ==
         ~s(<select id="search_key" multiple="" name="search[key][]">) <>
         ~s(<option value="foo">foo</option>) <>
         ~s(<option value="bar">bar</option>) <>
         ~s(</select>)

    assert safe_to_string(multiple_select(:search, :key, [{"foo", 1}, {"bar", 2}])) ==
           ~s(<select id="search_key" multiple="" name="search[key][]">) <>
           ~s(<option value="1">foo</option>) <>
           ~s(<option value="2">bar</option>) <>
           ~s(</select>)

    assert safe_to_string(multiple_select(:search, :key, ~w(foo bar), value: ["foo"])) =~
           ~s(<option selected="selected" value="foo">foo</option>)

    assert safe_to_string(multiple_select(:search, :key, [{"foo", 1}, {"bar", 2}], value: [1])) =~
           ~s(<option selected="selected" value="1">foo</option>)

    assert safe_to_string(multiple_select(:search, :key, [{"foo", 1}, {"bar", 2}], default: [1])) =~
           ~s(<option selected="selected" value="1">foo</option>)

  end

  test "multiple_select/4 with form" do
    assert safe_form(&multiple_select(&1, :key, [{"foo", 1}, {"bar", 2}], value: [1], default: [2])) ==
           ~s(<select id="search_key" multiple="" name="search[key][]">) <>
           ~s(<option selected="selected" value="1">foo</option>) <>
           ~s(<option value="2">bar</option>) <>
           ~s(</select>)

    assert safe_form(&multiple_select(&1, :other, [{"foo", 1}, {"bar", 2}], default: [2])) ==
           ~s(<select id="search_other" multiple="" name="search[other][]">) <>
           ~s(<option value="1">foo</option>) <>
           ~s(<option selected="selected" value="2">bar</option>) <>
           ~s(</select>)

    assert safe_form(&multiple_select(&1, :key, [{"foo", 1}, {"bar", 2}], value: [2])) ==
           ~s(<select id="search_key" multiple="" name="search[key][]">) <>
           ~s(<option value="1">foo</option>) <>
           ~s(<option selected="selected" value="2">bar</option>) <>
           ~s(</select>)

    assert safe_form(&multiple_select(&1, :key, ~w(value novalue), value: ["novalue"])) ==
           ~s(<select id="search_key" multiple="" name="search[key][]">) <>
           ~s(<option value="value">value</option>) <>
           ~s(<option selected="selected" value="novalue">novalue</option>) <>
           ~s(</select>)

  end

  # date_select/4

  test "date_select/4" do
    content = safe_to_string(date_select(:search, :datetime))
    assert content =~ ~s(<select id="search_datetime_year" name="search[datetime][year]">)
    assert content =~ ~s(<select id="search_datetime_month" name="search[datetime][month]">)
    assert content =~ ~s(<select id="search_datetime_day" name="search[datetime][day]">)

    content = safe_to_string(date_select(:search, :datetime, value: {2020, 04, 17}))
    assert content =~ ~s(<option selected="selected" value="2020">2020</option>)
    assert content =~ ~s(<option selected="selected" value="4">April</option>)
    assert content =~ ~s(<option selected="selected" value="17">17</option>)

    content = safe_to_string(date_select(:search, :datetime,
                                               value: %{year: 2020, month: 04, day: 07}))
    assert content =~ ~s(<option selected="selected" value="2020">2020</option>)
    assert content =~ ~s(<option selected="selected" value="4">April</option>)
    assert content =~ ~s(<option selected="selected" value="7">07</option>)

    content = safe_to_string(date_select(:search, :datetime, year: [prompt: "Year"],
                                               month: [prompt: "Month"], day: [prompt: "Day"]))
    assert content =~ ~s(<select id="search_datetime_year" name="search[datetime][year]">) <>
                      ~s(<option value="">Year</option>)
    assert content =~ ~s(<select id="search_datetime_month" name="search[datetime][month]">) <>
                      ~s(<option value="">Month</option>)
    assert content =~ ~s(<select id="search_datetime_day" name="search[datetime][day]">) <>
                      ~s(<option value="">Day</option>)
  end

  test "date_select/4 with form" do
    content = safe_form(&date_select(&1, :datetime, default: {2020, 10, 13}))
    assert content =~ ~s(<select id="search_datetime_year" name="search[datetime][year]">)
    assert content =~ ~s(<select id="search_datetime_month" name="search[datetime][month]">)
    assert content =~ ~s(<select id="search_datetime_day" name="search[datetime][day]">)
    assert content =~ ~s(<option selected="selected" value="2020">2020</option>)
    assert content =~ ~s(<option selected="selected" value="4">April</option>)
    assert content =~ ~s(<option selected="selected" value="17">17</option>)
    assert content =~ ~s(<option value="1">January</option><option value="2">February</option>)

    content = safe_form(&date_select(&1, :unknown, default: {2020, 10, 13}))
    assert content =~ ~s(<option selected="selected" value="2020">2020</option>)
    assert content =~ ~s(<option selected="selected" value="10">October</option>)
    assert content =~ ~s(<option selected="selected" value="13">13</option>)

    content = safe_form(&date_select(&1, :datetime, value: {2020, 10, 13}))
    assert content =~ ~s(<option selected="selected" value="2020">2020</option>)
    assert content =~ ~s(<option selected="selected" value="10">October</option>)
    assert content =~ ~s(<option selected="selected" value="13">13</option>)
  end

  # time_select/4

  test "time_select/4" do
    content = safe_to_string(time_select(:search, :datetime))
    assert content =~ ~s(<select id="search_datetime_hour" name="search[datetime][hour]">)
    assert content =~ ~s(<select id="search_datetime_min" name="search[datetime][min]">)
    refute content =~ ~s(<select id="search_datetime_sec" name="search[datetime][sec]">)

    content = safe_to_string(time_select(:search, :datetime, sec: []))
    assert content =~ ~s(<select id="search_datetime_hour" name="search[datetime][hour]">)
    assert content =~ ~s(<select id="search_datetime_min" name="search[datetime][min]">)
    assert content =~ ~s(<select id="search_datetime_sec" name="search[datetime][sec]">)

    content = safe_to_string(time_select(:search, :datetime, value: {2, 11, 13}, sec: []))
    assert content =~ ~s(<option selected="selected" value="2">02</option>)
    assert content =~ ~s(<option selected="selected" value="11">11</option>)
    assert content =~ ~s(<option selected="selected" value="13">13</option>)

    content = safe_to_string(time_select(:search, :datetime, value: {2, 11, 13, 328904}, sec: []))
    assert content =~ ~s(<option selected="selected" value="2">02</option>)
    assert content =~ ~s(<option selected="selected" value="11">11</option>)
    assert content =~ ~s(<option selected="selected" value="13">13</option>)

    content = safe_to_string(time_select(:search, :datetime,
                                      value: %{hour: 2, min: 11, sec: 13}, sec: []))
    assert content =~ ~s(<option selected="selected" value="2">02</option>)
    assert content =~ ~s(<option selected="selected" value="11">11</option>)
    assert content =~ ~s(<option selected="selected" value="13">13</option>)

    content = safe_to_string(time_select(:search, :datetime, hour: [prompt: "Hour"],
                                               min: [prompt: "Minute"], sec: [prompt: "Second"]))
    assert content =~ ~s(<select id="search_datetime_hour" name="search[datetime][hour]">) <>
                      ~s(<option value="">Hour</option>)
    assert content =~ ~s(<select id="search_datetime_min" name="search[datetime][min]">) <>
                      ~s(<option value="">Minute</option>)
    assert content =~ ~s(<select id="search_datetime_sec" name="search[datetime][sec]">) <>
                      ~s(<option value="">Second</option>)
  end

  test "time_select/4 with form" do
    content = safe_form(&time_select(&1, :datetime, default: {1, 2, 3}, sec: []))
    assert content =~ ~s(<select id="search_datetime_hour" name="search[datetime][hour]">)
    assert content =~ ~s(<select id="search_datetime_min" name="search[datetime][min]">)
    assert content =~ ~s(<select id="search_datetime_sec" name="search[datetime][sec]">)
    assert content =~ ~s(<option selected="selected" value="2">02</option>)
    assert content =~ ~s(<option selected="selected" value="11">11</option>)
    assert content =~ ~s(<option selected="selected" value="13">13</option>)
    assert content =~ ~s(<option value="1">01</option><option value="2">02</option>)

    content = safe_form(&time_select(&1, :unknown, default: {1, 2, 3}, sec: []))
    assert content =~ ~s(<option selected="selected" value="1">01</option>)
    assert content =~ ~s(<option selected="selected" value="2">02</option>)
    assert content =~ ~s(<option selected="selected" value="3">03</option>)

    content = safe_form(&time_select(&1, :datetime, value: {1, 2, 3}, sec: []))
    assert content =~ ~s(<option selected="selected" value="1">01</option>)
    assert content =~ ~s(<option selected="selected" value="2">02</option>)
    assert content =~ ~s(<option selected="selected" value="3">03</option>)
  end

  # datetime_select/4

  test "datetime_select/4" do
    content = safe_to_string(datetime_select(:search, :datetime))
    assert content =~ ~s(<select id="search_datetime_year" name="search[datetime][year]">)
    assert content =~ ~s(<select id="search_datetime_month" name="search[datetime][month]">)
    assert content =~ ~s(<select id="search_datetime_day" name="search[datetime][day]">)
    assert content =~ ~s(<select id="search_datetime_hour" name="search[datetime][hour]">)
    assert content =~ ~s(<select id="search_datetime_min" name="search[datetime][min]">)
    refute content =~ ~s(<select id="search_datetime_sec" name="search[datetime][sec]">)

    content = safe_to_string(datetime_select(:search, :datetime, sec: []))
    assert content =~ ~s(<select id="search_datetime_year" name="search[datetime][year]">)
    assert content =~ ~s(<select id="search_datetime_month" name="search[datetime][month]">)
    assert content =~ ~s(<select id="search_datetime_day" name="search[datetime][day]">)
    assert content =~ ~s(<select id="search_datetime_hour" name="search[datetime][hour]">)
    assert content =~ ~s(<select id="search_datetime_min" name="search[datetime][min]">)
    assert content =~ ~s(<select id="search_datetime_sec" name="search[datetime][sec]">)

    content = safe_to_string(datetime_select(:search, :datetime,
                                          value: {{2020, 04, 17}, {2, 11, 13}}, sec: []))
    assert content =~ ~s(<option selected="selected" value="2020">2020</option>)
    assert content =~ ~s(<option selected="selected" value="4">April</option>)
    assert content =~ ~s(<option selected="selected" value="17">17</option>)
    assert content =~ ~s(<option selected="selected" value="2">02</option>)
    assert content =~ ~s(<option selected="selected" value="11">11</option>)
    assert content =~ ~s(<option selected="selected" value="13">13</option>)

    content = safe_to_string(datetime_select(:search, :datetime,
                                          value: {{2020, 04, 17}, {2, 11, 13, 328904}}, sec: []))
    assert content =~ ~s(<option selected="selected" value="2020">2020</option>)
    assert content =~ ~s(<option selected="selected" value="4">April</option>)
    assert content =~ ~s(<option selected="selected" value="17">17</option>)
    assert content =~ ~s(<option selected="selected" value="2">02</option>)
    assert content =~ ~s(<option selected="selected" value="11">11</option>)
    assert content =~ ~s(<option selected="selected" value="13">13</option>)
  end

  test "datetime_select/4 with form" do
    content = safe_form(&datetime_select(&1, :datetime, default: {{2020, 10, 13}, {1, 2, 3}}, sec: []))
    assert content =~ ~s(<select id="search_datetime_year" name="search[datetime][year]">)
    assert content =~ ~s(<select id="search_datetime_month" name="search[datetime][month]">)
    assert content =~ ~s(<select id="search_datetime_day" name="search[datetime][day]">)
    assert content =~ ~s(<option selected="selected" value="2020">2020</option>)
    assert content =~ ~s(<option selected="selected" value="4">April</option>)
    assert content =~ ~s(<option selected="selected" value="17">17</option>)

    assert content =~ ~s(<select id="search_datetime_hour" name="search[datetime][hour]">)
    assert content =~ ~s(<select id="search_datetime_min" name="search[datetime][min]">)
    assert content =~ ~s(<select id="search_datetime_sec" name="search[datetime][sec]">)
    assert content =~ ~s(<option selected="selected" value="2">02</option>)
    assert content =~ ~s(<option selected="selected" value="11">11</option>)
    assert content =~ ~s(<option selected="selected" value="13">13</option>)

    content = safe_form(&datetime_select(&1, :unknown, default: {{2020, 10, 13}, {1, 2, 3}}, sec: []))
    assert content =~ ~s(<option selected="selected" value="2020">2020</option>)
    assert content =~ ~s(<option selected="selected" value="10">October</option>)
    assert content =~ ~s(<option selected="selected" value="13">13</option>)
    assert content =~ ~s(<option selected="selected" value="1">01</option>)
    assert content =~ ~s(<option selected="selected" value="2">02</option>)
    assert content =~ ~s(<option selected="selected" value="3">03</option>)

    content = safe_form(&datetime_select(&1, :datetime, value: {{2020, 10, 13}, {1, 2, 3}}, sec: []))
    assert content =~ ~s(<option selected="selected" value="2020">2020</option>)
    assert content =~ ~s(<option selected="selected" value="10">October</option>)
    assert content =~ ~s(<option selected="selected" value="13">13</option>)
    assert content =~ ~s(<option selected="selected" value="1">01</option>)
    assert content =~ ~s(<option selected="selected" value="2">02</option>)
    assert content =~ ~s(<option selected="selected" value="3">03</option>)
  end

  test "datetime_select/4 with builder" do
    builder = fn b ->
      html_escape ["Year: ",  b.(:year, class: "year"),
                   "Month: ", b.(:month, class: "month"),
                   "Day: ",   b.(:day, class: "day"),
                   "Hour: ",  b.(:hour, class: "hour"),
                   "Min: ",   b.(:min, class: "min"),
                   "Sec: ",   b.(:sec, class: "sec")]
    end

    content = safe_to_string(datetime_select(:search, :datetime, builder: builder,
                                             year: [id: "year"], month: [id: "month"],
                                             day: [id: "day"], hour: [id: "hour"],
                                             min: [id: "min"], sec: [id: "sec"]))

    assert content =~ ~s(Year: <select class="year" id="year" name="search[datetime][year]">)
    assert content =~ ~s(Month: <select class="month" id="month" name="search[datetime][month]">)
    assert content =~ ~s(Day: <select class="day" id="day" name="search[datetime][day]">)
    assert content =~ ~s(Hour: <select class="hour" id="hour" name="search[datetime][hour]">)
    assert content =~ ~s(Min: <select class="min" id="min" name="search[datetime][min]">)
    assert content =~ ~s(Sec: <select class="sec" id="sec" name="search[datetime][sec]">)
  end

  ## label/4

  test "label/4" do
    assert safe_to_string(label(:search, :key, "Search")) ==
          ~s(<label for="search_key">Search</label>)

    assert safe_to_string(label(:search, :key, "Search", for: "test_key")) ==
          ~s(<label for="test_key">Search</label>)
  end

  test "label/4 with form" do
    assert safe_form(&label(&1, :key, "Search")) ==
          ~s(<label for="search_key">Search</label>)

    assert safe_form(&label(&1, :key, "Search", for: "test_key")) ==
          ~s(<label for="test_key">Search</label>)
  end

  test "label/4 with default value" do
    assert safe_to_string(label(:search, :key)) ==
          ~s(<label for="search_key">Key</label>)

    assert safe_to_string(label(:search, :key, for: "test_key")) ==
          ~s(<label for="test_key">Key</label>)
  end

  test "label/4 with form and default value" do
    assert safe_form(&label(&1, :key)) ==
          ~s(<label for="search_key">Key</label>)

    assert safe_form(&label(&1, :key, for: "test_key")) ==
          ~s(<label for="test_key">Key</label>)
  end
end
