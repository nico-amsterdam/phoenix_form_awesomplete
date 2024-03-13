# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
# use Mix.Config
import Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :phoenix_form_awesomplete, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:phoenix_form_awesomplete, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

    config :esbuild, 
      version: "0.17.11",
      module: [
        args: ~w(js/index.js --format=esm --sourcemap --bundle --target=es2016 --outfile=../priv/static/assets/awesomplete_bundle.mjs),
        cd: Path.expand("../assets", __DIR__),
        env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
      ],
      main: [
        args: ~w(js/index.js --format=cjs --sourcemap --bundle --target=es2016 --outfile=../priv/static/assets/awesomplete_bundle.cjs),
        cd: Path.expand("../assets", __DIR__),
        env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
      ],
      cdn: [
        args: ~w(js/index.js --format=iife --sourcemap --global-name=AwesompleteBundle --bundle --target=es2016 --outfile=../priv/static/assets/awesomplete_bundle.js),
        cd: Path.expand("../assets", __DIR__),
        env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
      ],
      cdn_min: [
        args: ~w(js/index.js --format=iife --sourcemap --global-name=AwesompleteBundle --bundle --target=es2016 --minify --outfile=../priv/static/assets/awesomplete_bundle.min.js),
        cd: Path.expand("../assets", __DIR__),
        env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
      ]
