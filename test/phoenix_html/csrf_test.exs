defmodule Phoenix.HTML.CSRFTest do
  use ExUnit.Case, async: false

  import Phoenix.HTML
  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag

  test "link with post using a custom csrf token" do
    assert safe_to_string(link("hello", to: "/world", method: :post)) =~
             ~r(<a data-csrf="[^"]+" data-method="post" data-to="/world" href="/world" rel="nofollow">hello</a>)
  end

  test "link with put/delete using a custom csrf token" do
    assert safe_to_string(link("hello", to: "/world", method: :put)) =~
             ~r(<a data-csrf="[^"]+" data-method="put" data-to="/world" href="/world" rel="nofollow">hello</a>)
  end

  test "button with post using a custom csrf token" do
    assert safe_to_string(button("hello", to: "/world")) =~
             ~r(<button data-csrf="[^"]+" data-method="post" data-to="/world">hello</button>)
  end

  test "form_tag for post using a custom csrf token" do
    assert safe_to_string(form_tag("/")) =~ ~r(
                <form\ accept-charset="UTF-8"\ action="/"\ method="post">
                <input\ name="_csrf_token"\ type="hidden"\ value="[^"]+">
                <input\ name="_utf8"\ type="hidden"\ value="✓">
              )mx
  end

  test "form_tag for other method using a custom csrf token" do
    assert safe_to_string(form_tag("/", method: :put)) =~ ~r(
                <form\ accept-charset="UTF-8"\ action="/"\ method="post">
                <input\ name="_method"\ type="hidden"\ value="put">
                <input\ name="_csrf_token"\ type="hidden"\ value="[^"]+">
                <input\ name="_utf8"\ type="hidden"\ value="✓">
              )mx
  end

  test "csrf_meta_tag" do
    assert safe_to_string(csrf_meta_tag()) =~
             ~r(<meta charset="UTF-8" content="[^"]+" csrf-param="_csrf_token" method-param="_method" name="csrf-token">)
  end
end
