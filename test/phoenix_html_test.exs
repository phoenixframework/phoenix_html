defmodule Phoenix.HTMLTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML
  doctest Phoenix.HTML

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

    test "equivalences" do
      # Since some HTML code may compare html_escape("") with html_escape(nil),
      # we make sure they have equivalent representations.
      assert html_escape("") == html_escape(nil)
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

    test "suppress attribute when value is falsy" do
      assert attributes_escape([{"title", nil}]) |> safe_to_string() == ~s()
      assert attributes_escape([{"title", false}]) |> safe_to_string() == ~s()
    end

    test "suppress value when value is true" do
      assert attributes_escape([{"selected", true}]) |> safe_to_string() == ~s( selected)
    end
  end

  describe "css_escape" do
    test "null character" do
      assert css_escape(<<0>>) == <<0xFFFD::utf8>>
      assert css_escape("a\u0000") == "a\ufffd"
      assert css_escape("\u0000b") == "\ufffdb"
      assert css_escape("a\u0000b") == "a\ufffdb"
    end

    test "replacement character" do
      assert css_escape(<<0xFFFD::utf8>>) == <<0xFFFD::utf8>>
      assert css_escape("a\ufffd") == "a\ufffd"
      assert css_escape("\ufffdb") == "\ufffdb"
      assert css_escape("a\ufffdb") == "a\ufffdb"
    end

    test "invalid input" do
      assert_raise FunctionClauseError, fn -> css_escape(nil) end
    end

    test "control characters" do
      assert css_escape(<<0x01, 0x02, 0x1E, 0x1F>>) == "\\1 \\2 \\1E \\1F "
    end

    test "leading digit" do
      for {digit, expected} <- Enum.zip(0..9, ~w(30 31 32 33 34 35 36 37 38 39)) do
        assert css_escape("#{digit}a") == "\\#{expected} a"
      end
    end

    test "non-leading digit" do
      for digit <- 0..9 do
        assert css_escape("a#{digit}b") == "a#{digit}b"
      end
    end

    test "leading hyphen and digit" do
      for {digit, expected} <- Enum.zip(0..9, ~w(30 31 32 33 34 35 36 37 38 39)) do
        assert css_escape("-#{digit}a") == "-\\#{expected} a"
      end
    end

    test "hyphens" do
      assert css_escape("-") == "\\-"
      assert css_escape("-a") == "-a"
      assert css_escape("--") == "--"
      assert css_escape("--a") == "--a"
    end

    test "non-ASCII and special characters" do
      assert css_escape("🤷🏻‍♂️-_©") == "🤷🏻‍♂️-_©"

      assert css_escape(
               <<0x7F,
                 "\u0080\u0081\u0082\u0083\u0084\u0085\u0086\u0087\u0088\u0089\u008a\u008b\u008c\u008d\u008e\u008f\u0090\u0091\u0092\u0093\u0094\u0095\u0096\u0097\u0098\u0099\u009a\u009b\u009c\u009d\u009e\u009f">>
             ) ==
               "\\7F \u0080\u0081\u0082\u0083\u0084\u0085\u0086\u0087\u0088\u0089\u008a\u008b\u008c\u008d\u008e\u008f\u0090\u0091\u0092\u0093\u0094\u0095\u0096\u0097\u0098\u0099\u009a\u009b\u009c\u009d\u009e\u009f"

      assert css_escape("\u00a0\u00a1\u00a2") == "\u00a0\u00a1\u00a2"
    end

    test "alphanumeric characters" do
      assert css_escape("a0123456789b") == "a0123456789b"
      assert css_escape("abcdefghijklmnopqrstuvwxyz") == "abcdefghijklmnopqrstuvwxyz"
      assert css_escape("ABCDEFGHIJKLMNOPQRSTUVWXYZ") == "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    end

    test "space and exclamation mark" do
      assert css_escape(<<0x20, 0x21, 0x78, 0x79>>) == "\\ \\!xy"
    end

    test "Unicode characters" do
      # astral symbol (U+1D306 TETRAGRAM FOR CENTRE)
      assert css_escape(<<0x1D306::utf8>>) == <<0x1D306::utf8>>
    end
  end
end
