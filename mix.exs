defmodule Crudry.MixProject do
  use Mix.Project

  @github_url "https://github.com/jungsoft/crudry"

  def project do
    [
      app: :crudry,
      version: "2.4.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      compilers: [:gettext] ++ Mix.compilers,
      deps: deps(),
      name: "Crudry",
      source_url: @github_url,
      description: "Crudry is a library for DRYing CRUD.",
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test]
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
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
      licenses: ["MIT"],
      links: %{
        "GitHub" => @github_url,
        "Docs" => "https://hexdocs.pm/crudry/"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:ecto, ">= 3.0.0"},
      {:ecto_sql, ">= 3.0.0", only: :test},
      {:postgrex, ">= 0.0.0", only: :test},
      {:absinthe, ">= 1.4.0"},
      {:excoveralls, "~> 0.11", only: :test},
      {:gettext, ">= 0.0.0"},
    ]
  end
end
