defmodule Phoenix.HTMLTest do
  use ExUnit.Case, async: true

  use Phoenix.HTML
  doctest Phoenix.HTML

  alias Phoenix.HTML.Safe

  test "html_escape/1 entities" do
    assert html_escape("foo") == {:safe, "foo"}
    assert html_escape("<foo>") == {:safe, "&lt;foo&gt;"}
    assert html_escape("\" & \'") == {:safe, "&quot; &amp; &#39;"}
  end

  test "Phoenix.HTML.Safe for binaries" do
    assert Safe.to_iodata("<foo>") == "&lt;foo&gt;"
  end

  test "Phoenix.HTML.Safe for io data" do
    assert Safe.to_iodata('<foo>') == ["&lt;", 102, 111, 111, "&gt;"]
    assert Safe.to_iodata(['<foo>']) == [["&lt;", 102, 111, 111, "&gt;"]]
    assert Safe.to_iodata([?<, "foo" | ?>]) == ["&lt;", "foo" | "&gt;"]
  end

  test "Phoenix.HTML.Safe for atoms" do
    assert Safe.to_iodata(:'<foo>') == "&lt;foo&gt;"
  end

  test "Phoenix.HTML.Safe for safe data" do
    assert Safe.to_iodata(1) == "1"
    assert Safe.to_iodata(1.0) == "1.0"
    assert Safe.to_iodata({:safe, "<foo>"}) == "<foo>"
  end

  test "Phoenix.HTML.escape_javascript/1" do
    assert escape_javascript({:safe, ""}) == ""
    assert escape_javascript({:safe, "\\Double backslash"}) == "\\\\Double backslash"
    assert escape_javascript({:safe, "</closing tag>"}) == "<\/closing tag>"
    assert escape_javascript({:safe, "Windows line break \r\n"}) == "Windows line break \n"
    assert escape_javascript({:safe, "Carriage return \r"}) == "Carriage return \n"
    assert escape_javascript({:safe, "\"Double quote\""}) == "\\\"Double quote\\\""
    assert escape_javascript({:safe, "'Single quote'"}) == "\\'Single quote\\'"
  end
end
