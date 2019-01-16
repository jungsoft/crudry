defmodule CrudryContextTest do
  use ExUnit.Case
  doctest Crudry.Context

  alias Crudry.Repo

  @user %{username: "Chuck Norris"}
  @post %{title: "Chuck Norris threw a grenade and killed 50 people, then it exploded."}

  alias CrudryTest.Test

  test "creates the CRUD functions" do
    defmodule Context do
      alias CrudryTest.Repo
      alias CrudryTest.Test

      Crudry.Context.generate_functions(Test)
    end

    assert Context.create_test(%{x: 2}) == {:ok, %Test{x: 2}}

    assert Context.list_tests() == [1, 2, 3]

    # How to test these?
    #assert Context.list_tests(%{limit: 4}) == 2
    #assert Context.search_tests("asd") == 2
    #assert Context.filter_tests(%{id: [3,6]}) == 2

    assert Context.count_tests(:id) == 6

    assert Context.get_test(1) == %Test{x: "123"}
    assert Context.get_test!(3) == %Test{x: "123", bang: true}

    assert Context.get_test_with_assocs(1, [:assoc1, :assoc2]) == %Test{x: "123", assocs: [:assoc1, :assoc2]}

    assert Context.update_test(struct(Test), %{x: 3}) == {:ok, %Test{x: 3}}
    assert Context.update_test(3, %{x: 3}) == {:ok, %Test{x: 3}}

    assert Context.update_test_with_assocs(struct(Test), %{x: 3}, [:assocs]) == {:ok, %Test{x: 3, assocs: [:assocs]}}
    assert Context.update_test_with_assocs(3, %{x: 3}, [:assocs]) == {:ok, %Test{x: 3, assocs: [:assocs]}}

    assert Context.delete_test(struct(Test)) == {:ok, :deleted}
    assert Context.delete_test(2) == {:ok, :deleted}
  end

  test "return changeset error when deleting a parent record with a child associated constraint" do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    defmodule ContextDelete do
      alias Crudry.{User, Post}

      Crudry.Context.generate_functions(User, check_constraints_on_delete: [:posts])
      Crudry.Context.generate_functions(Post)
    end

    assert {:ok, %{} = user} = ContextDelete.create_user(@user)
    assert {:ok, %{} = post} = ContextDelete.create_post(%{title: @post.title, user_id: user.id})
    assert {:error, %Ecto.Changeset{}} = ContextDelete.delete_user(user)
  end


  test "return changeset error when deleting a parent record with childrens associated constraint" do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    defmodule ContextDeleteList do
      alias Crudry.Like
      alias Crudry.User
      alias Crudry.Post

      Crudry.Context.generate_functions(User, check_constraints_on_delete: [:posts, :likes])
      Crudry.Context.generate_functions(Post)
      Crudry.Context.generate_functions(Like)
    end

    assert {:ok, %{} = user} = ContextDeleteList.create_user(@user)
    assert {:ok, %{} = post} = ContextDeleteList.create_post(%{title: @post.title, user_id: user.id})
    assert {:ok, %{} = like} = ContextDeleteList.create_like(%{post_id: post.id, user_id: user.id})
    assert {:error, %Ecto.Changeset{}} = ContextDeleteList.delete_user(user)

    # Delete successfully after deleting children
    assert {:ok, %{}} = ContextDeleteList.delete_like(like.id)
    assert {:ok, %{}} = ContextDeleteList.delete_post(post.id)
    assert {:ok, %{}} = ContextDeleteList.delete_user(user.id)
  end

  test "allow defining of create changeset" do
    defmodule ContextCreate do
      alias CrudryTest.Repo

      Crudry.Context.generate_functions(CrudryTest.Test, create: :create_changeset)
    end

    assert ContextCreate.create_test(%{x: 2}) == {:ok, %Test{x: 3}}
    assert ContextCreate.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 2}}
  end

  test "allow defining of update changeset" do
    defmodule ContextUpdate do
      alias CrudryTest.Repo

      Crudry.Context.generate_functions(CrudryTest.Test, update: :update_changeset)
    end

    assert ContextUpdate.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert ContextUpdate.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 4}}
  end

  test "allow defining of both changeset functions" do
    defmodule ContextBoth do
      alias CrudryTest.Repo

      Crudry.Context.generate_functions(CrudryTest.Test,
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

      Crudry.Context.default(create: :create_changeset, update: :update_changeset)
      Crudry.Context.generate_functions(CrudryTest.Test)
    end

    assert ContextDefault.create_test(%{x: 2}) == {:ok, %Test{x: 3}}
    assert ContextDefault.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 4}}
  end

  test "choose which CRUD functions are to be generated" do
    defmodule ContextOnly do
      alias CrudryTest.Repo

      Crudry.Context.generate_functions(CrudryTest.Test, only: [:create, :list])
    end

    assert ContextOnly.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert ContextOnly.list_tests() == [1, 2, 3]
    assert length(ContextOnly.__info__(:functions)) == 3

    defmodule ContextExcept do
      alias CrudryTest.Repo

      Crudry.Context.generate_functions(CrudryTest.Test, except: [:get!, :list, :delete])
    end

    assert ContextExcept.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert ContextExcept.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 2}}
    assert length(ContextExcept.__info__(:functions)) == 9
  end

  test "choose which CRUD functions are to be generated by default" do
    defmodule ContextOnlyDefault do
      alias CrudryTest.Repo

      Crudry.Context.default(only: [:create, :list])
      Crudry.Context.generate_functions(CrudryTest.Test)
    end

    assert ContextOnlyDefault.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert ContextOnlyDefault.list_tests() == [1, 2, 3]
    assert length(ContextOnlyDefault.__info__(:functions)) == 3

    defmodule ContextExceptDefault do
      alias CrudryTest.Repo

      Crudry.Context.default(except: [:get!, :list, :delete])
      Crudry.Context.generate_functions(CrudryTest.Test)
    end

    assert ContextExceptDefault.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert ContextExceptDefault.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 2}}
    assert length(ContextExceptDefault.__info__(:functions)) == 9
  end

  test "underscore camelized schema name" do
    defmodule ContextUnderscore do
      alias CrudryTest.Repo
      Crudry.Context.generate_functions(CrudryTest.CamelizedSchemaName)
    end

    assert ContextUnderscore.create_camelized_schema_name(%{x: 2}) ==
             {:ok, %CrudryTest.CamelizedSchemaName{x: 2}}

    assert ContextUnderscore.list_camelized_schema_names() == [1, 2, 3]
  end

  test "pluralize correctly" do
    defmodule ContextPluralize do
      alias CrudryTest.Repo
      Crudry.Context.generate_functions(CrudryTest.Category)
    end

    assert ContextPluralize.create_category(%{x: 2}) == {:ok, %CrudryTest.Category{x: 2}}
    assert ContextPluralize.list_categories() == [1, 2, 3]
  end
end
