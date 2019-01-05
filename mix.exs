defmodule Crudry.MixProject do
  use Mix.Project

  def project do
    [
      app: :crudry,
      version: "0.2.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Crudry",
      source_url: "https://github.com/gabrielpra1/crudry",
      description: "Crudry is a library for DRYing CRUD.",
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs README*),
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/gabrielpra1/crudry",
        "Docs" => "https://hexdocs.pm/crudry/"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:inflex, "~> 1.10.0"}
    ]
  end
end
