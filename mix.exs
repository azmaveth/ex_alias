defmodule ExAlias.MixProject do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/azmaveth/ex_alias"

  def project do
    [
      app: :ex_alias,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @github_url,
      homepage_url: @github_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.36", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    A flexible command alias system for Elixir applications.
    Supports recursive expansion, parameter substitution, and circular reference detection.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @github_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}",
      groups_for_modules: [
        Core: [ExAlias.Core],
        "Error Handling": [ExAlias.Error]
      ]
    ]
  end
end