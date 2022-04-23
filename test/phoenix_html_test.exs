defmodule Phoenix.HTMLTest do
  use ExUnit.Case, async: true

  use Phoenix.HTML
  doctest Phoenix.HTML

  test "~E sigil" do
    assert ~E"""
           <%= "foo" %>
           """ == {:safe, ["foo", "\n"]}
  end

  test "javascript_escape/1" do
    assert javascript_escape("") == ""
    assert javascript_escape("\\Double backslash") == "\\\\Double backslash"
    assert javascript_escape("\"Double quote\"") == "\\\"Double quote\\\""
    assert javascript_escape("'Single quote'") == "\\'Single quote\\'"
    assert javascript_escape("`Backtick`") == "\\`Backtick\\`"
    assert javascript_escape("New line\r") == "New line\\n"
    assert javascript_escape("New line\n") == "New line\\n"
    assert javascript_escape("New line\r\n") == "New line\\n"
    assert javascript_escape("</close>") == "<\\/close>"
    assert javascript_escape("Line separator\u2028") == "Line separator\\u2028"
    assert javascript_escape("Paragraph separator\u2029") == "Paragraph separator\\u2029"
    assert javascript_escape("Null character\u0000") == "Null character\\u0000"
    assert javascript_escape({:safe, "'Single quote'"}) == {:safe, "\\'Single quote\\'"}
    assert javascript_escape({:safe, ["'Single quote'"]}) == {:safe, "\\'Single quote\\'"}
  end

  describe "html_escape" do
    test "escapes entities" do
      assert html_escape("foo") == {:safe, "foo"}
      assert html_escape("<foo>") == {:safe, [[[] | "&lt;"], "foo" | "&gt;"]}
      assert html_escape("\" & \'") == {:safe, [[[[] | "&quot;"], " " | "&amp;"], " " | "&#39;"]}
    end

    test "only accepts valid iodata" do
      assert html_escape("foo") == {:safe, "foo"}
      assert html_escape('foo') == {:safe, 'foo'}

      assert_raise ArgumentError, ~r/templates only support iodata/, fn ->
        html_escape('foo🐥')
      end
    end
  end

  describe "attributes_escape" do
    test "key as atom" do
      assert attributes_escape([{:title, "the title"}]) |> safe_to_string() ==
               ~s( title="the title")
    end

    test "key as string" do
      assert attributes_escape([{"title", "the title"}]) |> safe_to_string() ==
               ~s( title="the title")
    end

    test "convert snake_case keys into kebab-case when key is atom" do
      assert attributes_escape([{:my_attr, "value"}]) |> safe_to_string() == ~s( my-attr="value")
    end

    test "keep snake_case keys when key is string" do
      assert attributes_escape([{"my_attr", "value"}]) |> safe_to_string() == ~s( my_attr="value")
    end

    test "multiple attributes" do
      assert attributes_escape([{:title, "the title"}, {:id, "the id"}]) |> safe_to_string() ==
               ~s( title="the title" id="the id")
    end

    test "handle nested data" do
      assert attributes_escape([{"data", [{"a", "1"}, {"b", "2"}]}]) |> safe_to_string() ==
               ~s( data-a="1" data-b="2")

      assert attributes_escape([{:data, [a: "1", b: "2"]}]) |> safe_to_string() ==
               ~s( data-a="1" data-b="2")

      assert attributes_escape([{"aria", [{"a", "1"}, {"b", "2"}]}]) |> safe_to_string() ==
               ~s( aria-a="1" aria-b="2")

      assert attributes_escape([{:aria, [a: "1", b: "2"]}]) |> safe_to_string() ==
               ~s( aria-a="1" aria-b="2")

      assert attributes_escape([{:phx, [click: "save", value: [user_id: 1, foo: :bar]]}])
             |> safe_to_string() ==
               ~s( phx-click="save" phx-value-user-id="1" phx-value-foo="bar")

      assert attributes_escape([
               {"phx", [{"click", "save"}, {"value", [{"user_id", 1}, {"foo", "bar"}]}]}
             ])
             |> safe_to_string() ==
               ~s( phx-click="save" phx-value-user_id="1" phx-value-foo="bar")
    end

    test "handle class value as string" do
      assert attributes_escape([{:class, "btn"}]) |> safe_to_string() == ~s( class="btn")

      assert attributes_escape([{:class, "<active>"}]) |> safe_to_string() ==
               ~s( class="&lt;active&gt;")
    end

    test "handle class value as list" do
      assert attributes_escape([{:class, ["btn", nil, false, "<active>"]}]) |> safe_to_string() ==
               ~s( class="btn &lt;active&gt;")
    end

    test "handle class value as false/nil/true" do
      assert attributes_escape([{:class, false}]) |> safe_to_string() == ~s()
      assert attributes_escape([{:class, nil}]) |> safe_to_string() == ~s()
      assert attributes_escape([{:class, true}]) |> safe_to_string() == ~s( class)
    end

    test "handle class key as string" do
      assert attributes_escape([{"class", "btn"}]) |> safe_to_string() == ~s( class="btn")
    end

    test "raises on number id" do
      assert_raise ArgumentError, ~r/attempting to set id attribute to 3/, fn ->
        attributes_escape([{"id", 3}])
      end
    end

    test "suppress attribute when value is falsy" do
      assert attributes_escape([{"title", nil}]) |> safe_to_string() == ~s()
      assert attributes_escape([{"title", false}]) |> safe_to_string() == ~s()
    end

    test "suppress value when value is true" do
      assert attributes_escape([{"selected", true}]) |> safe_to_string() == ~s( selected)
    end
  end

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
end
