defmodule Phoenix.HTML.EngineTest do
  use ExUnit.Case, async: true

  test "evaluates expressions with buffers" do
    string = """
    <%= 123 %>
    <% if true do %>
      <%= 456 %>
    <% end %>
    <%= 789 %>
    """

    assert eval(string) == "123\n\n789\n"
  end

  defp eval(string) do
    {:safe, io} =
      EEx.eval_string(string, [], file: __ENV__.file, engine: Phoenix.HTML.Engine)
    IO.iodata_to_binary(io)
  end
end
