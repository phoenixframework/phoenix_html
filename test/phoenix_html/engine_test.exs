defmodule Phoenix.HTML.EngineTest do
  use ExUnit.Case, async: true

  @template """
  <%= 123 %>
  <%= if @foo do %>
    <%= 456 %>
  <% end %>
  <%= 789 %>
  """

  test "evaluates expressions with buffers" do
    assert eval(@template, %{foo: true}) == "123\n\n  456\n\n789\n"
  end

  test "evaluates safe expressions" do
    assert eval("Safe <%= {:safe, \"value\"} %>", %{}) == "Safe value"
  end

  test "raises ArgumentError for missing assigns" do
    assert_raise ArgumentError, ~r/assign @foo not available in eex template.*Available assigns: \[:bar\]/s, fn ->
      eval(@template, %{bar: "baz"})
    end
  end

  test "evaluates expressions in the right order" do
    assert eval("<% a = 1 %><% a = 2 %><%= a %>", %{}) == "2"
  end

  defp eval(string, assigns) do
    {:safe, io} =
      EEx.eval_string(string, [assigns: assigns],
                      file: __ENV__.file, engine: Phoenix.HTML.Engine)
    IO.iodata_to_binary(io)
  end
end
