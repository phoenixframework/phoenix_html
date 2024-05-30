defmodule PhoenixHTML.Mixfile do
  use Mix.Project

  # Also change package.json version
  @source_url "https://github.com/phoenixframework/phoenix_html"
  @version "3.3.4"

  def project do
    [
      app: :phoenix_html,
      version: @version,
      elixir: "~> 1.7",
      deps: deps(),
      name: "Phoenix.HTML",
      description: "Phoenix view functions for working with HTML templates",
      package: package(),
      docs: [
        extras: ["CHANGELOG.md"],
        source_url: @source_url,
        source_ref: "v#{@version}",
        main: "Phoenix.HTML",
        skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:eex, :logger],
      env: [csrf_token_reader: {Plug.CSRFProtection, :get_csrf_token_for, []}]
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.5", optional: true},
      {:ex_doc, ">= 0.0.0", only: :docs}
    ]
  end

  defp package do
    [
      maintainers: ["Chris McCord", "José Valim"],
      licenses: ["MIT"],
      files: ~w(lib priv CHANGELOG.md LICENSE mix.exs package.json README.md),
      links: %{
        Changelog: "https://hexdocs.pm/phoenix_html/changelog.html",
        GitHub: @source_url
      }
    ]
  end
end
