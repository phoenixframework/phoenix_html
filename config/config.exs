import Config

if Mix.env() == :dev do
  esbuild = fn args ->
    [
      args: ~w(./js/phoenix_html --bundle) ++ args,
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]
  end

  config :esbuild,
    version: "0.17.5",
    module: esbuild.(~w(--format=esm --sourcemap --outfile=../priv/static/phoenix_html.esm.js)),
    main: esbuild.(~w(--format=cjs --sourcemap --outfile=../priv/static/phoenix_html.cjs.js)),
    cdn:
      esbuild.(
        ~w(--format=iife --target=es2016 --global-name=PhoenixHTML --outfile=../priv/static/phoenix_html.js)
      ),
    cdn_min:
      esbuild.(
        ~w(--format=iife --target=es2016 --global-name=PhoenixHTML --minify --outfile=../priv/static/phoenix_html.min.js)
      )
end
