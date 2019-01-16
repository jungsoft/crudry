use Mix.Config

# Repos known to Ecto:
config :crudry, ecto_repos: [Crudry.Repo]

# Test Repo settings
config :crudry, Crudry.Repo,
  database: "crudry_test",
  hostname: "localhost",
  poolsize: 10,
  # Ensure async testing is possible:
  pool: Ecto.Adapters.SQL.Sandbox

import_config "db.secret.exs"
