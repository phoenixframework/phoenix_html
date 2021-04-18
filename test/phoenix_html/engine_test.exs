defmodule Phoenix.HTML.EngineTest do
  use ExUnit.Case, async: true

  def safe(do: {:safe, _} = safe), do: safe
  def unsafe(do: {:safe, content}), do: content

  test "encode_to_iodata!" do
    assert Phoenix.HTML.Engine.encode_to_iodata!("<foo>") == [[[] | "&lt;"], "foo" | "&gt;"]
    assert Phoenix.HTML.Engine.encode_to_iodata!({:safe, "<foo>"}) == "<foo>"
    assert Phoenix.HTML.Engine.encode_to_iodata!(123) == "123"
  end

  test "escapes HTML" do
    template = """
    <start> <%= "<escaped>" %>
    """

    assert eval(template) == "<start> &lt;escaped&gt;\n"
  end

  test "escapes HTML from nested content" do
    template = """
    <%= Phoenix.HTML.EngineTest.unsafe do %>
      <foo>
    <% end %>
    """

    assert eval(template) == "\n  &lt;foo&gt;\n\n"
  end

  test "does not escape safe expressions" do
    assert eval("Safe <%= {:safe, \"<value>\"} %>") == "Safe <value>"
  end

  test "nested content is always safe" do
    template = """
    <%= Phoenix.HTML.EngineTest.safe do %>
      <foo>
    <% end %>
    """

    assert eval(template) == "\n  <foo>\n\n"

    template = """
    <%= Phoenix.HTML.EngineTest.safe do %>
      <%= "<foo>" %>
    <% end %>
    """

    assert eval(template) == "\n  &lt;foo&gt;\n\n"
  end

  test "handles assigns" do
    assert eval("<%= @foo %>", %{foo: "<hello>"}) == "&lt;hello&gt;"
  end

  test "supports non-output expressions" do
    template = """
    <% foo = @foo %>
    <%= foo %>
    """

    assert eval(template, %{foo: "<hello>"}) == "\n&lt;hello&gt;\n"
  end

  test "raises ArgumentError for missing assigns" do
    assert_raise ArgumentError,
                 ~r/assign @foo not available in template.*Available assigns: \[:bar\]/s,
                 fn -> eval("<%= @foo %>", %{bar: true}) end
  end

  defp eval(string, assigns \\ %{}) do
    {:safe, io} =
      EEx.eval_string(string, [assigns: assigns], file: __ENV__.file, engine: Phoenix.HTML.Engine)

    IO.iodata_to_binary(io)
  end
end
