defmodule PhoenixFormAwesomplete.Mixfile do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/nico-amsterdam/phoenix_form_awesomplete"

  def project do
    [app: :phoenix_form_awesomplete,
     version: @version,
     elixir: "~> 1.15",

     # Hex
     package: package(),
     description: description(),

     # Docs
     name: "PhoenixFormAwesomplete",
     docs: [source_ref: "master", main: "PhoenixFormAwesomplete",
            canonical: "http://hexdocs.pm/phoenix_form_awesomplete",
            source_url: @source_url
           ],

     build_embedded:  Mix.env == :prod,
     start_permanent: Mix.env == :prod,

     deps: deps(),
     aliases: aliases()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
     extra_applications: [:logger]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:phoenix_html, "~> 2.10 or ~> 3.0 or ~> 4.0"},   # mix test of this project requires >= 3.3.0
      {:phoenix_live_view, "~> 0.20.14", override: true},
      {:ex_doc, "~> 0.32.1", only: :dev},
      {:esbuild, "~> 0.8", only: [:dev, :test]}
    ]
  end

  defp description do
    """
    Phoenix form helper that utilizes Lea Verou's autocomplete autosuggest
    typeahead Awesomplete widget, featuring dynamic data loading using
    ajax calls.
    """
  end

  defp package do
    [
     name: :phoenix_form_awesomplete,
     maintainers: ["Nico Hoogervorst"],
     licenses: ["MIT"],
     links: %{"GitHub" => @source_url,
              "Documentation with live examples" => "https://nico-amsterdam.github.io/awesomplete-util/phoenix.html" }
    ]
  end

  defp aliases do
    [
      "assets.build": ["esbuild module", "esbuild main", "esbuild css"]
    ]
  end
end
