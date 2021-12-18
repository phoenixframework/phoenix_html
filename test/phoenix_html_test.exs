defmodule Phoenix.HTMLTest do
  use ExUnit.Case, async: true

  use Phoenix.HTML
  doctest Phoenix.HTML

  test "~E sigil" do
    assert ~E"""
           <%= %>
           """ == {:safe, ["", "\n"]}

    assert ~E"""
           <%= "foo" %>
           """ == {:safe, ["foo", "\n"]}

    assert ~E"""
           <%= {:safe, "foo"} %>
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
end
