defmodule Phoenix.HTML.Link do
  @moduledoc """
  Conveniences for working with links and URLs in HTML.
  """

  import Phoenix.HTML.Tag

  @doc """
  Generates a link to the given URL.

  ## Examples

      link("hello", to: "/world")
      #=> <a href="/world">hello</a>

      link("hello", to: URI.parse("https://elixir-lang.org"))
      #=> <a href="https://elixir-lang.org">hello</a>

      link("<hello>", to: "/world")
      #=> <a href="/world">&lt;hello&gt;</a>

      link("<hello>", to: "/world", class: "btn")
      #=> <a class="btn" href="/world">&lt;hello&gt;</a>

      link("delete", to: "/the_world", data: [confirm: "Really?"])
      #=> <a data-confirm="Really?" href="/the_world">delete</a>

      # If you supply a method other than `:get`:
      link("delete", to: "/everything", method: :delete)
      #=> <a href="/everything" data-csrf="csrf_token" data-method="delete" data-to="/everything">delete</a>

      # You can use a `do ... end` block too:
      link to: "/hello" do
        "world"
      end

  ## Options

    * `:to` - the page to link to. This option is required

    * `:method` - the method to use with the link. In case the
      method is not `:get`, the link is generated inside the form
      which sets the proper information. In order to submit the
      form, JavaScript must be enabled

    * `:csrf_token` - a custom token to use for links with a method
      other than `:get`.

  All other options are forwarded to the underlying `<a>` tag.

  ## JavaScript dependency

  In order to support links where `:method` is not `:get` or use the above
  data attributes, `Phoenix.HTML` relies on JavaScript. You can load
  `priv/static/phoenix_html.js` into your build tool.

  ### Data attributes

  Data attributes are added as a keyword list passed to the `data` key.
  The following data attributes are supported:

    * `data-confirm` - shows a confirmation prompt before
      generating and submitting the form when `:method`
      is not `:get`.

  ### Overriding the default confirm behaviour

  `phoenix_html.js` does trigger a custom event `phoenix.link.click` on the
  clicked DOM element when a click happened. This allows you to intercept the
  event on it's way bubbling up to `window` and do your own custom logic to
  enhance or replace how the `data-confirm` attribute is handled.

  You could for example replace the browsers `confirm()` behavior with a
  custom javascript implementation:

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

  Or you could attach your own custom behavior.

  ```javascript
  window.addEventListener('phoenix.link.click', function (e) {
    // Introduce custom behaviour
    var message = e.target.getAttribute("data-prompt");
    var answer = e.target.getAttribute("data-prompt-answer");
    if(message && answer && (answer != window.prompt(message))) {
      e.preventDefault();
    }
  }, false);
  ```

  The latter could also be bound to any `click` event, but this way you can be
  sure your custom code is only executed when the code of `phoenix_html.js` is run.

  ## CSRF Protection

  By default, CSRF tokens are generated through `Plug.CSRFProtection`.
  """
  @valid_uri_schemes [
    "http:",
    "https:",
    "ftp:",
    "ftps:",
    "mailto:",
    "news:",
    "irc:",
    "gopher:",
    "nntp:",
    "feed:",
    "telnet:",
    "mms:",
    "rtsp:",
    "svn:",
    "tel:",
    "fax:",
    "xmpp:"
  ]

  def link(text, opts)

  def link(opts, do: contents) when is_list(opts) do
    link(contents, opts)
  end

  def link(_text, opts) when not is_list(opts) do
    raise ArgumentError, "link/2 requires a keyword list as second argument"
  end

  def link(text, opts) do
    {to, opts} = pop_required_option!(opts, :to, "expected non-nil value for :to in link/2")
    to = valid_destination!(to, "link/2")
    {method, opts} = Keyword.pop(opts, :method, :get)

    if method == :get do
      opts = skip_csrf(opts)
      content_tag(:a, text, [href: to] ++ opts)
    else
      {csrf_data, opts} = csrf_data(to, opts)
      opts = Keyword.put_new(opts, :rel, "nofollow")
      content_tag(:a, text, [data: csrf_data ++ [method: method, to: to], href: to] ++ opts)
    end
  end

  @doc """
  Generates a button tag that uses the Javascript function handleClick()
  (see phoenix_html.js) to submit the form data.

  Useful to ensure that links that change data are not triggered by
  search engines and other spidering software.

  ## Examples

      button("hello", to: "/world")
      #=> <button class="button" data-csrf="csrf_token" data-method="post" data-to="/world">hello</button>

      button("hello", to: "/world", method: :get, class: "btn")
      #=> <button class="btn" data-method="get" data-to="/world">hello</button>

  ## Options

    * `:to` - the page to link to. This option is required

    * `:method` - the method to use with the button. Defaults to :post.

  All other options are forwarded to the underlying button input.

  When the `:method` is set to `:get` and the `:to` URL contains query
  parameters the generated form element will strip the parameters in accordance
  with the [W3C](https://www.w3.org/TR/html401/interact/forms.html#h-17.13.3.4)
  form specification.

  ## Data attributes

  Data attributes are added as a keyword list passed to the
  `data` key. The following data attributes are supported:

    * `data-confirm` - shows a confirmation prompt before generating and
      submitting the form.
  """
  def button(opts, do: contents) do
    button(contents, opts)
  end

  def button(text, opts) do
    {to, opts} = pop_required_option!(opts, :to, "option :to is required in button/2")
    {method, opts} = Keyword.pop(opts, :method, :post)

    to = valid_destination!(to, "button/2")

    if method == :get do
      opts = skip_csrf(opts)
      content_tag(:button, text, [data: [method: method, to: to]] ++ opts)
    else
      {csrf_data, opts} = csrf_data(to, opts)
      content_tag(:button, text, [data: csrf_data ++ [method: method, to: to]] ++ opts)
    end
  end

  defp skip_csrf(opts) do
    Keyword.delete(opts, :csrf_token)
  end

  defp csrf_data(to, opts) do
    case Keyword.pop(opts, :csrf_token, true) do
      {csrf, opts} when is_binary(csrf) ->
        {[csrf: csrf], opts}

      {true, opts} ->
        {[csrf: Phoenix.HTML.Tag.csrf_token_value(to)], opts}

      {false, opts} ->
        {[], opts}
    end
  end

  defp pop_required_option!(opts, key, error_message) do
    {value, opts} = Keyword.pop(opts, key)

    unless value do
      raise ArgumentError, error_message
    end

    {value, opts}
  end

  defp valid_destination!(%URI{} = uri, context) do
    valid_destination!(URI.to_string(uri), context)
  end

  defp valid_destination!({:safe, to}, context) do
    {:safe, valid_string_destination!(IO.iodata_to_binary(to), context)}
  end

  defp valid_destination!({other, to}, _context) when is_atom(other) do
    [Atom.to_string(other), ?:, to]
  end

  defp valid_destination!(to, context) do
    valid_string_destination!(IO.iodata_to_binary(to), context)
  end

  for scheme <- @valid_uri_schemes do
    defp valid_string_destination!(unquote(scheme) <> _ = string, _context), do: string
  end

  defp valid_string_destination!(to, context) do
    if not match?("/" <> _, to) and String.contains?(to, ":") do
      raise ArgumentError, """
      unsupported scheme given to #{context}. In case you want to link to an
      unknown or unsafe scheme, such as javascript, use a tuple: {:javascript, rest}
      """
    else
      to
    end
  end
end
