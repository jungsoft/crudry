{:ok, _pid} = Crudry.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(Crudry.Repo, :manual)
ExUnit.start()
