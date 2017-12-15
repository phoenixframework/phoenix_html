defmodule Phoenix.HTML.Engine do
  @moduledoc """
  This is an implementation of EEx.Engine that guarantees
  templates are HTML Safe.
  """

  @anno (if :erlang.system_info(:otp_release) >= '19' do
    [generated: true]
  else
    [line: -1]
  end)

  use EEx.Engine

  # There is a fair amount of compatibility work going on in this module.
  # There are 3 versions of EEx.Engine that this module is compatibile with
  # 1. pre Elixir 1.3 that always passed empty string as the accumulator to
  #    handle_text and handle_expr - this is reflected in extra clauses
  #    that coerce this to the 2. format described below.
  # 2. pre Elixir 1.5 where accumulator had to be valid AST at all times.
  #    In that case we keep a safe tuple as the accumulator.
  # 3. After 1.5.1 Elixir introduced handle_begin and handle_end that effectively
  #    allow the accumulator to be any data converted to AST in handle_end.
  #    We leverage this by optimizing the building of iodata to a flat list
  #    and concatenating neighbouring literals, if that's the case.

  @doc false
  if function_exported?(EEx.Engine, :handle_begin, 1) do
    def init(opts), do: handle_begin(opts)
  else
    def init(_opts), do: {:safe, ""}
  end

  @doc false
  def handle_begin(_previous), do: {[], [], 0}

  @doc false
  def handle_end({exprs, values, _acc}) do
    quote do
      unquote_splicing(Enum.reverse(exprs))
      {:safe, unquote(combine_strings(values, []))}
    end
  end

  defp combine_strings([str1, str2 | rest], acc) when is_binary(str1) and is_binary(str2) do
    combine_strings([str2 <> str1 | rest], acc)
  end
  defp combine_strings([elem | rest], acc) do
    combine_strings(rest, [elem | acc])
  end
  defp combine_strings([], [elem]) do
    elem
  end
  defp combine_strings([], acc) do
    acc
  end

  @doc false
  if function_exported?(EEx.Engine, :handle_end, 1) do
    def handle_body(acc), do: handle_end(acc)
  else
    def handle_body(acc), do: acc
  end

  @doc false
  def handle_text("", text) do
    handle_text({:safe, ""}, text)
  end

  def handle_text({:safe, buffer}, text) do
    quote do
      {:safe, [unquote(buffer)|unquote(text)]}
    end
  end

  def handle_text({exprs, values, acc}, text) do
    {exprs, [text | values], acc}
  end

  @doc false
  def handle_expr("", marker, expr) do
    handle_expr({:safe, ""}, marker, expr)
  end

  def handle_expr({:safe, buffer}, "=", expr) do
    {:safe, quote do
      tmp1 = unquote(buffer)
      [tmp1|unquote(to_safe(expr(expr)))]
     end}
  end

  def handle_expr({:safe, buffer}, "", expr) do
    {:safe, quote do
      tmp2 = unquote(buffer)
      unquote(expr(expr))
      tmp2
    end}
  end

  def handle_expr({exprs, values, acc}, "", expr) do
    {[expr(expr) | exprs], values, acc}
  end

  def handle_expr({exprs, values, acc}, "=", expr) do
    case to_safe(expr(expr)) do
      str when is_binary(str) ->
        {exprs, [str | values], acc}
      expr ->
        var = Macro.var(:"tmp#{acc}", __MODULE__)
        expr = quote(do: unquote(var) = unquote(expr))
        {[expr | exprs], [var | values], acc + 1}
    end
  end

  defp line_from_expr({_, meta, _}) when is_list(meta), do: Keyword.get(meta, :line)
  defp line_from_expr(_), do: nil

  # We can do the work at compile time
  defp to_safe(literal) when is_binary(literal) or is_atom(literal) or is_number(literal) do
    Phoenix.HTML.Safe.to_iodata(literal)
  end

  # We can do the work at runtime
  defp to_safe(literal) when is_list(literal) do
    quote line: nil, do: Phoenix.HTML.Safe.to_iodata(unquote(literal))
  end

  # We need to check at runtime and we do so by
  # optimizing common cases.
  defp to_safe(expr) do
    line = line_from_expr(expr)
    # Keep stacktraces for protocol dispatch...
    fallback = quote line: line, do: Phoenix.HTML.Safe.to_iodata(other)

    # However ignore them for the generated clauses to avoid warnings
    quote @anno do
      case unquote(expr) do
        {:safe, data} -> data
        bin when is_binary(bin) -> Plug.HTML.html_escape_to_iodata(bin)
        other -> unquote(fallback)
      end
    end
  end

  defp expr(expr) do
    Macro.prewalk(expr, &handle_assign/1)
  end

  defp handle_assign({:@, meta, [{name, _, atom}]}) when is_atom(name) and is_atom(atom) do
    quote line: meta[:line] || 0 do
      Phoenix.HTML.Engine.fetch_assign(var!(assigns), unquote(name))
    end
  end
  defp handle_assign(arg), do: arg

  @doc false
  def fetch_assign(assigns, key) do
    case Access.fetch(assigns, key) do
      {:ok, val} ->
        val
      :error ->
        raise ArgumentError, message: """
        assign @#{key} not available in eex template.

        Please make sure all proper assigns have been set. If this
        is a child template, ensure assigns are given explicitly by
        the parent template as they are not automatically forwarded.

        Available assigns: #{inspect Enum.map(assigns, &elem(&1, 0))}
        """
    end
  end
end
