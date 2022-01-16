defmodule Phoenix.HTML do
  @moduledoc """
  Helpers for working with HTML strings and templates.

  When used, it imports the given modules:

    * `Phoenix.HTML` - functions to handle HTML safety;

    * `Phoenix.HTML.Tag` - functions for generating HTML tags;

    * `Phoenix.HTML.Form` - functions for working with forms;

    * `Phoenix.HTML.Link` - functions for generating links and urls;

    * `Phoenix.HTML.Format` - functions for formatting text;

  ## HTML Safe

  One of the main responsibilities of this module is to
  provide convenience functions for escaping and marking
  HTML code as safe.

  By default, data output in templates is not considered
  safe:

      <%= "<hello>" %>

  will be shown as:

      &lt;hello&gt;

  User data or data coming from the database is almost never
  considered safe. However, in some cases, you may want to tag
  it as safe and show its "raw" contents:

      <%= raw "<hello>" %>

  Keep in mind most helpers will automatically escape your data
  and return safe content:

      <%= content_tag :p, "<hello>" %>

  will properly output:

      <p>&lt;hello&gt;</p>

  ## JavaScript library

  This project ships with a tiny bit of JavaScript that listens
  to all click events to:

    * Support `data-confirm="message"` attributes, which shows
      a confirmation modal with the given message

    * Support `data-method="patch|post|put|delete"` attributes,
      which sends the current click as a PATCH/POST/PUT/DELETE
      HTTP request. You will need to add `data-to` with the URL
      and `data-csrf` with the CSRF token value. See `link_attributes/2`

    * Dispatch a "phoenix.link.click" event. You can listen to this
      event to customize the behaviour above. Returning false from
      this event will disable `data-method`. Stopping propagation
      will disable `data-confirm`

  To use the functionality above, you must load `priv/static/phoenix_html.js`
  into your build tool.

  ### Overriding the default confirm behaviour

  You can override the default confirmation behaviour by hooking
  into `phoenix.link.click`. Here is an example:

  ```javascript
  // listen on document.body, so it's executed before the default of
  // phoenix_html, which is listening on the window object
  document.body.addEventListener('phoenix.link.click', function (e) {
    // Prevent default implementation
    e.stopPropagation();

    // Introduce alternative implementation
    var message = e.target.getAttribute("data-confirm");
    if(!message){ return true; }
    vex.dialog.confirm({
      message: message,
      callback: function (value) {
        if (value == false) { e.preventDefault(); }
      }
    })
  }, false);
  ```

  """

  @doc false
  defmacro __using__(_) do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form
      import Phoenix.HTML.Link
      import Phoenix.HTML.Tag, except: [attributes_escape: 1]
      import Phoenix.HTML.Format
    end
  end

  @typedoc "Guaranteed to be safe"
  @type safe :: {:safe, iodata}

  @typedoc "May be safe or unsafe (i.e. it needs to be converted)"
  @type unsafe :: Phoenix.HTML.Safe.t()

  @doc false
  @deprecated "use the ~H sigil instead"
  defmacro sigil_e(expr, opts) do
    handle_sigil(expr, opts, __CALLER__)
  end

  @doc false
  @deprecated "use the ~H sigil instead"
  defmacro sigil_E(expr, opts) do
    handle_sigil(expr, opts, __CALLER__)
  end

  defp handle_sigil({:<<>>, meta, [expr]}, [], caller) do
    options = [
      engine: Phoenix.HTML.Engine,
      file: caller.file,
      line: caller.line + 1,
      indentation: meta[:indentation] || 0
    ]

    EEx.compile_string(expr, options)
  end

  defp handle_sigil(_, _, _) do
    raise ArgumentError,
          "interpolation not allowed in ~e sigil. " <>
            "Remove the interpolation, use <%= %> to insert values, " <>
            "or use ~E to show the interpolation literally"
  end

  @doc """
  Marks the given content as raw.

  This means any HTML code inside the given
  string won't be escaped.

      iex> raw("<hello>")
      {:safe, "<hello>"}
      iex> raw({:safe, "<hello>"})
      {:safe, "<hello>"}
      iex> raw(nil)
      {:safe, ""}

  """
  @spec raw(iodata | safe | nil) :: safe
  def raw({:safe, value}), do: {:safe, value}
  def raw(nil), do: {:safe, ""}
  def raw(value) when is_binary(value) or is_list(value), do: {:safe, value}

  @doc """
  Escapes the HTML entities in the given term, returning safe iodata.

      iex> html_escape("<hello>")
      {:safe, [[[] | "&lt;"], "hello" | "&gt;"]}

      iex> html_escape('<hello>')
      {:safe, ["&lt;", 104, 101, 108, 108, 111, "&gt;"]}

      iex> html_escape(1)
      {:safe, "1"}

      iex> html_escape({:safe, "<hello>"})
      {:safe, "<hello>"}

  """
  @spec html_escape(unsafe) :: safe
  def html_escape({:safe, _} = safe), do: safe
  def html_escape(other), do: {:safe, Phoenix.HTML.Engine.encode_to_iodata!(other)}

  @doc """
  Converts a safe result into a string.

  Fails if the result is not safe. In such cases, you can
  invoke `html_escape/1` or `raw/1` accordingly before.

  You can combine `html_escape/1` and `safe_to_string/1`
  to convert a data structure to a escaped string:

      data |> html_escape() |> safe_to_string()
  """
  @spec safe_to_string(safe) :: String.t()
  def safe_to_string({:safe, iodata}) do
    IO.iodata_to_binary(iodata)
  end

  @doc ~S"""
  Escapes an enumerable of attributes, returning iodata.

  The attributes are rendered in the given order. Note if
  a map is given, the key ordering is not guaranteed.

  The keys and values can be of any shape, as long as they
  implement the `Phoenix.HTML.Safe` protocol. In addition,
  if the key is an atom, it will be "dasherized". In other
  words, `:phx_value_id` will be converted to `phx-value-id`.

  Furthemore, the following attributes provide behaviour:

    * `:aria`, `:data`, and `:phx` - they accept a keyword list as
      value. `data: [confirm: "are you sure?"]` is converted to
      `data-confirm="are you sure?"`.

    * `:class` - it accepts a list of classes as argument. Each
      element in the list is separated by space. `nil` and `false`
      elements are discarded. `class: ["foo", nil, "bar"]` then
      becomes `class="foo bar"`.

    * `:id` - it is validated raise if a number is given as ID,
      which is not allowed by the HTML spec and leads to unpredictable
      behaviour.

  ## Examples

      iex> safe_to_string attributes_escape(title: "the title", id: "the id", selected: true)
      " title=\"the title\" id=\"the id\" selected"

      iex> safe_to_string attributes_escape(%{data: [confirm: "Are you sure?"], class: "foo"})
      " class=\"foo\" data-confirm=\"Are you sure?\""

      iex> safe_to_string attributes_escape(%{phx: [value: [foo: "bar"]], class: "foo"})
      " class=\"foo\" phx-value-foo=\"bar\""

  """
  def attributes_escape(attrs) when is_list(attrs) do
    {:safe, build_attrs(attrs)}
  end

  def attributes_escape(attrs) do
    {:safe, attrs |> Enum.to_list() |> build_attrs()}
  end

  defp build_attrs([{k, true} | t]),
    do: [?\s, key_escape(k) | build_attrs(t)]

  defp build_attrs([{_, false} | t]),
    do: build_attrs(t)

  defp build_attrs([{_, nil} | t]),
    do: build_attrs(t)

  defp build_attrs([{:id, v} | t]),
    do: [" id=\"", id_value(v), ?" | build_attrs(t)]

  defp build_attrs([{:class, v} | t]),
    do: [" class=\"", class_value(v), ?" | build_attrs(t)]

  defp build_attrs([{:aria, v} | t]) when is_list(v),
    do: nested_attrs(v, " aria", t)

  defp build_attrs([{:data, v} | t]) when is_list(v),
    do: nested_attrs(v, " data", t)

  defp build_attrs([{:phx, v} | t]) when is_list(v),
    do: nested_attrs(v, " phx", t)

  defp build_attrs([{"id", v} | t]),
    do: [" id=\"", id_value(v), ?" | build_attrs(t)]

  defp build_attrs([{"class", v} | t]),
    do: [" class=\"", class_value(v), ?" | build_attrs(t)]

  defp build_attrs([{"aria", v} | t]) when is_list(v),
    do: nested_attrs(v, " aria", t)

  defp build_attrs([{"data", v} | t]) when is_list(v),
    do: nested_attrs(v, " data", t)

  defp build_attrs([{"phx", v} | t]) when is_list(v),
    do: nested_attrs(v, " phx", t)

  defp build_attrs([{k, v} | t]),
    do: [?\s, key_escape(k), ?=, ?", attr_escape(v), ?" | build_attrs(t)]

  defp build_attrs([]), do: []

  defp nested_attrs([{k, v} | kv], attr, t) when is_list(v),
    do: [nested_attrs(v, "#{attr}-#{key_escape(k)}", []) | nested_attrs(kv, attr, t)]

  defp nested_attrs([{k, v} | kv], attr, t),
    do: [attr, ?-, key_escape(k), ?=, ?", attr_escape(v), ?" | nested_attrs(kv, attr, t)]

  defp nested_attrs([], _attr, t),
    do: build_attrs(t)

  defp id_value(value) when is_number(value) do
    raise ArgumentError,
          "attempting to set id attribute to #{value}, but the DOM ID cannot be set to a number"
  end

  defp id_value(value) do
    attr_escape(value)
  end

  defp class_value(value) when is_list(value) do
    value
    |> Enum.filter(& &1)
    |> Enum.join(" ")
    |> attr_escape()
  end

  defp class_value(value) do
    attr_escape(value)
  end

  defp key_escape(value) when is_atom(value), do: String.replace(Atom.to_string(value), "_", "-")
  defp key_escape(value), do: attr_escape(value)

  defp attr_escape({:safe, data}), do: data
  defp attr_escape(nil), do: []
  defp attr_escape(other) when is_binary(other), do: Phoenix.HTML.Engine.encode_to_iodata!(other)
  defp attr_escape(other), do: Phoenix.HTML.Safe.to_iodata(other)

  @doc """
  Escapes HTML content to be inserted a JavaScript string.

  This function is useful in JavaScript responses when there is a need
  to escape HTML rendered from other templates, like in the following:

      $("#container").append("<%= javascript_escape(render("post.html", post: @post)) %>");

  It escapes quotes (double and single), double backslashes and others.
  """
  @spec javascript_escape(binary) :: binary
  @spec javascript_escape(safe) :: safe
  def javascript_escape({:safe, data}),
    do: {:safe, data |> IO.iodata_to_binary() |> javascript_escape("")}

  def javascript_escape(data) when is_binary(data),
    do: javascript_escape(data, "")

  defp javascript_escape(<<0x2028::utf8, t::binary>>, acc),
    do: javascript_escape(t, <<acc::binary, "\\u2028">>)

  defp javascript_escape(<<0x2029::utf8, t::binary>>, acc),
    do: javascript_escape(t, <<acc::binary, "\\u2029">>)

  defp javascript_escape(<<0::utf8, t::binary>>, acc),
    do: javascript_escape(t, <<acc::binary, "\\u0000">>)

  defp javascript_escape(<<"</", t::binary>>, acc),
    do: javascript_escape(t, <<acc::binary, ?<, ?\\, ?/>>)

  defp javascript_escape(<<"\r\n", t::binary>>, acc),
    do: javascript_escape(t, <<acc::binary, ?\\, ?n>>)

  defp javascript_escape(<<h, t::binary>>, acc) when h in [?", ?', ?\\, ?`],
    do: javascript_escape(t, <<acc::binary, ?\\, h>>)

  defp javascript_escape(<<h, t::binary>>, acc) when h in [?\r, ?\n],
    do: javascript_escape(t, <<acc::binary, ?\\, ?n>>)

  defp javascript_escape(<<h, t::binary>>, acc),
    do: javascript_escape(t, <<acc::binary, h>>)

  defp javascript_escape(<<>>, acc), do: acc

  @doc """
  Returns a list of attributes that make an element behave like a link.

  For example, to make a button work like a link:

      <button {link_attributes("/home")}>
        Go back to home
      </button>

  However, this function is more often used to create buttons that
  must invoke an action on the server, such as deleting an entity,
  using the relevant HTTP protocol:

      <button data-confirm="Are you sure?" {link_attributes("/product/1", method: :delete}>
        Delete product
      </button>

  The `to` argument may be a string, a URI, or a tuple `{scheme, value}`.
  See the examples below.

  Note: using this function requires loading the JavaScript library
  at `priv/static/phoenix_html.js`. See the `Phoenix.HTML` module
  documentation for more information.

  ## Options

    * `:method` - the HTTP method for the link. Defaults to `:get`.

    * `:csrf_token` - a custom token to use when method is not `:get`.
      By default, CSRF tokens are generated through `Plug.CSRFProtection`.
      You can set this option to `false`, to disable token generation,
      or set it to your own token.

  When the `:method` is set to `:get` and the `:to` URL contains query
  parameters the generated form element will strip the parameters in
  accordance with the [W3C](https://www.w3.org/TR/html401/interact/forms.html#h-17.13.3.4)
  form specification.

  ## Data attributes

  The following data attributes can also be manually set in the element:

    * `data-confirm` - shows a confirmation prompt before generating and
      submitting the form.

  ## Examples

      iex> link_attributes("/world")
      [data: [method: :get, to: "/world"]]

      iex> link_attributes(URI.parse("https://elixir-lang.org"))
      [data: [method: :get, to: "https://elixir-lang.org"]]

      iex> link_attributes("/product/1", method: :delete)
      [data: [csrf: Plug.CSRFProtection.get_csrf_token(), method: :delete, to: "/product/1"]]

  If the URL is absolute, only certain schemas are allowed to
  avoid JavaScript injection. For example, the following will fail:

      iex> link_attributes("javascript:alert('hacked!')")
      ** (ArgumentError) unsupported scheme given as link. In case you want to link to an
      unknown or unsafe scheme, such as javascript, use a tuple: {:javascript, rest}

  You can however explicitly render those unsafe schemes by using a tuple:

      iex> link_attributes({:javascript, "alert('my alert!')"})
      [data: [method: :get, to: ["javascript", 58, "alert('my alert!')"]]]

  """
  def link_attributes(to, opts \\ []) do
    to = valid_destination!(to)
    method = Keyword.get(opts, :method, :get)
    data = [method: method, to: to]

    data =
      if method == :get do
        data
      else
        case Keyword.get(opts, :csrf_token, true) do
          true -> [csrf: Phoenix.HTML.Tag.csrf_token_value(to)] ++ data
          false -> data
          csrf when is_binary(csrf) -> [csrf: csrf] ++ data
        end
      end

    [data: data]
  end

  defp valid_destination!(%URI{} = uri) do
    valid_destination!(URI.to_string(uri))
  end

  defp valid_destination!({:safe, to}) do
    {:safe, valid_string_destination!(IO.iodata_to_binary(to))}
  end

  defp valid_destination!({other, to}) when is_atom(other) do
    [Atom.to_string(other), ?:, to]
  end

  defp valid_destination!(to) do
    valid_string_destination!(IO.iodata_to_binary(to))
  end

  @valid_uri_schemes ~w(http: https: ftp: ftps: mailto: news: irc: gopher:) ++
                       ~w(nntp: feed: telnet: mms: rtsp: svn: tel: fax: xmpp:)

  for scheme <- @valid_uri_schemes do
    defp valid_string_destination!(unquote(scheme) <> _ = string), do: string
  end

  defp valid_string_destination!(to) do
    if not match?("/" <> _, to) and String.contains?(to, ":") do
      raise ArgumentError, """
      unsupported scheme given as link. In case you want to link to an
      unknown or unsafe scheme, such as javascript, use a tuple: {:javascript, rest}\
      """
    else
      to
    end
  end
end
