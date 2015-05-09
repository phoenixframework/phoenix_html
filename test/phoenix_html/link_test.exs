defmodule Phoenix.HTML.LinkTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML
  import Phoenix.HTML.Link

  test "link with post" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(link("hello", to: "/world", method: :post)) ==
           ~s[<form action="/world" class="link" method="post">] <>
           ~s[<input name="_csrf_token" type="hidden" value="#{csrf_token}">] <>
           ~s[<a href="#" onclick="this.parentNode.submit(); return false;">hello</a>] <>
           ~s[</form>]
  end

  test "link with put/delete" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(link("hello", to: "/world", method: :put, form: [class: "linkmethod"])) ==
           ~s[<form action="/world" class="linkmethod" method="post">] <>
           ~s[<input name="_method" type="hidden" value="put">] <>
           ~s[<input name="_csrf_token" type="hidden" value="#{csrf_token}">] <>
           ~s[<a href="#" onclick="this.parentNode.submit(); return false;">hello</a>] <>
           ~s[</form>]
  end

  test "button with post (default)" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(button("hello", to: "/world")) ==
           ~s[<form action="/world" class="button" method="post">] <>
           ~s[<input name="_csrf_token" type="hidden" value="#{csrf_token}">] <>
           ~s[<input type="submit" value="hello">] <>
           ~s[</form>]
  end

  test "button with get does not generate CSRF" do
    assert safe_to_string(button("hello", to: "/world", method: :get)) ==
           ~s[<form action="/world" class="button" method="get">] <>
           ~s[<input type="submit" value="hello">] <>
           ~s[</form>]
  end

  test "button with class overrides default" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(button("hello", to: "/world", form: [class: "btn rounded"], id: "btn")) ==
           ~s[<form action="/world" class="btn rounded" method="post">] <>
           ~s[<input name="_csrf_token" type="hidden" value="#{csrf_token}">] <>
           ~s[<input id="btn" type="submit" value="hello">] <>
           ~s[</form>]
  end
end
