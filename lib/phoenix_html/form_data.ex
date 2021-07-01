defprotocol Phoenix.HTML.FormData do
  @moduledoc """
  Converts a data structure into a [`Phoenix.HTML.Form`](`t:Phoenix.HTML.Form.t/0`) struct.
  """

  @doc """
  Converts a data structure into a [`Phoenix.HTML.Form`](`t:Phoenix.HTML.Form.t/0`) struct.

  The options are the same options given to `form_for/4`. It
  can be used by implementations to configure their behaviour
  and it must be stored in the underlying struct, with any
  custom field removed.
  """
  @spec to_form(t, Keyword.t()) :: Phoenix.HTML.Form.t()
  def to_form(data, options)

  @doc """
  Converts the field in the given form based on the data structure
  into a list of [`Phoenix.HTML.Form`](`t:Phoenix.HTML.Form.t/0`) structs.

  The options are the same options given to `inputs_for/4`. It
  can be used by implementations to configure their behaviour
  and it must be stored in the underlying struct, with any
  custom field removed.
  """
  @spec to_form(t, Phoenix.HTML.Form.t(), Phoenix.HTML.Form.field(), Keyword.t()) ::
          [Phoenix.HTML.Form.t()]
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

defimpl Phoenix.HTML.FormData, for: [Plug.Conn, Atom] do
  def to_form(conn_or_atom, opts) do
    {name, params, opts} = name_params_and_opts(conn_or_atom, opts)
    {errors, opts} = Keyword.pop(opts, :errors, [])
    id = Keyword.get(opts, :id) || name

    unless is_binary(id) or is_nil(id) do
      raise ArgumentError, ":id option in form_for must be a binary/string, got: #{inspect(id)}"
    end

    %Phoenix.HTML.Form{
      source: conn_or_atom,
      impl: __MODULE__,
      id: id,
      name: name,
      params: params,
      data: %{},
      errors: errors,
      options: opts
    }
  end

  case @for do
    Atom ->
      defp name_params_and_opts(atom, opts) do
        {params, opts} = Keyword.pop(opts, :params, %{})
        {Atom.to_string(atom), params, opts}
      end

    Plug.Conn ->
      defp name_params_and_opts(conn, opts) do
        case Keyword.pop(opts, :as) do
          {nil, opts} ->
            {nil, conn.params, opts}

          {name, opts} ->
            name = to_string(name)
            {name, Map.get(conn.params, name) || %{}, opts}
        end
      end
  end

  def to_form(conn_or_atom, form, field, opts) when is_atom(field) or is_binary(field) do
    {default, opts} = Keyword.pop(opts, :default, %{})
    {prepend, opts} = Keyword.pop(opts, :prepend, [])
    {append, opts} = Keyword.pop(opts, :append, [])
    {name, opts} = Keyword.pop(opts, :as)
    {id, opts} = Keyword.pop(opts, :id)
    {hidden, opts} = Keyword.pop(opts, :hidden, [])

    id = to_string(id || form.id <> "_#{field}")
    name = to_string(name || form.name <> "[#{field}]")
    params = Map.get(form.params, field_to_string(field))

    cond do
      # cardinality: one
      is_map(default) ->
        [
          %Phoenix.HTML.Form{
            source: conn_or_atom,
            impl: __MODULE__,
            id: id,
            name: name,
            data: default,
            params: params || %{},
            hidden: hidden,
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
            source: conn_or_atom,
            impl: __MODULE__,
            index: index,
            id: id <> "_" <> index_string,
            name: name <> "[" <> index_string <> "]",
            data: data,
            params: params,
            hidden: hidden,
            options: opts
          }
        end
    end
  end

  def input_value(_conn_or_atom, %{data: data, params: params}, field)
      when is_atom(field) or is_binary(field) do
    key = field_to_string(field)

    case params do
      %{^key => value} -> value
      %{} -> Map.get(data, field)
    end
  end

  def input_type(_conn_or_atom, _form, _field), do: :text_input
  def input_validations(_conn_or_atom, _form, _field), do: []

  # Normalize field name to string version
  defp field_to_string(field) when is_atom(field), do: Atom.to_string(field)
  defp field_to_string(field) when is_binary(field), do: field
end
