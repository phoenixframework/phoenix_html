defmodule Phoenix.HTML.FormTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML
  import Phoenix.HTML.Form
  doctest Phoenix.HTML.Form

  defp form(map \\ %{}, opts \\ []) do
    Phoenix.HTML.FormData.to_form(map, opts)
  end

  test "warns on string keys" do
    assert ExUnit.CaptureIO.capture_io(:stderr, fn -> form(%{foo: 123}) end) =~
             "a map with atom keys was given to a form. Maps are always considered parameters and " <>
               "therefore must have string keys, got: %{foo: 123}"
  end

  describe "input_value/2" do
    test "without form" do
      assert input_value(:search, :key) == nil
      assert input_value(:search, 1) == nil
      assert input_value(:search, "key") == nil
    end

    test "with form" do
      assert input_value(form(%{"key" => "value"}), :key) == "value"
      assert input_value(form(%{"key" => "value"}), "key") == "value"
    end

    test "with form and data" do
      form = %{form(%{"param_key" => "param"}) | data: %{data_key: "data"}}
      assert input_value(form, :key) == nil
      assert input_value(form, "key") == nil
      assert input_value(form, :data_key) == "data"
      assert input_value(form, :param_key) == "param"
      assert input_value(form, "param_key") == "param"
    end
  end

  describe "input_id/2" do
    test "without form" do
      assert input_id(:search, :key) == "search_key"
      assert input_id(:search, "key") == "search_key"
    end

    test "with form" do
      assert input_id(form(%{}, as: "search"), :key) == "search_key"
      assert input_id(form(%{}, as: :search), "key") == "search_key"
    end

    test "with form with no name" do
      assert input_id(form(), :key) == "key"
    end
  end

  describe "input_id/3" do
    test "without form" do
      assert input_id(:search, :key, "") == "search_key_"
      assert input_id(:search, :key, "foo") == "search_key_foo"
      assert input_id(:search, :key, "foo bar") == "search_key_foo_bar"
      assert input_id(:search, :key, "Foo baR") == "search_key_Foo_baR"
      assert input_id(:search, :key, "F✓o]o%b+a'R") == "search_key_F_o_o_b_a__39_R"
      assert input_id(:search, :key, nil) == "search_key_"
      assert input_id(:search, :key, 37) == "search_key_37"
      assert input_id(:search, :key, 0) == "search_key_0"
      assert input_id(:search, :key, -1) == "search_key__1"
    end

    test "with form with no name" do
      assert input_id(form(), :key, :value) == "key_value"
    end
  end

  describe "input_name/2" do
    test "without form" do
      assert input_name(:search, :key) == "search[key]"
      assert input_name(:search, "key") == "search[key]"
    end

    test "with form" do
      assert input_name(form(%{}, as: :search), :key) == "search[key]"
      assert input_name(form(%{}, as: :search), "key") == "search[key]"
    end

    test "with form with no name" do
      assert input_name(form(), :key) == "key"
      assert input_name(form(), "key") == "key"
    end
  end

  describe "normalize_value/2" do
    test "for checkbox" do
      assert normalize_value("checkbox", true) == true
      assert normalize_value("checkbox", "true") == true
      assert normalize_value("checkbox", 1) == false
      assert normalize_value("checkbox", nil) == false
      assert normalize_value("checkbox", false) == false
      assert normalize_value("checkbox", "truthy") == false
    end

    test "for datetime-local" do
      assert normalize_value("datetime-local", ~N[2017-09-21 20:21:53]) ==
               {:safe, ["2017-09-21", ?T, "20:21"]}

      assert normalize_value("datetime-local", "2017-09-21 20:21:53") ==
               "2017-09-21 20:21:53"

      assert normalize_value("datetime-local", "other") == "other"
    end

    test "for textarea" do
      assert safe_to_string(normalize_value("textarea", "<other>")) == "\n&lt;other&gt;"
      assert safe_to_string(normalize_value("textarea", "string")) == "\nstring"
      assert safe_to_string(normalize_value("textarea", 1234)) == "\n1234"
      assert safe_to_string(normalize_value("textarea", nil)) == "\n"
    end

    test "for anything else" do
      assert normalize_value("foo", "<other>") == "<other>"
    end
  end

  test "input_changed? with atom fields" do
    form = form(%{})
    refute input_changed?(form, form, :foo)
    assert input_changed?(form, %{form | errors: [foo: "bar"]}, :foo)
    assert input_changed?(form, %{form | name: "another"}, :foo)
    assert input_changed?(form, %{form | id: "another"}, :foo)
    assert input_changed?(form, form(%{"foo" => "bar"}), :foo)
  end

  test "input_changed? with string fields" do
    form = form(%{})
    refute input_changed?(form, form, "foo")
    assert input_changed?(form, %{form | errors: [{"foo", "bar"}]}, "foo")
    assert input_changed?(form, %{form | name: "another"}, "foo")
    assert input_changed?(form, %{form | id: "another"}, "foo")
    assert input_changed?(form, form(%{"foo" => "bar"}), "foo")
  end

  test "input_changed? with changed action or method" do
    form = form(%{}, action: :validate)
    refute input_changed?(form, %{form | action: :validate}, :foo)
    assert input_changed?(form, %{form | action: :save}, :foo)
  end

  describe "access" do
    test "without name and atom keys" do
      form =
        form(%{"key" => "value"})
        |> Map.replace!(:errors, atom: "oops")
        |> Map.replace!(:data, %{atom: "data"})

      assert form[:key] == %Phoenix.HTML.FormField{
               field: :key,
               id: "key",
               form: form,
               value: "value",
               name: "key",
               errors: []
             }

      assert form[:atom] == %Phoenix.HTML.FormField{
               field: :atom,
               id: "atom",
               form: form,
               value: "data",
               name: "atom",
               errors: ["oops"]
             }

      assert form[:key][:id] == "key"
      assert form[:atom][:value] == "data"
    end

    test "with name and atom keys" do
      form =
        form(%{"key" => "value"}, as: :search)
        |> Map.replace!(:errors, atom: "oops")
        |> Map.replace!(:data, %{atom: "data"})

      assert form[:key] == %Phoenix.HTML.FormField{
               field: :key,
               id: "search_key",
               form: form,
               value: "value",
               name: "search[key]",
               errors: []
             }

      assert form[:atom] == %Phoenix.HTML.FormField{
               field: :atom,
               id: "search_atom",
               form: form,
               value: "data",
               name: "search[atom]",
               errors: ["oops"]
             }

      assert form[:key][:id] == "search_key"
      assert form[:atom][:value] == "data"
    end

    test "without name and string keys" do
      form =
        form(%{"key" => "value"})
        |> Map.replace!(:errors, [{"string", "oops"}])
        |> Map.replace!(:data, %{"string" => "data"})

      assert form["key"] == %Phoenix.HTML.FormField{
               field: "key",
               id: "key",
               form: form,
               value: "value",
               name: "key",
               errors: []
             }

      assert form["string"] == %Phoenix.HTML.FormField{
               field: "string",
               id: "string",
               form: form,
               value: "data",
               name: "string",
               errors: ["oops"]
             }

      assert form["key"][:id] == "key"
      assert form["string"][:value] == "data"
    end

    test "with name and string keys" do
      form =
        form(%{"key" => "value"}, as: :search)
        |> Map.replace!(:errors, [{"string", "oops"}])
        |> Map.replace!(:data, %{"string" => "data"})

      assert form["key"] == %Phoenix.HTML.FormField{
               field: "key",
               id: "search_key",
               form: form,
               value: "value",
               name: "search[key]",
               errors: []
             }

      assert form["string"] == %Phoenix.HTML.FormField{
               field: "string",
               id: "search_string",
               form: form,
               value: "data",
               name: "search[string]",
               errors: ["oops"]
             }

      assert form["key"][:id] == "search_key"
      assert form["string"][:value] == "data"
    end
  end

  describe "options_for_select/2" do
    test "simple" do
      assert options_for_select(["value", "novalue", nil], "novalue") |> safe_to_string() ==
               ~s(<option value="value">value</option>) <>
                 ~s(<option selected value="novalue">novalue</option>) <>
                 ~s(<option value=""></option>)

      assert options_for_select(["value", :hr, "novalue"], "novalue") |> safe_to_string() ==
               ~s(<option value="value">value</option>) <>
                 ~s(<hr/>) <>
                 ~s(<option selected value="novalue">novalue</option>)

      assert options_for_select(
               [
                 [value: "value", key: "Value", disabled: true],
                 :hr,
                 [value: "novalue", key: "No Value"],
                 [value: nil, key: nil]
               ],
               "novalue"
             )
             |> safe_to_string() ==
               ~s(<option disabled value="value">Value</option>) <>
                 ~s(<hr/>) <>
                 ~s(<option selected value="novalue">No Value</option>) <>
                 ~s(<option value=""></option>)

      assert options_for_select(~w(value novalue), ["value", "novalue"]) |> safe_to_string() ==
               ~s(<option selected value="value">value</option>) <>
                 ~s(<option selected value="novalue">novalue</option>)

      assert options_for_select([Label: "value", hr: nil, New: "new"], nil) |> safe_to_string() ==
               ~s(<option value="value">Label</option>) <>
                 ~s(<hr/>) <>
                 ~s(<option value="new">New</option>)
    end

    test "with groups" do
      assert options_for_select([{"foo", ["bar", :hr, "baz"]}, {"qux", ~w(qux quz)}], "qux")
             |> safe_to_string() ==
               ~s(<optgroup label="foo">) <>
                 ~s(<option value="bar">bar</option>) <>
                 ~s(<hr/>) <>
                 ~s(<option value="baz">baz</option>) <>
                 ~s(</optgroup>) <>
                 ~s(<optgroup label="qux">) <>
                 ~s(<option selected value="qux">qux</option>) <>
                 ~s(<option value="quz">quz</option>) <> ~s(</optgroup>)

      assert options_for_select([{"foo", ~w(bar baz)}, {"qux", ~w(qux quz)}], ["baz", "qux"])
             |> safe_to_string() ==
               ~s(<optgroup label="foo">) <>
                 ~s(<option value="bar">bar</option>) <>
                 ~s(<option selected value="baz">baz</option>) <>
                 ~s(</optgroup>) <>
                 ~s(<optgroup label="qux">) <>
                 ~s(<option selected value="qux">qux</option>) <>
                 ~s(<option value="quz">quz</option>) <> ~s(</optgroup>)
    end
  end

  describe "to_form/4" do
    defp nested_form(field, opts \\ []) do
      map = %{
        "date" => %{"year" => "2020", "month" => "4", "day" => "17"},
        "dates" => %{
          "0" => %{"year" => "2010", "month" => "4", "day" => "17"},
          "1" => %{"year" => "2020", "month" => "4", "day" => "17"}
        }
      }

      form = Phoenix.HTML.FormData.to_form(map, as: "search", action: :validate)
      Phoenix.HTML.FormData.to_form(map, form, field, opts)
    end

    ## Cardinality one

    test "one: without default and field is not present" do
      [f] = nested_form(:unknown)
      assert f.index == nil
      assert f.impl == Phoenix.HTML.FormData.Map

      assert %Phoenix.HTML.FormField{
               id: "search_unknown_year",
               name: "search[unknown][year]",
               field: :year,
               form: %{action: :validate},
               value: nil
             } = f[:year]
    end

    test "one: without default and field is present" do
      [f] = nested_form(:date)

      assert %Phoenix.HTML.FormField{
               id: "search_date_year",
               name: "search[date][year]",
               field: :year,
               form: %{action: :validate},
               value: "2020"
             } = f[:year]
    end

    test "one: with default and field is not present" do
      [f] = nested_form(:unknown, default: %{year: 2015})

      assert %Phoenix.HTML.FormField{
               id: "search_unknown_year",
               name: "search[unknown][year]",
               field: :year,
               form: %{action: :validate},
               value: 2015
             } = f[:year]
    end

    test "one: with default and field is present" do
      [f] = nested_form(:date, default: %{year: 2015})

      assert %Phoenix.HTML.FormField{
               id: "search_date_year",
               name: "search[date][year]",
               field: :year,
               form: %{action: :validate},
               value: "2020"
             } = f[:year]
    end

    test "one: with custom name, id, and action" do
      [f] = nested_form(:date, as: :foo, id: :bar, action: :another)

      assert %Phoenix.HTML.FormField{
               id: "bar_year",
               name: "foo[year]",
               field: :year,
               form: %{action: :another},
               value: "2020"
             } = f[:year]
    end

    # ## Cardinality many

    test "many: with defaults" do
      [f1, f2] = nested_form(:unknown, default: [%{}, %{}])

      assert f1.index == 0

      assert %Phoenix.HTML.FormField{
               id: "search_unknown_0_year",
               name: "search[unknown][0][year]",
               field: :year,
               value: nil
             } = f1[:year]

      assert f2.index == 1

      assert %Phoenix.HTML.FormField{
               id: "search_unknown_1_year",
               name: "search[unknown][1][year]",
               field: :year,
               value: nil
             } = f2[:year]
    end

    test "many: with default and field is present" do
      [f1, f2] = nested_form(:dates, default: [%{year: 1000}, %{year: 1001}])

      assert %Phoenix.HTML.FormField{
               id: "search_dates_0_year",
               name: "search[dates][0][year]",
               field: :year,
               value: "2010"
             } = f1[:year]

      assert %Phoenix.HTML.FormField{
               id: "search_dates_1_year",
               name: "search[dates][1][year]",
               field: :year,
               value: "2020"
             } = f2[:year]
    end

    test "many: with name and id" do
      [f1, f2] = nested_form(:dates, default: [%{year: 1000}, %{year: 1001}], as: :foo, id: :bar)

      assert %Phoenix.HTML.FormField{
               id: "bar_0_year",
               name: "foo[0][year]",
               field: :year,
               value: "2010"
             } = f1[:year]

      assert %Phoenix.HTML.FormField{
               id: "bar_1_year",
               name: "foo[1][year]",
               field: :year,
               value: "2020"
             } = f2[:year]
    end

    @prepend_append [
      prepend: [%{year: 2008}],
      append: [%{year: 2022}],
      default: [%{year: 2012}, %{year: 2018}]
    ]

    test "many: inputs_for/4 with prepend/append and field is not present" do
      [f0, f1, f2, f3] = nested_form(:unknown, @prepend_append)

      assert %Phoenix.HTML.FormField{
               id: "search_unknown_0_year",
               name: "search[unknown][0][year]",
               field: :year,
               value: 2008
             } = f0[:year]

      assert %Phoenix.HTML.FormField{
               id: "search_unknown_1_year",
               name: "search[unknown][1][year]",
               field: :year,
               value: 2012
             } = f1[:year]

      assert %Phoenix.HTML.FormField{
               id: "search_unknown_2_year",
               name: "search[unknown][2][year]",
               field: :year,
               value: 2018
             } = f2[:year]

      assert %Phoenix.HTML.FormField{
               id: "search_unknown_3_year",
               name: "search[unknown][3][year]",
               field: :year,
               value: 2022
             } = f3[:year]
    end

    test "many: with prepend/append and field is present" do
      [f1, f2] = nested_form(:dates, @prepend_append)

      assert %Phoenix.HTML.FormField{
               id: "search_dates_0_year",
               name: "search[dates][0][year]",
               field: :year,
               value: "2010"
             } = f1[:year]

      assert %Phoenix.HTML.FormField{
               id: "search_dates_1_year",
               name: "search[dates][1][year]",
               field: :year,
               value: "2020"
             } = f2[:year]
    end
  end
end
