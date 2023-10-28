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
    end
  end
end
