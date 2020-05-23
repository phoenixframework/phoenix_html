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

  test "html_escape/1 entities" do
    assert html_escape("foo") == {:safe, "foo"}
    assert html_escape("<foo>") == {:safe, [[[] | "&lt;"], "foo" | "&gt;"]}
    assert html_escape("\" & \'") == {:safe, [[[[] | "&quot;"], " " | "&amp;"], " " | "&#39;"]}
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

  test "only accepts valid iodata" do
    assert Phoenix.HTML.Safe.to_iodata("foo") == "foo"
    assert Phoenix.HTML.Safe.to_iodata('foo') == 'foo'

    assert_raise ArgumentError, ~r/templates only support iodata/, fn ->
      Phoenix.HTML.Safe.to_iodata('foo🐥')
    end
  end
end
