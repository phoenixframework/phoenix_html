defmodule Phoenix.HTML.SafeTest do
  use ExUnit.Case, async: true

  alias Phoenix.HTML.Safe

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

  test "Phoenix.HTML.Safe given an invalid tuple" do
    assert_raise Protocol.UndefinedError, fn ->
      Safe.to_iodata({"needs %{count}", [count: 123]})
    end
  end
end
