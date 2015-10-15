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

    * `:form` - customize the underlying form when the method
      is not `:get`

  All other options are forwarded to the underlying `<a>` tag.

  ## Data attributes

  The following data attributes are supported/generated:

    * `data-submit=parent` - used when the `:method` is not
      `:get`, this module attribute says the underlying link
      should submit the parent node whenever there is a click

    * `data-confirm` - shows a confirmation prompt before
      submitting the parent when `:method` is not `:get`

  ## JavaScript dependency

  In order to support the data attributes above, `Phoenix.HTML`
  relies on JavaScript. You can either load the ES5 version from
  `priv/static/phoenix_html.js` or depend on the one at
  `web/static/js/phoenix_html.js` written in ES6 directly from
  your build tool.
  """
  def link(text, opts)

  def link(opts, do: contents) when is_list(opts) do
    link(contents, opts)
  end

  def link(_text, opts) when not is_list(opts) do
    raise ArgumentError, "link/2 requires a keyword list as second argument"
  end

  def link(text, opts) do
    {to, opts} = Keyword.pop(opts, :to)
    {method, opts} = Keyword.pop(opts, :method, :get)

    unless to do
      raise ArgumentError, "expected non-nil value for :to in link/2, got: #{inspect to}"
    end

    if method == :get do
      content_tag(:a, text, [href: to] ++ opts)
    else
      {form, opts} = form_options(opts, method, "link")
      form_tag(to, form) do
        content_tag(:a, text, [href: "#", data: [submit: "parent"]] ++ opts)
      end
    end
  end

  @doc false
  # No docs since this function is only called when a `do` block is passed as
  # `do:` instead of `do...end` (and that case is documented in `link/2`).
  def link(opts) when is_list(opts) do
    {contents, opts} = Keyword.pop(opts, :do)

    unless contents do
      raise ArgumentError, "link/2 requires a text as first argument or contents in the :do block"
    end

    link(contents, opts)
  end

  @doc """
  Generates a button that uses a regular HTML form to submit to the given URL.

  Useful to ensure that links that change data are not triggered by
  search engines and other spidering software.

  ## Examples

      button("hello", to: "/world")
      #=> <form action="/world" class="button" method="post">
            <input name="_csrf_token" value=""><input type="submit" value="hello">
          </form>

      button("hello", to: "/world", method: "get", class: "btn")
      #=> <form action="/world" class="btn" method="post">
            <input type="submit" value="hello">
          </form>

  ## Options

    * `:to` - the page to link to. This option is required

    * `:method` - the method to use with the button. Defaults to :post.

    * `:form` - the options for the form. Defaults to
      `[class: "button", enforce_utf8: false]`

  All other options are forwarded to the underlying button input.
  """
  def button(text) do
    html_button(text)
  end

  def button(text, opts) do
    case Keyword.pop(opts, :to) do
      {nil, opts} -> html_button(text, opts)
      {to, opts}  -> form_button(text, to, opts)
    end
  end

  def form_button(text, to, opts) do
    {method, opts} = Keyword.pop(opts, :method, :post)

    {form, opts} = form_options(opts, method, "button")

    opts =
      opts
      |> Keyword.put_new(:type, "submit")
      |> Keyword.put_new(:value, text)

    form_tag(to, form) do
      tag(:input, opts)
    end
  end

  def html_button(text, opts \\ []) do
    content_tag(:button, text, opts)
  end


  defp form_options(opts, method, class) do
    {form, opts} = Keyword.pop(opts, :form, [])

    form =
      form
      |> Keyword.put_new(:class, class)
      |> Keyword.put_new(:method, method)
      |> Keyword.put_new(:enforce_utf8, false)

    {form, opts}
  end
end
