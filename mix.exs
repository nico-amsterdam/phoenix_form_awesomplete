defmodule PhoenixFormAwesomplete.Mixfile do
  use Mix.Project

  def project do
    [app: :phoenix_form_awesomplete,
     version: "0.1.0",
     elixir: "~> 1.3",
     description: description,
     package: package,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
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
      {:phoenix_html, "~> 2.4"},
      {:ex_doc,  "~> 0.12", only: :dev}
    ]
  end

  defp description do
    """
Phoenix form helper that utilizes Lea Verou's autocomplete autosuggest
typeahead Awesomplete widget, featuring dynamic data loading using
ajax JSON requests.
    """
  end

  defp package do
    [
     name: :phoenix_form_awesomplete,
     maintainers: ["Nico Hoogervorst"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/nico-amsterdam/phoenix_form_awesomplete", 
              "Documentation with live examples" => "https://nico-amsterdam.github.io/awesomplete-util/phoenix.html" }
    ]
  end
end
