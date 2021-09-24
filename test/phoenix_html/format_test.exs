defmodule Phoenix.HTML.FormatTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML.Format
  import Phoenix.HTML

  doctest Phoenix.HTML.Format

  test "wraps paragraphs" do
    formatted =
      format("""
      Hello,

      Please come see me.

      Regards,
      The Boss.
      """)

    assert formatted == """
           <p>Hello,</p>
           <p>Please come see me.</p>
           <p>Regards,<br>
           The Boss.</p>
           """
  end

  test "wraps paragraphs with carriage returns" do
    formatted = format("Hello,\r\n\r\nPlease come see me.\r\n\r\nRegards,\r\nThe Boss.")

    assert formatted == """
           <p>Hello,</p>
           <p>Please come see me.</p>
           <p>Regards,<br>
           The Boss.</p>
           """
  end

  test "escapes html" do
    formatted =
      format("""
      <script></script>
      """)

    assert formatted == """
           <p>&lt;script&gt;&lt;/script&gt;</p>
           """
  end

  test "skips escaping html" do
    formatted =
      format(
        """
        <script></script>
        """,
        escape: false
      )

    assert formatted == """
           <p><script></script></p>
           """
  end

  test "adds brs" do
    formatted =
      format("""
      Hello,
      This is dog,
      How can I help you?


      """)

    assert formatted == """
           <p>Hello,<br>
           This is dog,<br>
           How can I help you?</p>
           """
  end

  test "adds brs with carriage return" do
    formatted = format("Hello,\r\nThis is dog,\r\nHow can I help you?\r\n\r\n\r\n")

    assert formatted == """
           <p>Hello,<br>
           This is dog,<br>
           How can I help you?</p>
           """
  end

  test "doesn't add brs" do
    formatted =
      format(
        """
        Hello,
        This is dog,
        How can I help you?


        """,
        insert_brs: false
      )

    assert formatted == """
           <p>Hello, This is dog, How can I help you?</p>
           """
  end

  defp format(text, opts \\ []) do
    text |> text_to_html(opts) |> safe_to_string
  end
end
