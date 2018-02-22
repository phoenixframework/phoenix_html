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
  @spec to_form(t, Keyword.t()) :: Phoenix.HTML.Form.t()
  def to_form(data, options)

  @doc """
  Converts the field in the given form based on the data structure
  into a `Phoenix.HTML.Form` struct.

  The options are the same options given to `inputs_for/4`. It
  can be used by implementations to configure their behaviour
  and it must be stored in the underlying struct, with any
  custom field removed.
  """
  @spec to_form(t, Phoenix.HTML.Form.t(), Phoenix.HTML.Form.field(), Keyword.t()) ::
          Phoenix.HTML.Form.t()
  def to_form(data, form, field, options)

  @doc """
  Returns the value for the given field.
  """
  @spec input_value(t, Phoenix.HTML.Form.t(), Phoenix.HTML.Form.field()) :: term
  def input_value(data, form, field)

  @doc """
  Returns the HTML5 validations that would apply to
  the given field.
  """
  @spec input_validations(t, Phoenix.HTML.Form.t(), Phoenix.HTML.Form.field()) :: Keyword.t()
  def input_validations(data, form, field)

  @doc """
  Receives the given field and returns its input type (:text_input,
  :select, etc). Returns `nil` if the type is unknown.
  """
  @spec input_type(t, Phoenix.HTML.Form.t(), Phoenix.HTML.Form.field()) :: atom | nil
  def input_type(data, form, field)
end

defimpl Phoenix.HTML.FormData, for: Plug.Conn do
  def to_form(conn, opts) do
    {name, params, opts} =
      case Keyword.pop(opts, :as) do
        {nil, opts} ->
          {nil, conn.params, opts}

        {name, opts} ->
          name = to_string(name)
          {name, Map.get(conn.params, name) || %{}, opts}
      end

    %Phoenix.HTML.Form{
      source: conn,
      impl: __MODULE__,
      id: name,
      name: name,
      params: params,
      options: opts,
      data: %{}
    }
  end

  def to_form(conn, form, field, opts) when is_atom(field) or is_binary(field) do
    {default, opts} = Keyword.pop(opts, :default, %{})
    {prepend, opts} = Keyword.pop(opts, :prepend, [])
    {append, opts} = Keyword.pop(opts, :append, [])
    {name, opts} = Keyword.pop(opts, :as)
    {id, opts} = Keyword.pop(opts, :id)

    id = to_string(id || form.id <> "_#{field}")
    name = to_string(name || form.name <> "[#{field}]")
    params = Map.get(form.params, field_to_string(field))

    cond do
      # cardinality: one
      is_map(default) ->
        [
          %Phoenix.HTML.Form{
            source: conn,
            impl: __MODULE__,
            id: id,
            name: name,
            data: default,
            params: params || %{},
            options: opts
          }
        ]

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

        for {{data, params}, index} <- Enum.with_index(entries) do
          index_string = Integer.to_string(index)

          %Phoenix.HTML.Form{
            source: conn,
            impl: __MODULE__,
            index: index,
            id: id <> "_" <> index_string,
            name: name <> "[" <> index_string <> "]",
            data: data,
            params: params,
            options: opts
          }
        end
    end
  end

  def input_value(_conn, %{data: data, params: params}, field)
      when is_atom(field) or is_binary(field) do
    case Map.fetch(params, field_to_string(field)) do
      {:ok, value} ->
        value

      :error ->
        Map.get(data, field)
    end
  end

  def input_type(_conn, _form, _field), do: :text_input
  def input_validations(_conn, _form, _field), do: []

  # Normalize field name to string version
  defp field_to_string(field) when is_atom(field), do: Atom.to_string(field)
  defp field_to_string(field) when is_binary(field), do: field
end
