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
  @spec to_form(t, Keyword.t) :: Phoenix.HTML.Form.t
  def to_form(data, options)

  @doc """
  Converts the field in the given form based on the data structure
  into a `Phoenix.HTML.Form` struct.

  The options are the same options given to `inputs_for/4`. It
  can be used by implementations to configure their behaviour
  and it must be stored in the underlying struct, with any
  custom field removed.
  """
  @spec to_form(t, Phoenix.HTML.Form.t, atom, Keyword.t) :: Phoenix.HTML.Form.t
  def to_form(data, form, field, options)

  @doc """
  Returns the HTML5 validations that would apply to
  the given field.
  """
  @spec input_validations(t, atom) :: Keyword.t
  def input_validations(data, field)

  @doc """
  Receives the given field and returns its input type (:text_input,
  :select, etc). Returns `nil` if the type is unknown.
  """
  @spec input_type(t, atom) :: atom | nil
  def input_type(data, field)
end

defimpl Phoenix.HTML.FormData, for: Plug.Conn do
  def to_form(conn, opts) do
    {name, opts} = Keyword.pop(opts, :as)
    name = to_string(name || warn_name(opts) || no_name_error!)

    %Phoenix.HTML.Form{
      source: conn,
      impl: __MODULE__,
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
    {name, opts}    = Keyword.pop(opts, :as)
    {id, opts}      = Keyword.pop(opts, :id)

    id     = to_string(id || form.id <> "_#{field}")
    name   = to_string(name || warn_name(opts) || form.name <> "[#{field}]")
    params = Map.get(form.params, Atom.to_string(field))

    cond do
      # cardinality: one
      is_map(default) ->
        [%Phoenix.HTML.Form{
          source: conn,
          impl: __MODULE__,
          id: id,
          name: name,
          model: default,
          params: params || %{},
          options: opts}]

      # cardinality: many
      is_list(default) ->
        entries =
          if params do
            params
            |> Enum.sort_by(&elem(&1, 0))
            |> Enum.map(&{nil, elem(&1, 1)})
          else
            Enum.map(prepend ++ default ++ append, &{&1, %{}})
          end

        for {{model, params}, index} <- Enum.with_index(entries) do
          index_string = Integer.to_string(index)
          %Phoenix.HTML.Form{
            source: conn,
            impl: __MODULE__,
            index: index,
            id: id <> "_" <> index_string,
            name: name <> "[" <> index_string <> "]",
            model: model,
            params: params,
            options: opts}
        end
    end
  end

  def input_type(_data, _field), do: :text_input
  def input_validations(_data, _field), do: []

  defp no_name_error! do
    raise ArgumentError, "form_for/4 expects [as: NAME] to be given as option " <>
                         "when used with @conn"
  end

  defp warn_name(opts) do
    if name = Keyword.get(opts, :name) do
      IO.write :stderr, "the :name option in form_for/inputs_for is deprecated, " <>
                        "please use :as instead\n" <> Exception.format_stacktrace()
      name
    end
  end
end
