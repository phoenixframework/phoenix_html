defmodule PhoenixHtml.Mixfile do
  use Mix.Project

  # Also change package.json version
  @version "2.14.3"

  def project do
    [
      app: :phoenix_html,
      version: @version,
      elixir: "~> 1.5.1 or ~> 1.6",
      deps: deps(),
      name: "Phoenix.HTML",
      description: "Phoenix view functions for working with HTML templates",
      package: package(),
      docs: [
        source_ref: "v#{@version}",
        main: "Phoenix.HTML",
        source_url: "https://github.com/phoenixframework/phoenix_html"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:eex, :logger]
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.5"},
      {:ex_doc, ">= 0.0.0", only: :docs}
    ]
  end

  defp package do
    [
      maintainers: ["Chris McCord", "José Valim"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/phoenixframework/phoenix_html"},
      files: ~w(lib priv CHANGELOG.md LICENSE mix.exs package.json README.md)
    ]
  end
end
