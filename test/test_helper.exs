# Mock for Repo.
defmodule CrudryTest.Repo do
  def insert(changeset) do
    {:ok, changeset}
  end

  def all(_module) do
    [1, 2, 3]
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
    :deleted
  end
end

# Mock for a schema
defmodule CrudryTest.Test do
  defstruct x: "123", bang: false

  # Each changeset functions changes `attrs` in a different way so
  # we can verify which one was called.
  # TODO: This is not a clean way to do it, so change it

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

ExUnit.start()
