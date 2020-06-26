defmodule Phoenix.HTML.FormTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML
  import Phoenix.HTML.Form
  doctest Phoenix.HTML.Form

  @doc """
  A function that executes `form_for/4` and
  extracts its inner contents for assertion.
  """
  def safe_form(fun, opts \\ [as: :search]) do
    mark = "--PLACEHOLDER--"

    contents =
      safe_to_string(
        form_for(conn(), "/", opts, fn f ->
          html_escape([mark, fun.(f), mark])
        end)
      )

    [_, inner, _] = String.split(contents, mark)
    inner
  end

  defp conn do
    Plug.Test.conn(:get, "/foo", %{"search" => search_params()})
  end

  defp search_params do
    %{
      "key" => "value",
      "time" => ~T[01:02:03.004005],
      "alt_key" => nil,
      "datetime" => %{
        "year" => "2020",
        "month" => "4",
        "day" => "17",
        "hour" => "2",
        "minute" => "11",
        "second" => "13"
      },
      "naive_datetime" => ~N[2000-01-01 10:00:42]
    }
  end

  ## form_for/3

  describe "form_for/3 with connection" do
    test "without options" do
      form = form_for(conn(), "/")
      assert %Phoenix.HTML.Form{} = form

      contents = form |> html_escape() |> safe_to_string()
      assert contents =~ ~s(<form action="/" method="post">)
    end

    test "with custom options" do
      form = form_for(conn(), "/", as: :search, method: :put, multipart: true)
      assert %Phoenix.HTML.Form{} = form

      contents = form |> html_escape() |> safe_to_string()
      assert contents =~ ~s(<form action="/" enctype="multipart/form-data" method="post">)
      assert contents =~ ~s(method="post")
      assert contents =~ ~s(<input name="_method" type="hidden" value="put">)
      refute contents =~ ~s(</form>)
    end
  end

  describe "form_for/3 with atom" do
    test "without options" do
      form = form_for(:search, "/", [])
      assert %Phoenix.HTML.Form{} = form

      contents = form |> html_escape() |> safe_to_string()
      assert contents =~ ~s(<form action="/" method="post">)
    end

    test "with custom options" do
      form = form_for(:search, "/", method: :put, multipart: true)
      assert %Phoenix.HTML.Form{} = form

      contents = form |> html_escape() |> safe_to_string()

      assert contents =~
               ~s(<form action="/" enctype="multipart/form-data" method="post">)

      assert contents =~ ~s(method="post")
      assert contents =~ ~s(<input name="_method" type="hidden" value="put">)
      refute contents =~ ~s(</form>)
    end

    test "with id prefix the form id in the input id" do
      form = form_for(:search, "/", id: "form_id")
      assert %Phoenix.HTML.Form{} = form

      form_content =
        form
        |> html_escape()
        |> safe_to_string()

      input_content =
        form
        |> text_input(:name)
        |> html_escape()
        |> safe_to_string()

      assert form_content  =~ ~s(<form action="/" id="form_id" method="post">)
      assert input_content =~ ~s(<input id="form_id_name" name="search[name]" type="text">)
    end

    test "without id prefix the form name in the input id" do
      form = form_for(:search, "/")
      assert %Phoenix.HTML.Form{} = form

      form_content =
        form
        |> html_escape()
        |> safe_to_string()

      contents =
        form
        |> text_input(:name)
        |> html_escape()
        |> safe_to_string()

      assert form_content  =~ ~s(<form action="/" method="post">)
      assert contents =~ ~s(<input id="search_name" name="search[name]" type="text">)
    end
  end

  describe "form_for/4 with connection" do
    test "with :as" do
      conn = conn()

      form =
        safe_to_string(
          form_for(conn, "/", [as: :search], fn f ->
            assert f.impl == Phoenix.HTML.FormData.Plug.Conn
            assert f.name == "search"
            assert f.source == conn
            assert f.params["key"] == "value"
            ""
          end)
        )

      assert form =~ ~s(<form action="/" method="post">)
    end

    test "without :as" do
      form =
        safe_to_string(
          form_for(conn(), "/", fn f ->
            text_input(f, :key)
          end)
        )

      assert form =~ ~s(<input id="key" name="key" type="text">)
    end

    test "with custom options" do
      form =
        safe_to_string(
          form_for(conn(), "/", [as: :search, method: :put, multipart: true], fn f ->
            refute f.options[:name]
            assert f.options[:multipart] == true
            assert f.options[:method] == :put
            ""
          end)
        )

      assert form =~
               ~s(<form action="/" enctype="multipart/form-data" method="post">)

      assert form =~ ~s(<input name="_method" type="hidden" value="put">)
    end

    test "is html safe" do
      form = safe_to_string(form_for(conn(), "/", [as: :search], fn _ -> "<>" end))
      assert form =~ ~s(&lt;&gt;</form>)
    end

    test "with type and validations" do
      form =
        safe_to_string(
          form_for(conn(), "/", [as: :search], fn f ->
            assert input_type(f, :hello) == :text_input
            assert input_type(f, :email) == :email_input
            assert input_type(f, :search) == :search_input
            assert input_type(f, :password) == :password_input
            assert input_type(f, :special_url) == :url_input
            assert input_type(f, :number, %{"number" => :number_input}) == :number_input
            assert input_validations(f, :hello) == []
            ""
          end)
        )

      assert form =~ "<form"
    end

    test "with errors through options" do
      errors = [field: {"error message!", []}]

      form =
        safe_to_string(
          form_for(conn(), "/", [errors: errors], fn f ->
            for {field, {message, _}} <- f.errors do
              Phoenix.HTML.Tag.content_tag(:span, humanize(field) <> " " <> message,
                class: "errors"
              )
            end
          end)
        )

      assert form =~ ~s(<span class="errors">Field error message!</span>)
    end
  end

  describe "form_for/4 with atom" do
    test "without params" do
      form =
        safe_to_string(
          form_for(:search, "/", fn f ->
            assert f.impl == Phoenix.HTML.FormData.Atom
            assert f.name == "search"
            assert f.source == :search
            assert f.params == %{}
            ""
          end)
        )

      assert form =~ ~s(<form action="/" method="post">)
    end

    test "with params" do
      form =
        safe_to_string(
          form_for(:search, "/", [params: search_params()], fn f ->
            text_input(f, :key)
          end)
        )

      assert form =~ ~s(<input id="search_key" name="search[key]" type="text" value="value">)
    end

    test "with custom options" do
      form =
        safe_to_string(
          form_for(:search, "/", [method: :put, multipart: true], fn f ->
            refute f.options[:name]
            assert f.options[:multipart] == true
            assert f.options[:method] == :put
            ""
          end)
        )

      assert form =~
               ~s(<form action="/" enctype="multipart/form-data" method="post">)

      assert form =~ ~s(<input name="_method" type="hidden" value="put">)
    end

    test "is html safe" do
      form = safe_to_string(form_for(conn(), "/", [as: :search], fn _ -> "<>" end))
      assert form =~ ~s(&lt;&gt;</form>)
    end

    test "with type and validations" do
      form =
        safe_to_string(
          form_for(:search, "/", [], fn f ->
            assert input_type(f, :hello) == :text_input
            assert input_type(f, :email) == :email_input
            assert input_type(f, :search) == :search_input
            assert input_type(f, :password) == :password_input
            assert input_type(f, :special_url) == :url_input
            assert input_type(f, :number, %{"number" => :number_input}) == :number_input
            assert input_validations(f, :hello) == []
            ""
          end)
        )

      assert form =~ "<form"
    end

    test "with errors through options" do
      errors = [field: {"error message!", []}]

      form =
        safe_to_string(
          form_for(conn(), "/", [errors: errors], fn f ->
            for {field, {message, _}} <- f.errors do
              Phoenix.HTML.Tag.content_tag(:span, humanize(field) <> " " <> message,
                class: "errors"
              )
            end
          end)
        )

      assert form =~ ~s(<span class="errors">Field error message!</span>)
    end

    test "with id prefix the form id in the input id" do
      form =
        safe_to_string(
          form_for(:search, "/", [params: search_params(), id: "form_id"], fn f ->
            text_input(f, :key)
          end)
        )

      assert form =~
               ~s(<input id="form_id_key" name="search[key]" type="text" value="value">)
    end
  end

  describe "inputs_for/3" do
    test "generate a new form builder for the given parameter" do
      conn = conn()

      form =
        form_for(conn, "/", [as: :user], fn form ->
          for company_form <- inputs_for(form, :company) do
            text_input(company_form, :name)
          end
        end)
        |> safe_to_string()

      assert form =~ ~s(<input id="user_company_name" name="user[company][name]" type="text">)
    end

    test "support options" do
      conn = conn()

      form =
        form_for(conn, "/", [as: :user], fn form ->
          for company_form <- inputs_for(form, :company, as: :new_company, id: :custom_id) do
            text_input(company_form, :name)
          end
        end)
        |> safe_to_string()

      assert form =~ ~s(<input id="custom_id_name" name="new_company[name]" type="text">)
    end

    test "support atom or binary field" do
      form = form_for(:user, "/")

      [f] = inputs_for(form, :key)
      assert f.name == "user[key]"
      assert f.id == "user_key"

      [f] = inputs_for(form, "key")
      assert f.name == "user[key]"
      assert f.id == "user_key"
    end
  end

  describe "inputs_for/4" do
    test "generate a new form builder for the given parameter" do
      conn = conn()

      form =
        form_for(conn, "/", [as: :user], fn form ->
          inputs_for(form, :company, fn company_form ->
            text_input(company_form, :name)
          end)
        end)
        |> safe_to_string()

      assert form =~ ~s(<input id="user_company_name" name="user[company][name]" type="text">)
    end

    test "generate a new form builder with hidden inputs when they are present" do
      conn = conn()

      form =
        form_for(conn, "/", [as: :user], fn form ->
          inputs_for(form, :company, [hidden: [id: 1]], fn company_form ->
            text_input(company_form, :name)
          end)
        end)
        |> safe_to_string()

      assert form =~
               ~s(input id="user_company_id" name="user[company][id]" type="hidden" value="1">)

      assert form =~ ~s(<input id="user_company_name" name="user[company][name]" type="text">)
    end

    test "skip hidden inputs" do
      conn = conn()

      form =
        form_for(conn, "/", [as: :user], fn form ->
          inputs_for(form, :company, [skip_hidden: true, hidden: [id: 1]], fn company_form ->
            text_input(company_form, :name)
          end)
        end)
        |> safe_to_string()

      refute form =~
               ~s(input id="user_company_id" name="user[company][id]" type="hidden" value="1">)

      assert form =~ ~s(<input id="user_company_name" name="user[company][name]" type="text">)
    end
  end

  ## text_input/3

  test "text_input/3" do
    assert safe_to_string(text_input(:search, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="text">)

    assert safe_to_string(
             text_input(:search, :key, value: "foo", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="text" value="foo">)
  end

  test "text_input/3 with form" do
    assert safe_form(&text_input(&1, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="text" value="value">)

    assert safe_form(&text_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
             ~s(<input id="key" name="search[key][]" type="text" value="foo">)
  end

  test "text_input/3 with form and data" do
    assert safe_form(&text_input(put_in(&1.data[:key], "original"), :key)) ==
             ~s(<input id="search_key" name="search[key]" type="text" value="value">)

    assert safe_form(&text_input(put_in(&1.data[:no_key], "original"), :no_key)) ==
             ~s(<input id="search_no_key" name="search[no_key]" type="text" value="original">)

    assert safe_form(&text_input(put_in(&1.data[:alt_key], "original"), :alt_key)) ==
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

  test "textarea/3 with non-binary type" do
    assert safe_form(&textarea(&1, :key, value: :atom_value)) ==
             ~s(<textarea id="search_key" name="search[key]">\natom_value</textarea>)
  end

  ## number_input/3

  test "number_input/3" do
    assert safe_to_string(number_input(:search, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="number">)

    assert safe_to_string(
             number_input(:search, :key, value: "foo", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="number" value="foo">)
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

    assert safe_to_string(
             hidden_input(:search, :key, value: "foo", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="hidden" value="foo">)

    assert safe_to_string(
             hidden_input(:search, :key, value: true, id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="hidden" value="true">)

    assert safe_to_string(
             hidden_input(:search, :key, value: false, id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="hidden" value="false">)
  end

  test "hidden_input/3 with form" do
    assert safe_form(&hidden_input(&1, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="hidden" value="value">)

    assert safe_form(&hidden_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
             ~s(<input id="key" name="search[key][]" type="hidden" value="foo">)
  end

  describe "hidden_inputs_for/1" do
    test "generates hidden fields from the given form" do
      form = %{form_for(conn(), "/") | hidden: [id: 1]}

      assert hidden_inputs_for(form) == [hidden_input(form, :id, value: 1)]
    end
  end

  ## email_input/3

  test "email_input/3" do
    assert safe_to_string(email_input(:search, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="email">)

    assert safe_to_string(
             email_input(:search, :key, value: "foo", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="email" value="foo">)
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

    assert safe_to_string(
             password_input(:search, :key, value: "foo", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="password" value="foo">)
  end

  test "password_input/3 with form" do
    assert safe_form(&password_input(&1, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="password">)

    assert safe_form(&password_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
             ~s(<input id="key" name="search[key][]" type="password" value="foo">)
  end

  ## file_input/3

  test "file_input/3" do
    assert safe_to_string(file_input(:search, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="file">)

    assert safe_to_string(file_input(:search, :key, id: "key", name: "search[key][]")) ==
             ~s(<input id="key" name="search[key][]" type="file">)

    assert safe_to_string(file_input(:search, :key, multiple: true)) ==
             ~s(<input id="search_key" name="search[key][]" type="file" multiple>)
  end

  test "file_input/3 with form" do
    assert_raise ArgumentError, fn ->
      safe_form(&file_input(&1, :key))
    end

    assert safe_form(&file_input(&1, :key), multipart: true, as: :search) ==
             ~s(<input id="search_key" name="search[key]" type="file">)
  end

  ## url_input/3

  test "url_input/3" do
    assert safe_to_string(url_input(:search, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="url">)

    assert safe_to_string(
             url_input(:search, :key, value: "foo", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="url" value="foo">)
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

    assert safe_to_string(
             search_input(:search, :key, value: "foo", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="search" value="foo">)
  end

  test "search_input/3 with form" do
    assert safe_form(&search_input(&1, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="search" value="value">)

    assert safe_form(&search_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
             ~s(<input id="key" name="search[key][]" type="search" value="foo">)
  end

  ## color_input/3

  test "color_input/3" do
    assert safe_to_string(color_input(:search, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="color">)

    assert safe_to_string(
             color_input(:search, :key, value: "#123456", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="color" value="#123456">)
  end

  test "color_input/3 with form" do
    assert safe_form(&color_input(&1, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="color" value="value">)

    assert safe_form(&color_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
             ~s(<input id="key" name="search[key][]" type="color" value="foo">)
  end

  ## telephone_input/3

  test "telephone_input/3" do
    assert safe_to_string(telephone_input(:search, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="tel">)

    assert safe_to_string(
             telephone_input(:search, :key, value: "foo", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="tel" value="foo">)
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

    assert safe_to_string(
             range_input(:search, :key, value: "foo", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="range" value="foo">)
  end

  test "range_input/3 with form" do
    assert safe_form(&range_input(&1, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="range" value="value">)

    assert safe_form(&range_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
             ~s(<input id="key" name="search[key][]" type="range" value="foo">)
  end

  ## date_input/3

  test "date_input/3" do
    assert safe_to_string(date_input(:search, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="date">)

    assert safe_to_string(
             date_input(:search, :key, value: "foo", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="date" value="foo">)

    assert safe_to_string(
             date_input(:search, :key, value: ~D[2017-09-21], id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="date" value="2017-09-21">)
  end

  test "date_input/3 with form" do
    assert safe_form(&date_input(&1, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="date" value="value">)

    assert safe_form(&date_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
             ~s(<input id="key" name="search[key][]" type="date" value="foo">)

    assert safe_form(
             &date_input(&1, :key, value: ~D[2017-09-21], id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="date" value="2017-09-21">)
  end

  ## datetime_input/3

  test "datetime_local_input/3" do
    assert safe_to_string(datetime_local_input(:search, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="datetime-local">)

    assert safe_form(&datetime_local_input(&1, :naive_datetime)) ==
             ~s(<input id="search_naive_datetime" name="search[naive_datetime]" type="datetime-local" value="2000-01-01T10:00">)

    assert safe_to_string(
             datetime_local_input(:search, :key, value: "foo", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="datetime-local" value="foo">)

    assert safe_to_string(
             datetime_local_input(
               :search,
               :key,
               value: ~N[2017-09-21 20:21:53],
               id: "key",
               name: "search[key][]"
             )
           ) ==
             ~s(<input id="key" name="search[key][]" type="datetime-local" value="2017-09-21T20:21">)
  end

  test "datetime_local_input/3 with form" do
    assert safe_form(&datetime_local_input(&1, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="datetime-local" value="value">)

    assert safe_form(
             &datetime_local_input(&1, :key, value: "foo", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="datetime-local" value="foo">)

    assert safe_form(
             &datetime_local_input(
               &1,
               :key,
               value: ~N[2017-09-21 20:21:53],
               id: "key",
               name: "search[key][]"
             )
           ) ==
             ~s(<input id="key" name="search[key][]" type="datetime-local" value="2017-09-21T20:21">)
  end

  ## time_input/3

  test "time_input/3" do
    assert safe_to_string(time_input(:search, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="time">)

    assert safe_to_string(
             time_input(:search, :key, value: "foo", id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="time" value="foo">)

    assert safe_to_string(
             time_input(:search, :key, value: ~T[23:00:07.001], id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="time" value="23:00">)
  end

  test "time_input/3 with form" do
    assert safe_form(&time_input(&1, :key)) ==
             ~s(<input id="search_key" name="search[key]" type="time" value="value">)

    assert safe_form(&time_input(&1, :time)) ==
             ~s(<input id="search_time" name="search[time]" type="time" value="01:02">)

    if Version.match?(System.version(), ">= 1.6.0") do
      assert safe_form(&time_input(&1, :time, precision: :second)) ==
               ~s(<input id="search_time" name="search[time]" type="time" value="01:02:03">)

      assert safe_form(&time_input(&1, :time, precision: :millisecond)) ==
               ~s(<input id="search_time" name="search[time]" type="time" value="01:02:03.004">)
    end

    assert safe_form(&time_input(&1, :key, value: "foo", id: "key", name: "search[key][]")) ==
             ~s(<input id="key" name="search[key][]" type="time" value="foo">)

    assert safe_form(
             &time_input(&1, :key, value: ~T[23:00:07.001], id: "key", name: "search[key][]")
           ) == ~s(<input id="key" name="search[key][]" type="time" value="23:00">)
  end

  ## submit/2

  test "submit/2" do
    assert safe_to_string(submit("Submit")) == ~s(<button type="submit">Submit</button>)

    assert safe_to_string(submit("Submit", class: "btn")) ==
             ~s(<button class="btn" type="submit">Submit</button>)

    assert safe_to_string(submit([class: "btn"], do: "Submit")) ==
             ~s(<button class="btn" type="submit">Submit</button>)

    assert safe_to_string(submit(do: "Submit")) == ~s(<button type="submit">Submit</button>)

    assert safe_to_string(submit("<Submit>")) == ~s(<button type="submit">&lt;Submit&gt;</button>)

    assert safe_to_string(submit("<Submit>", class: "btn")) ==
             ~s(<button class="btn" type="submit">&lt;Submit&gt;</button>)

    assert safe_to_string(submit([class: "btn"], do: "<Submit>")) ==
             ~s(<button class="btn" type="submit">&lt;Submit&gt;</button>)

    assert safe_to_string(submit(do: "<Submit>")) ==
             ~s(<button type="submit">&lt;Submit&gt;</button>)
  end

  ## reset/2

  test "reset/2" do
    assert safe_to_string(reset("Reset")) == ~s(<input type="reset" value="Reset">)

    assert safe_to_string(reset("Reset", class: "btn")) ==
             ~s(<input class="btn" type="reset" value="Reset">)
  end

  ## radio_button/4

  test "radio_button/4" do
    assert safe_to_string(radio_button(:search, :key, "admin")) ==
             ~s(<input id="search_key_admin" name="search[key]" type="radio" value="admin">)

    assert safe_to_string(radio_button(:search, :key, "admin", checked: true)) ==
             ~s(<input id="search_key_admin" name="search[key]" type="radio" value="admin" checked>)

    assert safe_to_string(radio_button(:search, :key, "value with spaces")) ==
             ~s(<input id="search_key_value_with_spaces" name="search[key]" type="radio" value="value with spaces">)

    assert safe_to_string(radio_button(:search, :key, "F✓o]o%b+a'R")) ==
             ~s(<input id="search_key_F_o_o_b_a__39_R" name="search[key]" type="radio" value="F✓o]o%b+a&#39;R">)
  end

  test "radio_button/4 with form" do
    assert safe_form(&radio_button(&1, :key, :admin)) ==
             ~s(<input id="search_key_admin" name="search[key]" type="radio" value="admin">)

    assert safe_form(&radio_button(&1, :key, :value)) ==
             ~s(<input id="search_key_value" name="search[key]" type="radio" value="value" checked>)

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
               ~s(<input id="search_key" name="search[key]" type="checkbox" value="true" checked>)

    assert safe_to_string(checkbox(:search, :key, checked: true)) ==
             ~s(<input name="search[key]" type="hidden" value="false">) <>
               ~s(<input id="search_key" name="search[key]" type="checkbox" value="true" checked>)

    assert safe_to_string(checkbox(:search, :key, checked: true, disabled: true)) ==
             ~s(<input name="search[key]" type="hidden" value="false" disabled>) <>
               ~s(<input id="search_key" name="search[key]" type="checkbox" value="true" checked disabled>)

    assert safe_to_string(checkbox(:search, :key, value: "true", checked: false)) ==
             ~s(<input name="search[key]" type="hidden" value="false">) <>
               ~s(<input id="search_key" name="search[key]" type="checkbox" value="true">)

    assert safe_to_string(checkbox(:search, :key, value: 0, checked_value: 1, unchecked_value: 0)) ==
             ~s(<input name="search[key]" type="hidden" value="0">) <>
               ~s(<input id="search_key" name="search[key]" type="checkbox" value="1">)

    assert safe_to_string(checkbox(:search, :key, value: 1, checked_value: 1, unchecked_value: 0)) ==
             ~s(<input name="search[key]" type="hidden" value="0">) <>
               ~s(<input id="search_key" name="search[key]" type="checkbox" value="1" checked>)

    assert safe_to_string(checkbox(:search, :key, value: 1, hidden_input: false)) ==
             ~s(<input id="search_key" name="search[key]" type="checkbox" value="true">)
  end

  test "checkbox/3 with form" do
    assert safe_form(&checkbox(&1, :key)) ==
             ~s(<input name="search[key]" type="hidden" value="false">) <>
               ~s(<input id="search_key" name="search[key]" type="checkbox" value="true">)

    assert safe_form(&checkbox(&1, :key, value: true)) ==
             ~s(<input name="search[key]" type="hidden" value="false">) <>
               ~s(<input id="search_key" name="search[key]" type="checkbox" value="true" checked>)

    assert safe_form(&checkbox(&1, :key, checked_value: :value, unchecked_value: :novalue)) ==
             ~s(<input name="search[key]" type="hidden" value="novalue">) <>
               ~s(<input id="search_key" name="search[key]" type="checkbox" value="value" checked>)
  end

  # select/4

  test "select/4" do
    assert safe_to_string(select(:search, :key, ~w(foo bar))) ==
             ~s(<select id="search_key" name="search[key]">) <>
               ~s(<option value="foo">foo</option>) <>
               ~s(<option value="bar">bar</option>) <> ~s(</select>)

    assert safe_to_string(select(:search, :key, Foo: "foo", Bar: "bar")) ==
             ~s(<select id="search_key" name="search[key]">) <>
               ~s(<option value="foo">Foo</option>) <>
               ~s(<option value="bar">Bar</option>) <> ~s(</select>)

    assert safe_to_string(
             select(:search, :key, [
               [key: "Foo", value: "foo"],
               [key: "Bar", value: "bar", disabled: true]
             ])
           ) ==
             ~s(<select id="search_key" name="search[key]">) <>
               ~s(<option value="foo">Foo</option>) <>
               ~s(<option value="bar" disabled>Bar</option>) <> ~s(</select>)

    assert safe_to_string(
             select(:search, :key, [Foo: "foo", Bar: "bar"], prompt: "Choose your destiny")
           ) ==
             ~s(<select id="search_key" name="search[key]">) <>
               ~s(<option value="">Choose your destiny</option>) <>
               ~s(<option value="foo">Foo</option>) <>
               ~s(<option value="bar">Bar</option>) <> ~s(</select>)

    assert safe_to_string(
             select(:search, :key, [Foo: "foo", Bar: "bar"],
               prompt: [key: "Choose your destiny", disabled: true]
             )
           ) ==
             ~s(<select id="search_key" name="search[key]">) <>
               ~s(<option value="" disabled>Choose your destiny</option>) <>
               ~s(<option value="foo">Foo</option>) <>
               ~s(<option value="bar">Bar</option>) <> ~s(</select>)

    assert_raise ArgumentError, fn ->
      select(:search, :key, [Foo: "foo", Bar: "bar"], prompt: [])
    end

    assert safe_to_string(select(:search, :key, ~w(foo bar), value: "foo")) =~
             ~s(<option value="foo" selected>foo</option>)

    assert safe_to_string(select(:search, :key, ~w(foo bar), selected: "foo")) =~
             ~s(<option value="foo" selected>foo</option>)
  end

  test "select/4 with form" do
    assert safe_form(&select(&1, :key, ~w(value novalue), selected: "novalue")) ==
             ~s(<select id="search_key" name="search[key]">) <>
               ~s(<option value="value" selected>value</option>) <>
               ~s(<option value="novalue">novalue</option>) <> ~s(</select>)

    assert safe_form(&select(&1, :other, ~w(value novalue), selected: "novalue")) ==
             ~s(<select id="search_other" name="search[other]">) <>
               ~s(<option value="value">value</option>) <>
               ~s(<option value="novalue" selected>novalue</option>) <> ~s(</select>)

    assert safe_form(
             &select(
               &1,
               :key,
               [
                 [value: "value", key: "Value", disabled: true],
                 [value: "novalue", key: "No Value"]
               ],
               selected: "novalue"
             )
           ) ==
             ~s(<select id="search_key" name="search[key]">) <>
               ~s(<option value="value" disabled selected>Value</option>) <>
               ~s(<option value="novalue">No Value</option>) <> ~s(</select>)

    assert safe_form(
             &select(
               put_in(&1.data[:other], "value"),
               :other,
               ~w(value novalue),
               selected: "novalue"
             )
           ) ==
             ~s(<select id="search_other" name="search[other]">) <>
               ~s(<option value="value">value</option>) <>
               ~s(<option value="novalue" selected>novalue</option>) <> ~s(</select>)

    assert safe_form(&select(&1, :key, ~w(value novalue), value: "novalue")) ==
             ~s(<select id="search_key" name="search[key]">) <>
               ~s(<option value="value">value</option>) <>
               ~s(<option value="novalue" selected>novalue</option>) <> ~s(</select>)
  end

  test "select/4 with groups" do
    assert safe_form(
             &select(&1, :key, [{"foo", ~w(bar baz)}, {"qux", ~w(qux quz)}], value: "qux")
           ) ==
             ~s(<select id="search_key" name="search[key]">) <>
               ~s(<optgroup label="foo">) <>
               ~s(<option value="bar">bar</option>) <>
               ~s(<option value="baz">baz</option>) <>
               ~s(</optgroup>) <>
               ~s(<optgroup label="qux">) <>
               ~s(<option value="qux" selected>qux</option>) <>
               ~s(<option value="quz">quz</option>) <> ~s(</optgroup>) <> ~s(</select>)

    assert safe_form(
             &select(
               &1,
               :key,
               [foo: [{"1", "One"}, {"2", "Two"}], qux: ~w(qux quz)],
               value: "qux"
             )
           ) ==
             ~s(<select id="search_key" name="search[key]">) <>
               ~s(<optgroup label="foo">) <>
               ~s(<option value="One">1</option>) <>
               ~s(<option value="Two">2</option>) <>
               ~s(</optgroup>) <>
               ~s(<optgroup label="qux">) <>
               ~s(<option value="qux" selected>qux</option>) <>
               ~s(<option value="quz">quz</option>) <> ~s(</optgroup>) <> ~s(</select>)

    assert safe_form(
             &select(
               &1,
               :key,
               %{"foo" => %{"1" => "One", "2" => "Two"}, "qux" => ~w(qux quz)},
               value: "qux"
             )
           ) ==
             ~s(<select id="search_key" name="search[key]">) <>
               ~s(<optgroup label="foo">) <>
               ~s(<option value="One">1</option>) <>
               ~s(<option value="Two">2</option>) <>
               ~s(</optgroup>) <>
               ~s(<optgroup label="qux">) <>
               ~s(<option value="qux" selected>qux</option>) <>
               ~s(<option value="quz">quz</option>) <> ~s(</optgroup>) <> ~s(</select>)

    assert safe_form(
             &select(
               &1,
               :key,
               %{"foo" => [{"1", "One"}, {"2", "Two"}], "qux" => ~w(qux quz)},
               value: "qux"
             )
           ) ==
             ~s(<select id="search_key" name="search[key]">) <>
               ~s(<optgroup label="foo">) <>
               ~s(<option value="One">1</option>) <>
               ~s(<option value="Two">2</option>) <>
               ~s(</optgroup>) <>
               ~s(<optgroup label="qux">) <>
               ~s(<option value="qux" selected>qux</option>) <>
               ~s(<option value="quz">quz</option>) <> ~s(</optgroup>) <> ~s(</select>)
  end

  # multiple_select/4

  test "multiple_select/4" do
    assert safe_to_string(multiple_select(:search, :key, ~w(foo bar))) ==
             ~s(<select id="search_key" multiple="" name="search[key][]">) <>
               ~s(<option value="foo">foo</option>) <>
               ~s(<option value="bar">bar</option>) <> ~s(</select>)

    assert safe_to_string(multiple_select(:search, :key, [{"foo", 1}, {"bar", 2}])) ==
             ~s(<select id="search_key" multiple="" name="search[key][]">) <>
               ~s(<option value="1">foo</option>) <>
               ~s(<option value="2">bar</option>) <> ~s(</select>)

    assert safe_to_string(multiple_select(:search, :key, ~w(foo bar), value: ["foo"])) =~
             ~s(<option value="foo" selected>foo</option>)

    assert safe_to_string(
             multiple_select(:search, :key, [{"foo", "1"}, {"bar", "2"}], value: [1])
           ) =~ ~s(<option value="1" selected>foo</option>)

    assert safe_to_string(multiple_select(:search, :key, [{"foo", 1}, {"bar", 2}], selected: [1])) =~
             ~s(<option value="1" selected>foo</option>)

    assert safe_to_string(
             multiple_select(:search, :key, %{"foo" => [{"One", 1}, {"Two", 2}], "bar" => ~w(3 4)})
           ) ==
             ~s(<select id="search_key" multiple="" name="search[key][]">) <>
               ~s(<optgroup label="bar">) <>
               ~s(<option value="3">3</option>) <>
               ~s(<option value="4">4</option>) <>
               ~s(</optgroup>) <>
               ~s(<optgroup label="foo">) <>
               ~s(<option value="1">One</option>) <>
               ~s(<option value="2">Two</option>) <> ~s(</optgroup>) <> ~s(</select>)
  end

  test "multiple_select/4 with form" do
    assert safe_form(
             &multiple_select(&1, :key, [{"foo", 1}, {"bar", 2}], value: [1], selected: [2])
           ) ==
             ~s(<select id="search_key" multiple="" name="search[key][]">) <>
               ~s(<option value="1" selected>foo</option>) <>
               ~s(<option value="2">bar</option>) <> ~s(</select>)

    assert safe_form(&multiple_select(&1, :other, [{"foo", 1}, {"bar", 2}], selected: [2])) ==
             ~s(<select id="search_other" multiple="" name="search[other][]">) <>
               ~s(<option value="1">foo</option>) <>
               ~s(<option value="2" selected>bar</option>) <> ~s(</select>)

    assert safe_form(&multiple_select(&1, :key, [{"foo", 1}, {"bar", 2}], value: [2])) ==
             ~s(<select id="search_key" multiple="" name="search[key][]">) <>
               ~s(<option value="1">foo</option>) <>
               ~s(<option value="2" selected>bar</option>) <> ~s(</select>)

    assert safe_form(&multiple_select(&1, :key, ~w(value novalue), value: ["novalue"])) ==
             ~s(<select id="search_key" multiple="" name="search[key][]">) <>
               ~s(<option value="value">value</option>) <>
               ~s(<option value="novalue" selected>novalue</option>) <> ~s(</select>)

    assert safe_form(
             &multiple_select(
               put_in(&1.params["key"], ["3"]),
               :key,
               [{"foo", 1}, {"bar", 2}, {"goo", 3}],
               selected: [2]
             )
           ) ==
             ~s(<select id="search_key" multiple="" name="search[key][]">) <>
               ~s(<option value="1">foo</option>) <>
               ~s(<option value="2">bar</option>) <>
               ~s(<option value="3" selected>goo</option>) <> ~s(</select>)
  end

  test "multiple_select/4 with unnamed form" do
    assert safe_form(
             &multiple_select(&1, :key, [{"foo", 1}, {"bar", 2}], value: [1], selected: [2]),
             []
           ) ==
             ~s(<select id="key" multiple="" name="key[]">) <>
               ~s(<option value="1" selected>foo</option>) <>
               ~s(<option value="2">bar</option>) <> ~s(</select>)

    assert safe_form(&multiple_select(&1, :other, [{"foo", 1}, {"bar", 2}], selected: [2]), []) ==
             ~s(<select id="other" multiple="" name="other[]">) <>
               ~s(<option value="1">foo</option>) <>
               ~s(<option value="2" selected>bar</option>) <> ~s(</select>)

    assert safe_form(&multiple_select(&1, :key, [{"foo", 1}, {"bar", 2}], value: [2]), []) ==
             ~s(<select id="key" multiple="" name="key[]">) <>
               ~s(<option value="1">foo</option>) <>
               ~s(<option value="2" selected>bar</option>) <> ~s(</select>)

    assert safe_form(&multiple_select(&1, :key, ~w(value novalue), value: ["novalue"]), []) ==
             ~s(<select id="key" multiple="" name="key[]">) <>
               ~s(<option value="value">value</option>) <>
               ~s(<option value="novalue" selected>novalue</option>) <> ~s(</select>)

    assert safe_form(
             &multiple_select(
               put_in(&1.params["key"], ["3"]),
               :key,
               [{"foo", 1}, {"bar", 2}, {"goo", 3}],
               selected: [2]
             ),
             []
           ) ==
             ~s(<select id="key" multiple="" name="key[]">) <>
               ~s(<option value="1">foo</option>) <>
               ~s(<option value="2">bar</option>) <>
               ~s(<option value="3" selected>goo</option>) <> ~s(</select>)
  end

  # options_for_select/2

  test "options_for_select/2" do
    assert options_for_select(~w(value novalue), "novalue") |> safe_to_string() ==
             ~s(<option value="value">value</option>) <>
               ~s(<option value="novalue" selected>novalue</option>)

    assert options_for_select(~w(value novalue), "novalue") |> safe_to_string() ==
             ~s(<option value="value">value</option>) <>
               ~s(<option value="novalue" selected>novalue</option>)

    assert options_for_select(
             [
               [value: "value", key: "Value", disabled: true],
               [value: "novalue", key: "No Value"]
             ],
             "novalue"
           )
           |> safe_to_string() ==
             ~s(<option value="value" disabled>Value</option>) <>
               ~s(<option value="novalue" selected>No Value</option>)

    assert options_for_select(~w(value novalue), ["value", "novalue"]) |> safe_to_string() ==
             ~s(<option value="value" selected>value</option>) <>
               ~s(<option value="novalue" selected>novalue</option>)
  end

  test "options_for_select/2 with groups" do
    assert options_for_select([{"foo", ~w(bar baz)}, {"qux", ~w(qux quz)}], "qux")
           |> safe_to_string() ==
             ~s(<optgroup label="foo">) <>
               ~s(<option value="bar">bar</option>) <>
               ~s(<option value="baz">baz</option>) <>
               ~s(</optgroup>) <>
               ~s(<optgroup label="qux">) <>
               ~s(<option value="qux" selected>qux</option>) <>
               ~s(<option value="quz">quz</option>) <> ~s(</optgroup>)

    assert options_for_select([{"foo", ~w(bar baz)}, {"qux", ~w(qux quz)}], ["baz", "qux"])
           |> safe_to_string() ==
             ~s(<optgroup label="foo">) <>
               ~s(<option value="bar">bar</option>) <>
               ~s(<option value="baz" selected>baz</option>) <>
               ~s(</optgroup>) <>
               ~s(<optgroup label="qux">) <>
               ~s(<option value="qux" selected>qux</option>) <>
               ~s(<option value="quz">quz</option>) <> ~s(</optgroup>)
  end

  # date_select/4

  test "date_select/4" do
    content = safe_to_string(date_select(:search, :datetime))
    assert content =~ ~s(<select id="search_datetime_year" name="search[datetime][year]">)
    assert content =~ ~s(<select id="search_datetime_month" name="search[datetime][month]">)
    assert content =~ ~s(<select id="search_datetime_day" name="search[datetime][day]">)

    content = safe_to_string(date_select(:search, :datetime, value: {2020, 04, 17}))
    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="4" selected>April</option>)
    assert content =~ ~s(<option value="17" selected>17</option>)

    content = safe_to_string(date_select(:search, :datetime, value: "2020-04-17"))
    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="4" selected>April</option>)
    assert content =~ ~s(<option value="17" selected>17</option>)

    content =
      safe_to_string(date_select(:search, :datetime, value: %{year: 2020, month: 04, day: 07}))

    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="4" selected>April</option>)
    assert content =~ ~s(<option value="7" selected>07</option>)

    content =
      safe_to_string(date_select(:search, :datetime, value: %{year: 2020, month: 04, day: 09}))

    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="4" selected>April</option>)
    assert content =~ ~s(<option value="9" selected>09</option>)

    content =
      safe_to_string(
        date_select(
          :search,
          :datetime,
          year: [prompt: "Year"],
          month: [prompt: "Month"],
          day: [prompt: "Day"]
        )
      )

    assert content =~
             ~s(<select id="search_datetime_year" name="search[datetime][year]">) <>
               ~s(<option value="">Year</option>)

    assert content =~
             ~s(<select id="search_datetime_month" name="search[datetime][month]">) <>
               ~s(<option value="">Month</option>)

    assert content =~
             ~s(<select id="search_datetime_day" name="search[datetime][day]">) <>
               ~s(<option value="">Day</option>)
  end

  test "date_select/4 with form" do
    content = safe_form(&date_select(&1, :datetime, default: {2020, 10, 13}))
    assert content =~ ~s(<select id="search_datetime_year" name="search[datetime][year]">)
    assert content =~ ~s(<select id="search_datetime_month" name="search[datetime][month]">)
    assert content =~ ~s(<select id="search_datetime_day" name="search[datetime][day]">)
    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="4" selected>April</option>)
    assert content =~ ~s(<option value="17" selected>17</option>)
    assert content =~ ~s(<option value="1">January</option><option value="2">February</option>)

    content = safe_form(&date_select(&1, :unknown, default: {2020, 9, 9}))
    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="9" selected>September</option>)
    assert content =~ ~s(<option value="9" selected>09</option>)

    content = safe_form(&date_select(&1, :unknown, default: {2020, 10, 13}))
    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="10" selected>October</option>)
    assert content =~ ~s(<option value="13" selected>13</option>)

    content = safe_form(&date_select(&1, :datetime, value: {2020, 10, 13}))
    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="10" selected>October</option>)
    assert content =~ ~s(<option value="13" selected>13</option>)
  end

  # time_select/4

  test "time_select/4" do
    content = safe_to_string(time_select(:search, :datetime))
    assert content =~ ~s(<select id="search_datetime_hour" name="search[datetime][hour]">)
    assert content =~ ~s(<select id="search_datetime_minute" name="search[datetime][minute]">)
    refute content =~ ~s(<select id="search_datetime_second" name="search[datetime][second]">)

    content = safe_to_string(time_select(:search, :datetime, second: []))
    assert content =~ ~s(<select id="search_datetime_hour" name="search[datetime][hour]">)
    assert content =~ ~s(<select id="search_datetime_minute" name="search[datetime][minute]">)
    assert content =~ ~s(<select id="search_datetime_second" name="search[datetime][second]">)

    content = safe_to_string(time_select(:search, :datetime, value: {2, 9, 9}, second: []))
    assert content =~ ~s(<option value="2" selected>02</option>)
    assert content =~ ~s(<option value="9" selected>09</option>)
    assert content =~ ~s(<option value="9" selected>09</option>)

    content = safe_to_string(time_select(:search, :datetime, value: "02:11:13.123Z", second: []))
    assert content =~ ~s(<option value="2" selected>02</option>)
    assert content =~ ~s(<option value="11" selected>11</option>)
    assert content =~ ~s(<option value="13" selected>13</option>)

    content = safe_to_string(time_select(:search, :datetime, value: {2, 11, 13}, second: []))
    assert content =~ ~s(<option value="2" selected>02</option>)
    assert content =~ ~s(<option value="11" selected>11</option>)
    assert content =~ ~s(<option value="13" selected>13</option>)

    content =
      safe_to_string(
        time_select(:search, :datetime, value: %{hour: 2, minute: 11, second: 13}, second: [])
      )

    assert content =~ ~s(<option value="2" selected>02</option>)
    assert content =~ ~s(<option value="11" selected>11</option>)
    assert content =~ ~s(<option value="13" selected>13</option>)

    content =
      safe_to_string(
        time_select(
          :search,
          :datetime,
          hour: [prompt: "Hour"],
          minute: [prompt: "Minute"],
          second: [prompt: "Second"]
        )
      )

    assert content =~
             ~s(<select id="search_datetime_hour" name="search[datetime][hour]">) <>
               ~s(<option value="">Hour</option>)

    assert content =~
             ~s(<select id="search_datetime_minute" name="search[datetime][minute]">) <>
               ~s(<option value="">Minute</option>)

    assert content =~
             ~s(<select id="search_datetime_second" name="search[datetime][second]">) <>
               ~s(<option value="">Second</option>)
  end

  test "time_select/4 with form" do
    content = safe_form(&time_select(&1, :datetime, default: {1, 2, 3}, second: []))
    assert content =~ ~s(<select id="search_datetime_hour" name="search[datetime][hour]">)
    assert content =~ ~s(<select id="search_datetime_minute" name="search[datetime][minute]">)
    assert content =~ ~s(<select id="search_datetime_second" name="search[datetime][second]">)
    assert content =~ ~s(<option value="2" selected>02</option>)
    assert content =~ ~s(<option value="11" selected>11</option>)
    assert content =~ ~s(<option value="13" selected>13</option>)
    assert content =~ ~s(<option value="1">01</option><option value="2">02</option>)

    content = safe_form(&time_select(&1, :unknown, default: {1, 2, 3}, second: []))
    assert content =~ ~s(<option value="1" selected>01</option>)
    assert content =~ ~s(<option value="2" selected>02</option>)
    assert content =~ ~s(<option value="3" selected>03</option>)

    content = safe_form(&time_select(&1, :datetime, value: {1, 2, 3}, second: []))
    assert content =~ ~s(<option value="1" selected>01</option>)
    assert content =~ ~s(<option value="2" selected>02</option>)
    assert content =~ ~s(<option value="3" selected>03</option>)
  end

  # datetime_select/4

  test "datetime_select/4" do
    content = safe_to_string(datetime_select(:search, :datetime))
    assert content =~ ~s(<select id="search_datetime_year" name="search[datetime][year]">)
    assert content =~ ~s(<select id="search_datetime_month" name="search[datetime][month]">)
    assert content =~ ~s(<select id="search_datetime_day" name="search[datetime][day]">)
    assert content =~ ~s(<select id="search_datetime_hour" name="search[datetime][hour]">)
    assert content =~ ~s(<select id="search_datetime_minute" name="search[datetime][minute]">)
    refute content =~ ~s(<select id="search_datetime_second" name="search[datetime][second]">)

    content = safe_to_string(datetime_select(:search, :datetime, second: []))
    assert content =~ ~s(<select id="search_datetime_year" name="search[datetime][year]">)
    assert content =~ ~s(<select id="search_datetime_month" name="search[datetime][month]">)
    assert content =~ ~s(<select id="search_datetime_day" name="search[datetime][day]">)
    assert content =~ ~s(<select id="search_datetime_hour" name="search[datetime][hour]">)
    assert content =~ ~s(<select id="search_datetime_minute" name="search[datetime][minute]">)
    assert content =~ ~s(<select id="search_datetime_second" name="search[datetime][second]">)

    content =
      safe_to_string(
        datetime_select(:search, :datetime, value: {{2020, 9, 9}, {2, 11, 13}}, second: [])
      )

    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="9" selected>September</option>)
    assert content =~ ~s(<option value="9" selected>09</option>)
    assert content =~ ~s(<option value="2" selected>02</option>)
    assert content =~ ~s(<option value="11" selected>11</option>)
    assert content =~ ~s(<option value="13" selected>13</option>)

    content =
      safe_to_string(
        datetime_select(:search, :datetime, value: {{2020, 04, 17}, {2, 11, 13}}, second: [])
      )

    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="4" selected>April</option>)
    assert content =~ ~s(<option value="17" selected>17</option>)
    assert content =~ ~s(<option value="2" selected>02</option>)
    assert content =~ ~s(<option value="11" selected>11</option>)
    assert content =~ ~s(<option value="13" selected>13</option>)
  end

  test "datetime_select/4 with form" do
    content =
      safe_form(&datetime_select(&1, :datetime, default: {{2020, 10, 13}, {1, 2, 3}}, second: []))

    assert content =~ ~s(<select id="search_datetime_year" name="search[datetime][year]">)
    assert content =~ ~s(<select id="search_datetime_month" name="search[datetime][month]">)
    assert content =~ ~s(<select id="search_datetime_day" name="search[datetime][day]">)
    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="4" selected>April</option>)
    assert content =~ ~s(<option value="17" selected>17</option>)

    assert content =~ ~s(<select id="search_datetime_hour" name="search[datetime][hour]">)
    assert content =~ ~s(<select id="search_datetime_minute" name="search[datetime][minute]">)
    assert content =~ ~s(<select id="search_datetime_second" name="search[datetime][second]">)
    assert content =~ ~s(<option value="2" selected>02</option>)
    assert content =~ ~s(<option value="11" selected>11</option>)
    assert content =~ ~s(<option value="13" selected>13</option>)

    content =
      safe_form(&datetime_select(&1, :unknown, default: {{2020, 10, 9}, {1, 2, 3}}, second: []))

    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="10" selected>October</option>)
    assert content =~ ~s(<option value="9" selected>09</option>)
    assert content =~ ~s(<option value="1" selected>01</option>)
    assert content =~ ~s(<option value="2" selected>02</option>)
    assert content =~ ~s(<option value="3" selected>03</option>)

    content =
      safe_form(&datetime_select(&1, :unknown, default: {{2020, 10, 13}, {1, 2, 3}}, second: []))

    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="10" selected>October</option>)
    assert content =~ ~s(<option value="13" selected>13</option>)
    assert content =~ ~s(<option value="1" selected>01</option>)
    assert content =~ ~s(<option value="2" selected>02</option>)
    assert content =~ ~s(<option value="3" selected>03</option>)

    content =
      safe_form(&datetime_select(&1, :datetime, value: {{2020, 10, 13}, {1, 2, 3}}, second: []))

    assert content =~ ~s(<option value="2020" selected>2020</option>)
    assert content =~ ~s(<option value="10" selected>October</option>)
    assert content =~ ~s(<option value="13" selected>13</option>)
    assert content =~ ~s(<option value="1" selected>01</option>)
    assert content =~ ~s(<option value="2" selected>02</option>)
    assert content =~ ~s(<option value="3" selected>03</option>)
  end

  test "datetime_select/4 with builder" do
    builder = fn b ->
      html_escape([
        "Year: ",
        b.(:year, class: "year"),
        "Month: ",
        b.(:month, class: "month"),
        "Day: ",
        b.(:day, class: "day"),
        "Hour: ",
        b.(:hour, class: "hour"),
        "Min: ",
        b.(:minute, class: "min"),
        "Sec: ",
        b.(:second, class: "sec")
      ])
    end

    content =
      safe_to_string(
        datetime_select(
          :search,
          :datetime,
          builder: builder,
          year: [id: "year"],
          month: [id: "month"],
          day: [id: "day"],
          hour: [id: "hour"],
          minute: [id: "min"],
          second: [id: "sec"]
        )
      )

    assert content =~ ~s(Year: <select class="year" id="year" name="search[datetime][year]">)
    assert content =~ ~s(Month: <select class="month" id="month" name="search[datetime][month]">)
    assert content =~ ~s(Day: <select class="day" id="day" name="search[datetime][day]">)
    assert content =~ ~s(Hour: <select class="hour" id="hour" name="search[datetime][hour]">)
    assert content =~ ~s(Min: <select class="min" id="min" name="search[datetime][minute]">)
    assert content =~ ~s(Sec: <select class="sec" id="sec" name="search[datetime][second]">)
  end

  describe "label" do
    test "with block" do
      assert safe_to_string(
               label do
                 "Block"
               end
             ) == ~s(<label>Block</label>)

      assert safe_to_string(
               label class: "foo" do
                 "Block"
               end
             ) == ~s(<label class="foo">Block</label>)
    end

    test "with field but no content" do
      assert safe_to_string(label(:search, :key)) == ~s(<label for="search_key">Key</label>)

      assert safe_to_string(label(:search, :key, for: "test_key")) ==
               ~s(<label for="test_key">Key</label>)

      assert safe_to_string(label(:search, :key, for: "test_key", class: "foo")) ==
               ~s(<label class="foo" for="test_key">Key</label>)
    end

    test "with field and inline content" do
      assert safe_to_string(label(:search, :key, "Search")) ==
               ~s(<label for="search_key">Search</label>)

      assert safe_to_string(label(:search, :key, "Search", for: "test_key")) ==
               ~s(<label for="test_key">Search</label>)

      assert safe_form(&label(&1, :key, "Search")) == ~s(<label for="search_key">Search</label>)

      assert safe_form(&label(&1, :key, "Search", for: "test_key")) ==
               ~s(<label for="test_key">Search</label>)

      assert safe_form(&label(&1, :key, "Search", for: "test_key", class: "foo")) ==
               ~s(<label class="foo" for="test_key">Search</label>)
    end

    test "with field and inline safe content" do
      assert safe_to_string(label(:search, :key, {:safe, "<em>Search</em>"})) ==
               ~s(<label for="search_key"><em>Search</em></label>)
    end

    test "with field and block content" do
      assert safe_form(&label(&1, :key, do: "Hello")) == ~s(<label for="search_key">Hello</label>)

      assert safe_form(&label(&1, :key, [class: "test-label"], do: "Hello")) ==
               ~s(<label class="test-label" for="search_key">Hello</label>)
    end

    test "with atom or binary field" do
      assert safe_form(&label(&1, :key, do: "Hello")) ==
               ~s(<label for="search_key">Hello</label>)

      assert safe_form(&label(&1, "key", do: "Hello")) ==
               ~s(<label for="search_key">Hello</label>)
    end
  end

  ## input_value/2

  test "input_value/2 without form" do
    assert input_value(:search, :key) == nil
    assert input_value(:search, 1) == nil
    assert input_value(:search, "key") == nil
  end

  test "input_value/2 with form" do
    assert safe_form(&input_value(&1, :key)) == "value"
    assert safe_form(&input_value(&1, "key")) == "value"
  end

  test "input_value/2 with form and data" do
    assert safe_form(&input_value(put_in(&1.data[:key], "original"), :key)) == "value"
    assert safe_form(&input_value(put_in(&1.data[:no_key], "original"), :no_key)) == "original"

    safe_form(fn f ->
      assert input_value(put_in(f.data[:alt_key], "original"), :alt_key) == nil
      ""
    end)

    assert safe_form(&input_value(put_in(&1.data["key"], "original"), "key")) == "value"
    assert safe_form(&input_value(put_in(&1.data["no_key"], "original"), "no_key")) == "original"

    safe_form(fn f ->
      assert input_value(put_in(f.data["alt_key"], "original"), "alt_key") == nil
      ""
    end)
  end

  ## input_id/2

  test "input_id/2 without form" do
    assert input_id(:search, :key) == "search_key"
    assert input_id(:search, "key") == "search_key"
  end

  test "input_id/2 with form" do
    assert safe_form(&input_id(&1, :key)) == "search_key"
    assert safe_form(&input_id(&1, "key")) == "search_key"
  end

  test "input_id/2 with form with no name" do
    assert safe_form(&input_id(&1, :key), []) == "key"
  end

  ## input_id/3

  test "input_id/3" do
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

  test "input_id/3 with form with no name" do
    assert safe_form(&input_id(&1, :key, :value), []) == "key_value"
  end

  ## input_name/2

  test "input_name/2 without form" do
    assert input_name(:search, :key) == "search[key]"
    assert input_name(:search, "key") == "search[key]"
  end

  test "input_name/2 with form" do
    assert safe_form(&input_name(&1, :key)) == "search[key]"
    assert safe_form(&input_name(&1, "key")) == "search[key]"
  end
end
