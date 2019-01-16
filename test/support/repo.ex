defmodule Crudry.Repo do
  use Ecto.Repo, 
  otp_app: :crudry,
  adapter: Ecto.Adapters.Postgres
end