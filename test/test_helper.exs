# Mock for Repo.
defmodule CrudryTest.Repo do
  def insert(changeset) do
    {:ok, changeset}
  end

  def all(_module) do
    [1, 2, 3]
  end

  def get(_module, 0) do
    nil
  end

  def get(module, _id) do
    struct(module)
  end

  def get!(module, _id) do
    struct(module)
    |> Map.put(:bang, true)
  end

  def update(changeset) do
    {:ok, changeset}
  end

  def delete(_) do
    {:ok, :deleted}
  end

  def preload(module, assocs) do
    Map.put(module, :assocs, assocs)
  end

  def aggregate(_query, _aggregate, _field) do
    6
  end
end

# Generate mock for an ecto schema.
defmodule Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      embedded_schema do
        field :x, :string, default: "123"
        field :bang, :boolean, default: false
        field :assocs, {:array, :string}, default: []
      end

      def changeset(test, attrs) do
        Map.merge(test, attrs)
      end

      def create_changeset(test, %{x: x}) do
        attrs = %{x: x + 1}
        Map.merge(test, attrs)
      end

      def update_changeset(test, %{x: x}) do
        attrs = %{x: x + 2}
        Map.merge(test, attrs)
      end
    end
  end
end

# Mocks for schemas
defmodule CrudryTest.Test do
  use Schema
end

defmodule CrudryTest.CamelizedSchemaName do
  use Schema
end

defmodule CrudryTest.Category do
  use Schema
end

{:ok, _pid} = Crudry.Repo.start_link
Ecto.Adapters.SQL.Sandbox.mode(Crudry.Repo, :manual)
ExUnit.start()
