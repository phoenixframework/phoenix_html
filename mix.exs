defmodule PhoenixHtml.Mixfile do
  use Mix.Project

  @version "2.0.0-dev"

  def project do
    [app: :phoenix_html,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,

     name: "Phoenix.HTML",
     description: "Phoenix.HTML functions for working with HTML strings and templates",
     docs: [source_ref: "v#{@version}", main: "Phoenix.HTML",
            source_url: "https://github.com/phoenixframework/phoenix_html"]]
  end

  def application do
    [applications: [:logger, :plug]]
  end

  defp deps do
    [{:plug, ">= 0.13 and < 2.0.0"},

     # Docs dependencies
     {:earmark, "~> 0.1", only: :docs},
     {:ex_doc, "~> 0.7.1", only: :docs}]
  end
end
