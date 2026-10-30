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
      assert html_escape(~c"foo") == {:safe, ~c"foo"}

      assert_raise ArgumentError, ~r/templates only support iodata/, fn ->
        html_escape(~c"foo🐥")
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

      assert attributes_escape([{:data, [a: false, b: true, c: nil]}]) |> safe_to_string() ==
               ~s( data-b)

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

    test "handle class value list with nested lists" do
      assert attributes_escape([{:class, ["btn", nil, false, ["<active>", "small"]]}])
             |> safe_to_string() ==
               ~s( class="btn &lt;active&gt; small")

      assert attributes_escape([{:class, ["btn", nil, [false, ["<active>", "small"]]]}])
             |> safe_to_string() ==
               ~s( class="btn &lt;active&gt; small")
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

    test "raises on invalid binary attribute name" do
      for invalid <- [
            "",
            "foo\"bar",
            "foo'bar",
            "foo>bar",
            "foo/bar",
            "foo=bar",
            "foo bar",
            "foo\tbar",
            "foo\nbar",
            "foo\fbar",
            "foo\rbar",
            "foo\0bar",
            "foo\x7Fbar"
          ] do
        assert_raise ArgumentError, ~r/expected attribute name/, fn ->
          attributes_escape([{invalid, "value"}])
        end
      end
    end

    test "raises on invalid binary nested attribute name" do
      assert_raise ArgumentError, ~r/expected attribute name/, fn ->
        attributes_escape([{"data", [{"a=b", "1"}]}])
      end
    end

    test "handle atom attribute name without validation" do
      assert attributes_escape([{:"foo bar", "baz"}]) |> safe_to_string() == ~s( foo bar="baz")
      assert attributes_escape([{:"foo bar", true}]) |> safe_to_string() == ~s( foo bar)

      assert attributes_escape(data: [{:"a b", "1"}]) |> safe_to_string() ==
               ~s( data-a b="1")
    end

    test "raises on invalid attribute name in map" do
      assert_raise ArgumentError, ~r/expected attribute name/, fn ->
        attributes_escape(%{"x onmouseover" => "alert(1)"})
      end
    end

    test "raises on invalid attribute name with true value" do
      assert_raise ArgumentError, ~r/expected attribute name/, fn ->
        attributes_escape([{"x onmouseover=alert(1)", true}])
      end

      assert_raise ArgumentError, ~r/expected attribute name/, fn ->
        attributes_escape([{"x onmouseover=alert(1)", true}])
      end

      assert_raise ArgumentError, ~r/expected attribute name/, fn ->
        attributes_escape(phx: [{"x onclick=alert(1)", true}])
      end
    end

    test "raises on invalid attribute name in deeply nested attributes" do
      assert_raise ArgumentError, ~r/expected attribute name/, fn ->
        attributes_escape(data: [{"a b", [{:c, "d"}]}])
      end

      assert_raise ArgumentError, ~r/expected attribute name/, fn ->
        attributes_escape(data: [{:a, [{"c d", "e"}]}])
      end
    end

    test "handle non-ascii attribute name" do
      assert attributes_escape(%{"données" => "y"}) |> safe_to_string() == ~s( données="y")
    end

    test "raises on invalid iodata attribute name" do
      for invalid <- [[], ~c"foo bar", ["foo bar"], ["foo", " ", "bar"]] do
        assert_raise ArgumentError, ~r/expected attribute name/, fn ->
          attributes_escape([{invalid, "value"}])
        end
      end
    end

    test "handle iodata attribute name" do
      assert attributes_escape([{["foo", "-", "bar"], "v"}]) |> safe_to_string() ==
               ~s( foo-bar="v")

      assert attributes_escape([{~c"a&b", "v"}]) |> safe_to_string() == ~s( a&amp;b="v")
    end

    test "handle safe attribute name without validation" do
      assert attributes_escape([{{:safe, "foo"}, "bar"}]) |> safe_to_string() == ~s( foo="bar")
      assert attributes_escape([{{:safe, "foo"}, true}]) |> safe_to_string() == ~s( foo)

      assert attributes_escape(data: [{{:safe, "foo"}, "bar"}]) |> safe_to_string() ==
               ~s( data-foo="bar")
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
