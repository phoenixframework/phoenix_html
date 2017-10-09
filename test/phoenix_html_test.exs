defmodule Phoenix.HTMLTest do
  use ExUnit.Case, async: true

  use Phoenix.HTML
  doctest Phoenix.HTML

  test "html_escape/1 entities" do
    assert html_escape("foo") == {:safe, "foo"}
    assert html_escape("<foo>") == {:safe, "&lt;foo&gt;"}
    assert html_escape("\" & \'") == {:safe, "&quot; &amp; &#39;"}
  end

  test "escape_javascript/1" do
    assert escape_javascript("") == ""
    assert escape_javascript("\\Double backslash") == "\\\\Double backslash"
    assert escape_javascript("\"Double quote\"") == "\\\"Double quote\\\""
    assert escape_javascript("'Single quote'") == "\\'Single quote\\'"
    assert escape_javascript("New line\r") == "New line\\n"
    assert escape_javascript("New line\n") == "New line\\n"
    assert escape_javascript("New line\r\n") == "New line\\n"
    assert escape_javascript("</close>") == "<\\/close>"
    assert escape_javascript(<<0x2028::utf8>>) == "&#x2028;"
    assert escape_javascript(<<0x2029::utf8>>) == "&#x2029;"
    assert escape_javascript({:safe, "'Single quote'"}) == {:safe, "\\'Single quote\\'"}
    assert escape_javascript({:safe, ["'Single quote'"]}) == {:safe, "\\'Single quote\\'"}
    assert escape_javascript({:safe, 'ünicode'}) == {:safe, "ünicode"}
  end

  test "safe_to_string/1" do
    assert safe_to_string({:safe, 'ünicode'}) == "ünicode"
  end

  test "only accepts valid iodata" do
    assert Phoenix.HTML.Safe.to_iodata("foo") == "foo"
    assert Phoenix.HTML.Safe.to_iodata('foo') == 'foo'
    assert_raise ArgumentError, ~r/templates only support iodata/, fn ->
      Phoenix.HTML.Safe.to_iodata('foo🐥')
    end
  end
end
