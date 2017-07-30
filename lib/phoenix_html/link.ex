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

      link("<hello>", to: "/world")
      #=> <a href="/world">&lt;hello&gt;</a>

      link("<hello>", to: "/world", class: "btn")
      #=> <a class="btn" href="/world">&lt;hello&gt;</a>

      link("delete", to: "/the_world", data: [confirm: "Really?"])
      #=> <a data-confirm="Really?" href="/the_world">delete</a>

      # If you supply a method other than `:get`:
      link("delete", to: "/everything", method: :delete)
      #=> <a href="#" data-csrf="csrf_token" data-method="delete" data-to="/everything">delete</a>

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

  All other options are forwarded to the underlying `<a>` tag.

  ## Data attributes

  Data attributes are added as a keyword list passed to the
  `data` key. The following data attributes are supported:

    * `data-confirm` - shows a confirmation prompt before
      generating and submitting the form when `:method`
      is not `:get`.

  ## JavaScript dependency

  In order to support links where `:method` is not `:get`
  or use the above data attributes, `Phoenix.HTML` relies
  on JavaScript. You can load `priv/static/phoenix_html.js`
  into your build tool.

  ## CSRF Protection

  By default, CSRF tokens are generated through `Plug.CSRFProtection`. You
  can customize the CSRF token generation by configuring your own MFA:

      config :phoenix_html, csrf_token_generator: {MyGenerator, :get_token, []}

  """
  def link(text, opts)

  def link(opts, do: contents) when is_list(opts) do
    link(contents, opts)
  end

  def link(_text, opts) when not is_list(opts) do
    raise ArgumentError, "link/2 requires a keyword list as second argument"
  end

  def link(text, opts) do
    {to, opts} = pop_required_option!(opts, :to, "expected non-nil value for :to in link/2")
    {method, opts} = Keyword.pop(opts, :method, :get)

    if method == :get do
      opts = skip_csrf(opts)
      content_tag(:a, text, [href: to] ++ opts)
    else
      {csrf_data, opts} = csrf_data(opts)
      opts = Keyword.put_new(opts, :rel, "nofollow")
      content_tag(:a, text, [href: "#", data: [method: method, to: to] ++ csrf_data] ++ opts)
    end
  end

  @doc false
  # No docs since this function is only called when a `do` block is passed as
  # `do:` instead of `do...end` (and that case is documented in `link/2`).
  def link(opts) when is_list(opts) do
    error = "link/2 requires a text as first argument or contents in the :do block"
    {contents, opts} = pop_required_option!(opts, :do, error)
    link(contents, opts)
  end

  @doc """
  Generates a button that uses a regular HTML form to submit to the given URL.

  Useful to ensure that links that change data are not triggered by
  search engines and other spidering software.

  ## Examples

      button("hello", to: "/world")
      #=> <button class="button" data-csrf="csrf_token" data-method="post" data-to="/world">hello</button>

      button("hello", to: "/world", method: "get", class: "btn")
      #=> <button class="btn" data-method="get" data-to="/world">hello</button>

  ## Options

    * `:to` - the page to link to. This option is required

    * `:method` - the method to use with the button. Defaults to :post.

  All other options are forwarded to the underlying button input.
  """
  def button(opts, [do: contents]) do
    button(contents, opts)
  end

  def button(text, opts) do
    {to, opts} = pop_required_option!(opts, :to, "option :to is required in button/2")
    {method, opts} = Keyword.pop(opts, :method, :post)

    if method == :get do
      opts = skip_csrf(opts)
      content_tag(:button, text, [data: [method: method, to: to]] ++ opts)
    else
      {csrf_data, opts} = csrf_data(opts)
      content_tag(:button, text, [data: [method: method, to: to] ++ csrf_data] ++ opts)
    end
  end

  defp skip_csrf(opts) do
    Keyword.delete(opts, :csrf_token)
  end

  defp csrf_data(opts) do
    {csrf_token?, opts} = Keyword.pop(opts, :csrf_token, true)
    if csrf_token = csrf_token? && get_csrf_token() do
      {[csrf: csrf_token], opts}
    else
      {[], opts}
    end
  end

  defp get_csrf_token do
    {mod, fun, args} = Application.fetch_env!(:phoenix_html, :csrf_token_generator)
    apply(mod, fun, args)
  end

  defp pop_required_option!(opts, key, error_message) do
    {value, opts} = Keyword.pop(opts, key)

    unless value do
      raise ArgumentError, error_message
    end

    {value, opts}
  end
end
