defmodule PhoenixHtml.Mixfile do
  use Mix.Project

  @version "1.0.0"

  def project do
    [app: :phoenix_html,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,

     name: "Phoenix.HTML",
     description: "Phoenix.HTML functions for working with HTML strings and templates",
     docs: [source_ref: "v#{@version}",
            source_url: "https://github.com/phoenixframework/phoenix_html"]]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :plug]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:plug, ">= 0.12.2 and < 2.0.0"},

     # Docs dependencies
     {:earmark, "~> 0.1", only: :docs},
     {:ex_doc, "~> 0.7.1", only: :docs}]
  end
end
