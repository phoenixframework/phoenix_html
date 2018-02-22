defmodule Phoenix.HTML.CSRFTest do
  use ExUnit.Case, async: false

  import Phoenix.HTML
  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag

  defmodule TokenGenerator do
    def get, do: "custom-token"
  end

  setup_all do
    previous_generator = Application.fetch_env!(:phoenix_html, :csrf_token_generator)
    Application.put_env(:phoenix_html, :csrf_token_generator, {TokenGenerator, :get, []})

    on_exit(fn ->
      Application.put_env(:phoenix_html, :csrf_token_generator, previous_generator)
    end)

    :ok
  end

  test "link with post using a custom csrf token" do
    assert safe_to_string(link("hello", to: "/world", method: :post)) ==
             ~s[<a data-csrf="custom-token" data-method="post" data-to="/world" href="#" rel="nofollow">hello</a>]
  end

  test "link with put/delete using a custom csrf token" do
    assert safe_to_string(link("hello", to: "/world", method: :put)) ==
             ~s[<a data-csrf="custom-token" data-method="put" data-to="/world" href="#" rel="nofollow">hello</a>]
  end

  test "button with post using a custom csrf token" do
    assert safe_to_string(button("hello", to: "/world")) ==
             ~s[<button data-csrf="custom-token" data-method="post" data-to="/world">hello</button>]
  end

  test "form_tag for post using a custom csrf token" do
    assert safe_to_string(form_tag("/")) ==
             ~s(<form accept-charset="UTF-8" action="/" method="post">) <>
               ~s(<input name="_csrf_token" type="hidden" value="custom-token">) <>
               ~s(<input name="_utf8" type="hidden" value="✓">)
  end

  test "form_tag for other method using a custom csrf token" do
    assert safe_to_string(form_tag("/", method: :put)) ==
             ~s(<form accept-charset="UTF-8" action="/" method="post">) <>
               ~s(<input name="_method" type="hidden" value="put">) <>
               ~s(<input name="_csrf_token" type="hidden" value="custom-token">) <>
               ~s(<input name="_utf8" type="hidden" value="✓">)
  end

  test "csrf_meta_tag" do
    assert safe_to_string(csrf_meta_tag()) ==
             ~s(<meta charset="UTF-8" content="custom-token" csrf-param="_csrf_token" method-param="_method" name="csrf-token">)
  end
end
