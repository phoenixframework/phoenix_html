defmodule Phoenix.HTML.TagTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML
  import Phoenix.HTML.Tag
  doctest Phoenix.HTML.Tag

  test "tag" do
    assert tag(:br) |> safe_to_string() ==
           ~s(<br>)

    assert tag(:input, name: ~s("<3")) |> safe_to_string() ==
           ~s(<input name="&quot;&lt;3&quot;">)

    assert tag(:input, name: raw "<3") |> safe_to_string() ==
           ~s(<input name="<3">)

    assert tag(:input, name: :hello) |> safe_to_string() ==
           ~s(<input name="hello">)

    assert tag(:input, type: "text", name: "user_id") |> safe_to_string() ==
           ~s(<input name="user_id" type="text">)

    assert tag(:input, data: [toggle: "dropdown"]) |> safe_to_string() ==
           ~s(<input data-toggle="dropdown">)

    assert tag(:input, my_attr: "blah") |> safe_to_string() ==
           ~s(<input my-attr="blah">)

    assert tag(:input, data: [my_attr: "blah"]) |> safe_to_string() ==
           ~s(<input data-my-attr="blah">)

    assert tag(:input, data: [toggle: [target: "#parent", attr: "blah"]]) |> safe_to_string() ==
           ~s(<input data-toggle-attr="blah" data-toggle-target="#parent">)

    assert tag(:audio, autoplay: true) |> safe_to_string() ==
           ~s(<audio autoplay="autoplay">)

    assert tag(:audio, autoplay: false) |> safe_to_string() ==
           ~s(<audio>)

    assert tag(:audio, autoplay: nil) |> safe_to_string() ==
           ~s(<audio>)
  end

  test "content_tag" do
    assert content_tag(:p, "Hello") |> safe_to_string() ==
           "<p>Hello</p>"

    assert content_tag(:p, "Hello", class: "dark") |> safe_to_string() ==
           "<p class=\"dark\">Hello</p>"

    assert content_tag(:p, [class: "dark"], do: "Hello") |> safe_to_string() ==
           "<p class=\"dark\">Hello</p>"

    assert content_tag(:p, "<Hello>") |> safe_to_string() ==
           "<p>&lt;Hello&gt;</p>"

    assert content_tag(:p, 13) |> safe_to_string() ==
           "<p>13</p>"

    assert content_tag(:p, [class: "dark"], do: "<Hello>") |> safe_to_string() ==
           "<p class=\"dark\">&lt;Hello&gt;</p>"

    assert content_tag(:p, raw "<Hello>") |> safe_to_string() ==
           "<p><Hello></p>"

    assert content_tag(:p, [class: "dark"], do: raw "<Hello>") |> safe_to_string() ==
           "<p class=\"dark\"><Hello></p>"

    content = content_tag(:form, [action: "/users", data: [remote: true]]) do
      tag(:input, name: "user[name]")
    end

    assert safe_to_string(content) ==
           ~s(<form action="/users" data-remote="true">) <>
           ~s(<input name="user[name]"></form>)

    assert content_tag(:p, do: "Hello") |> safe_to_string() ==
            "<p>Hello</p>"

    content = content_tag :ul do
      content_tag :li do
        "Hello"
      end
    end
    assert safe_to_string(content) ==
           "<ul><li>Hello</li></ul>"

    assert content_tag(:p, ["hello", ?\s, "world"]) |> safe_to_string() ==
           "<p>hello world</p>"
  end

  test "form_tag for get" do
    assert safe_to_string(form_tag("/", method: :get)) ==
           ~s(<form accept-charset="UTF-8" action="/" method="get">) <>
           ~s(<input name="_utf8" type="hidden" value="✓">)

    assert safe_to_string(form_tag("/", method: :get, enforce_utf8: false)) ==
           ~s(<form action="/" method="get">)
  end

  test "form_tag for post" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(form_tag("/")) ==
           ~s(<form accept-charset="UTF-8" action="/" method="post">) <>
           ~s(<input name="_csrf_token" type="hidden" value="#{csrf_token}">) <>
           ~s(<input name="_utf8" type="hidden" value="✓">)

    assert safe_to_string(form_tag("/", method: :post, csrf_token: false, multipart: true)) ==
           ~s(<form accept-charset="UTF-8" action="/" enctype="multipart/form-data" method="post">) <>
           ~s(<input name="_utf8" type="hidden" value="✓">)
  end

  test "form_tag for other method" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(form_tag("/", method: :put)) ==
           ~s(<form accept-charset="UTF-8" action="/" method="post">) <>
           ~s(<input name="_method" type="hidden" value="put">) <>
           ~s(<input name="_csrf_token" type="hidden" value="#{csrf_token}">) <>
           ~s(<input name="_utf8" type="hidden" value="✓">)
  end

  test "form_tag with do block" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(form_tag("/") do "<>" end) ==
           ~s(<form accept-charset="UTF-8" action="/" method="post">) <>
           ~s(<input name="_csrf_token" type="hidden" value="#{csrf_token}">) <>
           ~s(<input name="_utf8" type="hidden" value="✓">) <>
           ~s(&lt;&gt;) <>
           ~s(</form>)

    assert safe_to_string(form_tag("/", method: :get) do "<>" end) ==
           ~s(<form accept-charset="UTF-8" action="/" method="get">) <>
           ~s(<input name="_utf8" type="hidden" value="✓">) <>
           ~s(&lt;&gt;) <>
           ~s(</form>)
  end

  test "csrf_meta_tag" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(csrf_meta_tag) ==
           ~s(<meta charset="UTF-8" content="#{csrf_token}" csrf-param="_csrf_token" method-param="_method" name="csrf-token">)
  end
end
