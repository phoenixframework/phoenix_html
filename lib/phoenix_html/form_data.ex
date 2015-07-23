defprotocol Phoenix.HTML.FormData do
  @moduledoc """
  Converts a data structure into a `Phoenix.HTML.Form` struct.
  """

  @doc """
  Converts a data structure into a `Phoenix.HTML.Form` struct.

  The options are the same options given to `form_for/4`. It
  can be used by implementations to configure their behaviour
  and it must be stored in the underlying struct, with any
  custom field removed.
  """
  def to_form(data, options)

  @doc """
  Converts the field in the given form based on the data structure
  into a `Phoenix.HTML.Form` struct.

  The options are the same options given to `inputs_for/4`. It
  can be used by implementations to configure their behaviour
  and it must be stored in the underlying struct, with any
  custom field removed.
  """
  def to_form(data, form, field, options)
end

defimpl Phoenix.HTML.FormData, for: Plug.Conn do
  def to_form(conn, opts) do
    {name, opts} = Keyword.pop(opts, :name)
    name = to_string(name || no_name_error!)

    %Phoenix.HTML.Form{
      source: conn,
      id: name,
      name: name,
      params: Map.get(conn.params, name) || %{},
      options: opts
    }
  end

  def to_form(conn, form, field, opts) do
    {default, opts} = Keyword.pop(opts, :default, %{})
    {prepend, opts} = Keyword.pop(opts, :prepend, [])
    {append, opts}  = Keyword.pop(opts, :append, [])
    {name, opts}    = Keyword.pop(opts, :name)
    {id, opts}      = Keyword.pop(opts, :id)

    id     = to_string(id || form.id <> "_#{field}")
    name   = to_string(name || form.name <> "[#{field}]")
    params = Map.get(form.params, Atom.to_string(field))

    cond do
      # cardinality: one
      is_map(default) ->
        [%Phoenix.HTML.Form{
          source: conn,
          id: id,
          name: name,
          model: default,
          params: params || %{},
          options: opts}]

      # cardinality: many
      is_list(default) ->
        prepend = Enum.map(prepend, &{&1, %{}})
        append  = Enum.map(append, &{&1, %{}})

        middle =
          if params do
            params
            |> Enum.sort_by(&elem(&1, 0))
            |> Enum.map(&{nil, elem(&1, 1)})
          else
            Enum.map(default, &{&1, %{}})
          end

        for {{model, params}, index} <- Enum.with_index(prepend ++ middle ++ append) do
          index = Integer.to_string(index)
          %Phoenix.HTML.Form{
            source: conn,
            id: id <> "_" <> index,
            name: name <> "[" <> index <> "]",
            model: model,
            params: params,
            options: opts}
        end
    end
  end

  defp no_name_error! do
    raise ArgumentError, "form_for/4 expects [name: NAME] to be given as option " <>
                         "when used with @conn"
  end
end
