defmodule CrudryTest do
  use ExUnit.Case
  doctest Crudry

  # Mock for Repo.
  defmodule Repo do
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
  defmodule Test do
    defstruct x: "123", bang: false

    def changeset(test, attrs) do
      Map.merge(test, attrs)
    end
  end

  # Mock for a context
  defmodule Mock do
    alias CrudryTest.Repo

    Crudry.define_functions CrudryTest.Test
  end

  test "creates the CRUD functions" do
    assert Mock.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert Mock.list_tests() == [1, 2, 3]
    assert Mock.get_test(1) == %Test{x: "123"}
    assert Mock.get_test!(3) == %Test{x: "123", bang: true}
    assert Mock.update_test(struct(Test), %{x: 3}) == {:ok, %Test{x: 3}}
    assert Mock.update_test(3, %{x: 3}) == {:ok, %Test{x: 3}}
    assert Mock.delete_test(struct(Test)) == :deleted
    assert Mock.delete_test(2) == :deleted
  end
end
