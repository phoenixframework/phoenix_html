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
  end
end
