defmodule Phoenix.HTML.TagTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML
  import Phoenix.HTML.Tag, except: [attributes_escape: 1]
  doctest Phoenix.HTML.Tag

  test "tag" do
    assert tag(:br) |> safe_to_string() == ~s(<br>)

    assert tag(:input, name: ~s("<3")) |> safe_to_string() == ~s(<input name="&quot;&lt;3&quot;">)
    assert tag(:input, name: raw("<3")) |> safe_to_string() == ~s(<input name="<3">)
    assert tag(:input, name: ["foo", raw("b<r")]) |> safe_to_string() == ~s(<input name="foob<r">)
    assert tag(:input, name: :hello) |> safe_to_string() == ~s(<input name="hello">)

    assert tag(:input, type: "text", name: "user_id") |> safe_to_string() ==
             ~s(<input name="user_id" type="text">)

    assert tag(:input, data: [toggle: "dropdown"]) |> safe_to_string() ==
             ~s(<input data-toggle="dropdown">)

    assert tag(:input, my_attr: "blah") |> safe_to_string() == ~s(<input my-attr="blah">)

    assert tag(:input, [{"my_<_attr", "blah"}]) |> safe_to_string() ==
             ~s(<input my_&lt;_attr="blah">)

    assert tag(:input, [{{:safe, "my_<_attr"}, "blah"}]) |> safe_to_string() ==
             ~s(<input my_<_attr="blah">)

    assert tag(:input, data: [my_attr: "blah"]) |> safe_to_string() ==
             ~s(<input data-my-attr="blah">)

    assert tag(:input, data: [toggle: [attr: "blah", target: "#parent"]]) |> safe_to_string() ==
             ~s(<input data-toggle-attr="blah" data-toggle-target="#parent">)

    assert tag(:audio, autoplay: "autoplay") |> safe_to_string() ==
             ~s(<audio autoplay="autoplay">)

    assert tag(:audio, autoplay: true) |> safe_to_string() == ~s(<audio autoplay>)
    assert tag(:audio, autoplay: false) |> safe_to_string() == ~s(<audio>)
    assert tag(:audio, autoplay: nil) |> safe_to_string() == ~s(<audio>)
  end

  test "content_tag" do
    assert content_tag(:p, "Hello") |> safe_to_string() == "<p>Hello</p>"

    assert content_tag(:p, "Hello", class: "dark") |> safe_to_string() ==
             "<p class=\"dark\">Hello</p>"

    assert content_tag(:p, [class: "dark"], do: "Hello") |> safe_to_string() ==
             "<p class=\"dark\">Hello</p>"

    assert content_tag(:p, "<Hello>") |> safe_to_string() == "<p>&lt;Hello&gt;</p>"

    assert content_tag(:p, 13) |> safe_to_string() == "<p>13</p>"

    assert content_tag(:p, [class: "dark"], do: "<Hello>") |> safe_to_string() ==
             "<p class=\"dark\">&lt;Hello&gt;</p>"

    assert content_tag(:p, raw("<Hello>")) |> safe_to_string() == "<p><Hello></p>"

    assert content_tag(:p, [class: "dark"], do: raw("<Hello>")) |> safe_to_string() ==
             "<p class=\"dark\"><Hello></p>"

    content =
      content_tag :form, action: "/users", data: [remote: true] do
        tag(:input, name: "user[name]")
      end

    assert safe_to_string(content) ==
             ~s(<form action="/users" data-remote="true">) <> ~s(<input name="user[name]"></form>)

    assert content_tag(:p, do: "Hello") |> safe_to_string() == "<p>Hello</p>"

    content =
      content_tag :ul do
        content_tag :li do
          "Hello"
        end
      end

    assert safe_to_string(content) == "<ul><li>Hello</li></ul>"

    assert content_tag(:p, ["hello", ?\s, "world"]) |> safe_to_string() == "<p>hello world</p>"

    assert content_tag(:div, [autoplay: "autoplay"], do: "") |> safe_to_string() ==
             ~s(<div autoplay="autoplay"></div>)

    assert content_tag(:div, [autoplay: true], do: "") |> safe_to_string() ==
             ~s(<div autoplay></div>)

    assert content_tag(:div, [autoplay: false], do: "") |> safe_to_string() == ~s(<div></div>)

    assert content_tag(:div, [autoplay: nil], do: "") |> safe_to_string() == ~s(<div></div>)

    assert content_tag("custom-tag", "Hi") |> safe_to_string() == ~s(<custom-tag>Hi</custom-tag>)
  end

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
end
