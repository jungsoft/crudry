defmodule CrudryTest do
  use ExUnit.Case
  doctest Crudry

  alias CrudryTest.Test

  test "creates the CRUD functions" do
    defmodule Context do
      alias CrudryTest.Repo
      alias CrudryTest.Test

      Crudry.generate_functions(Test)
    end

    assert Context.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert Context.list_tests() == [1, 2, 3]
    assert Context.get_test(1) == %Test{x: "123"}
    assert Context.get_test!(3) == %Test{x: "123", bang: true}
    assert Context.update_test(struct(Test), %{x: 3}) == {:ok, %Test{x: 3}}
    assert Context.update_test(3, %{x: 3}) == {:ok, %Test{x: 3}}
    assert Context.delete_test(struct(Test)) == :deleted
    assert Context.delete_test(2) == :deleted
  end

  test "allow defining of create changeset" do
    defmodule ContextCreate do
      alias CrudryTest.Repo

      Crudry.generate_functions(CrudryTest.Test, create: :create_changeset)
    end

    assert ContextCreate.create_test(%{x: 2}) == {:ok, %Test{x: 3}}
    assert ContextCreate.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 2}}
  end

  test "allow defining of update changeset" do
    defmodule ContextUpdate do
      alias CrudryTest.Repo

      Crudry.generate_functions(CrudryTest.Test, update: :update_changeset)
    end

    assert ContextUpdate.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert ContextUpdate.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 4}}
  end

  test "allow defining of both changeset functions" do
    defmodule ContextBoth do
      alias CrudryTest.Repo

      Crudry.generate_functions(CrudryTest.Test,
        create: :create_changeset,
        update: :update_changeset
      )
    end

    assert ContextBoth.create_test(%{x: 2}) == {:ok, %Test{x: 3}}
    assert ContextBoth.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 4}}
  end

  test "allow defining default changeset functions for context" do
    defmodule ContextDefault do
      alias CrudryTest.Repo

      Crudry.default(create: :create_changeset, update: :update_changeset)
      Crudry.generate_functions(CrudryTest.Test)
    end

    assert ContextDefault.create_test(%{x: 2}) == {:ok, %Test{x: 3}}
    assert ContextDefault.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 4}}
  end

  test "choose which CRUD functions are to be generated" do
    defmodule ContextOnly do
      alias CrudryTest.Repo

      Crudry.generate_functions(CrudryTest.Test, only: [:create, :list])
    end

    assert ContextOnly.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert ContextOnly.list_tests() == [1, 2, 3]
    assert length(ContextOnly.__info__(:functions)) == 2

    defmodule ContextExcept do
      alias CrudryTest.Repo

      Crudry.generate_functions(CrudryTest.Test, except: [:get!, :list, :delete])
    end

    assert ContextExcept.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert ContextExcept.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 2}}
    assert length(ContextExcept.__info__(:functions)) == 3
  end

  test "choose which CRUD functions are to be generated by default" do
    defmodule ContextOnlyDefault do
      alias CrudryTest.Repo

      Crudry.default(only: [:create, :list])
      Crudry.generate_functions(CrudryTest.Test)
    end

    assert ContextOnlyDefault.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert ContextOnlyDefault.list_tests() == [1, 2, 3]
    assert length(ContextOnlyDefault.__info__(:functions)) == 2

    defmodule ContextExceptDefault do
      alias CrudryTest.Repo

      Crudry.default(except: [:get!, :list, :delete])
      Crudry.generate_functions(CrudryTest.Test)
    end

    assert ContextExceptDefault.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert ContextExceptDefault.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 2}}
    assert length(ContextExceptDefault.__info__(:functions)) == 3
  end

  test "underscore camelized schema name" do
    defmodule ContextUnderscore do
      alias CrudryTest.Repo
      Crudry.generate_functions(CrudryTest.CamelizedSchemaName)
    end

    assert ContextUnderscore.create_camelized_schema_name(%{x: 2}) ==
             {:ok, %CrudryTest.CamelizedSchemaName{x: 2}}

    assert ContextUnderscore.list_camelized_schema_names() == [1, 2, 3]
  end

  test "pluralize correctly" do
    defmodule ContextPluralize do
      alias CrudryTest.Repo
      Crudry.generate_functions(CrudryTest.Category)
    end

    assert ContextPluralize.create_category(%{x: 2}) == {:ok, %CrudryTest.Category{x: 2}}
    assert ContextPluralize.list_categories() == [1, 2, 3]
  end
end
