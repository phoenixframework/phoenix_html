defmodule Phoenix.HTML.TagTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML
  import Phoenix.HTML.Tag, except: [attributes_escape: 1]
  doctest Phoenix.HTML.Tag

  test "img_tag" do
    assert img_tag("user.png") |> safe_to_string() == ~s(<img src="user.png">)

    assert img_tag("user.png", class: "big") |> safe_to_string() ==
             ~s(<img class="big" src="user.png">)

    assert img_tag("user.png", srcset: %{"big.png" => "2x", "small.png" => "1x"})
           |> safe_to_string() ==
             ~s(<img src="user.png" srcset="big.png 2x, small.png 1x">)

    assert img_tag("user.png", srcset: [{"big.png", "2x"}, "small.png"]) |> safe_to_string() ==
             ~s(<img src="user.png" srcset="big.png 2x, small.png">)

    assert img_tag("user.png", srcset: "big.png 2x, small.png") |> safe_to_string() ==
             ~s[<img src="user.png" srcset="big.png 2x, small.png">]
  end

  test "form_tag for get" do
    assert safe_to_string(form_tag("/", method: :get)) ==
             ~s(<form action="/" method="get">)

    assert safe_to_string(form_tag("/", method: :get)) ==
             ~s(<form action="/" method="get">)
  end

  test "form_tag for post" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(form_tag("/")) ==
             ~s(<form action="/" method="post">) <>
               ~s(<input name="_csrf_token" type="hidden" value="#{csrf_token}">)

    assert safe_to_string(form_tag("/", method: :post, csrf_token: false, multipart: true)) ==
             ~s(<form action="/" enctype="multipart/form-data" method="post">)
  end

  test "form_tag for other method" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(form_tag("/", method: :put)) ==
             ~s(<form action="/" method="post">) <>
               ~s(<input name="_method" type="hidden" value="put">) <>
               ~s(<input name="_csrf_token" type="hidden" value="#{csrf_token}">)
  end

  test "form_tag with do block" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(
             form_tag "/" do
               "<>"
             end
           ) ==
             ~s(<form action="/" method="post">) <>
               ~s(<input name="_csrf_token" type="hidden" value="#{csrf_token}">) <>
               ~s(&lt;&gt;) <> ~s(</form>)

    assert safe_to_string(
             form_tag "/", method: :get do
               "<>"
             end
           ) ==
             ~s(<form action="/" method="get">) <>
               ~s(&lt;&gt;) <> ~s(</form>)
  end

  test "csrf_meta_tag" do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    assert safe_to_string(csrf_meta_tag()) ==
             ~s(<meta content="#{csrf_token}" name="csrf-token">)

    assert safe_to_string(csrf_meta_tag(foo: "bar")) ==
             ~s(<meta content="#{csrf_token}" foo="bar" name="csrf-token">)
  end

  test "csrf_input_tag" do
    url = "/example"
    csrf_token = Plug.CSRFProtection.get_csrf_token_for(url)

    assert safe_to_string(csrf_input_tag(url)) ==
             ~s(<input name="_csrf_token" type="hidden" value="#{csrf_token}">)

    assert safe_to_string(csrf_input_tag(url, foo: "bar")) ==
             ~s(<input foo="bar" name="_csrf_token" type="hidden" value="#{csrf_token}">)
  end

  describe "csrf_token_value" do
    def custom_csrf(to, extra), do: "#{extra}:#{to}"

    test "with default" do
      assert csrf_token_value("/") == Plug.CSRFProtection.get_csrf_token()
    end

    test "with configured MFA" do
      default_reader = Application.fetch_env!(:phoenix_html, :csrf_token_reader)

      try do
        Application.put_env(
          :phoenix_html,
          :csrf_token_reader,
          {__MODULE__, :custom_csrf, ["extra"]}
        )

        assert csrf_token_value("/foo") == "extra:/foo"
      after
        Application.put_env(:phoenix_html, :csrf_token_reader, default_reader)
      end
    end
  end
end
