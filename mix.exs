defmodule PhoenixHtml.Mixfile do
  use Mix.Project

  @version "2.5.0"

  def project do
    [app: :phoenix_html,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,

     name: "Phoenix.HTML",
     description: "Phoenix.HTML functions for working with HTML strings and templates",
     package: package,
     docs: [source_ref: "v#{@version}", main: "Phoenix.HTML",
            source_url: "https://github.com/phoenixframework/phoenix_html"]]
  end

  def application do
    [applications: [:logger, :plug]]
  end

  defp deps do
    [{:plug, "~> 0.13 or ~> 1.0"},

     # Docs dependencies
     {:earmark, "~> 0.1", only: :docs},
     {:ex_doc, "~> 0.11", only: :docs}]
  end

  defp package do
    [maintainers: ["Chris McCord", "José Valim"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/phoenixframework/phoenix_html"},
     files: ~w(lib priv web) ++
            ~w(brunch-config.js CHANGELOG.md LICENSE mix.exs package.json README.md)]
  end
end
