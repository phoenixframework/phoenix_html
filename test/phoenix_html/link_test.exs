defmodule Phoenix.HTML.LinkTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML
  import Phoenix.HTML.Link

  test "link with post" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(link("hello", to: "/world", method: :post)) ==
           ~s[<form action="/world" class="link" method="post">] <>
           ~s[<input name="_csrf_token" type="hidden" value="#{csrf_token}">] <>
           ~s[<a data-submit="parent" href="#" rel="nofollow">hello</a>] <>
           ~s[</form>]
  end

  test "link with put/delete" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(link("hello", to: "/world", method: :put, form: [class: "linkmethod"])) ==
           ~s[<form action="/world" class="linkmethod" method="post">] <>
           ~s[<input name="_method" type="hidden" value="put">] <>
           ~s[<input name="_csrf_token" type="hidden" value="#{csrf_token}">] <>
           ~s[<a data-submit="parent" href="#" rel="nofollow">hello</a>] <>
           ~s[</form>]
  end

  test "link with post remote" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(link("hello", to: "/world", method: :post, remote: true)) ==
           ~s[<form action="/world" class="link" data-remote="true" method="post">] <>
           ~s[<input name="_csrf_token" type="hidden" value="#{csrf_token}">] <>
           ~s[<input to="/world" type="submit" value="hello">] <>
           ~s[</form>]
  end

  test "link with :do contents" do
    assert ~s[<a href="/hello"><p>world</p></a>] == safe_to_string(link to: "/hello" do
      Phoenix.HTML.Tag.content_tag :p, "world"
    end)

    assert safe_to_string(link(to: "/hello", do: "world")) == ~s[<a href="/hello">world</a>]
  end

  test "link remote" do
    assert safe_to_string(link "world", to: "/hello", remote: true) ==
           ~s[<a data-remote="true" href="/hello">world</a>]
  end

  test "link with invalid args" do
    msg = "expected non-nil value for :to in link/2, got: nil"
    assert_raise ArgumentError, msg, fn ->
      link("foo", [bar: "baz"])
    end

    msg = "link/2 requires a keyword list as second argument"
    assert_raise ArgumentError, msg, fn ->
      link("foo", "/login")
    end

    msg = "link/2 requires a text as first argument or contents in the :do block"
    assert_raise ArgumentError, msg, fn ->
      link(to: "/hello-world")
    end
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
