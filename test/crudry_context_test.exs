defmodule CrudryContextTest do
  use ExUnit.Case
  doctest Crudry.Context

  alias Crudry.Repo
  alias Crudry.{Post, User}
  alias Ecto.Changeset

  @user %{username: "Chuck Norris"}
  @user2 %{username: "Will Smith"}
  @user3 %{username: "Sylvester Stallone"}
  @post %{title: "Chuck Norris threw a grenade and killed 50 people, then it exploded."}

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "Basic CRUD functions" do
    defmodule UserContext do
      alias Crudry.User

      Crudry.Context.generate_functions(User)
    end

    setup do
      assert {:ok, %{} = user1} = Repo.insert(User.changeset(%User{}, @user))
      assert {:ok, %{} = user2} = Repo.insert(User.changeset(%User{}, @user2))
      assert {:ok, %{} = user3} = Repo.insert(User.changeset(%User{}, @user3))
      assert {:ok, %{} = post} = Repo.insert(Post.changeset(%Post{}, %{title: "title", user_id: user1.id}))
      %{user1: user1, user2: user2, user3: user3, post: post}
    end

    test "create/1" do
      username = @user.username
      assert {:ok, %Crudry.User{username: ^username}} = UserContext.create_user(@user)
    end

    test "create!/1" do
      username = @user.username
      assert %Crudry.User{username: ^username} = UserContext.create_user!(@user)
    end

    test "list/0", %{user1: user1, user2: user2, user3: user3} do
      assert UserContext.list_users() == [user1, user2, user3]
    end

    test "list_with_assocs/1", %{user1: user1, user2: user2, user3: user3} do
      assert UserContext.list_users_with_assocs(:posts) == Repo.preload([user1, user2, user3], :posts)
    end

    test "list/1", %{user1: user1} do
      assert UserContext.list_users(limit: 1) == [user1]
    end

    test "list_with_assocs/2", %{user1: user1} do
      assert UserContext.list_users_with_assocs(:posts, limit: 1) == Repo.preload([user1], :posts)
    end

    test "search/1", %{user1: user1} do
      assert UserContext.search_users(user1.username) == [user1]
    end

    test "filter/0", %{user1: user1, user2: user2, user3: user3} do
      assert UserContext.filter_users(%{id: [user1.id, user2.id]}) == [user1, user2]
      assert UserContext.filter_users(%{username: @user3.username}) == [user3]
    end

    test "count/1" do
      assert UserContext.count_users(:id) == 3
    end

    test "get/1", %{user1: user1} do
      assert UserContext.get_user(user1.id) == user1
      assert UserContext.get_user(-1) == nil
    end

    test "get!/1", %{user1: user1} do
      assert UserContext.get_user!(user1.id) == user1
      assert_raise Ecto.NoResultsError, fn ->
        UserContext.get_user!(-1)
      end
    end

    test "get_by/1", %{user1: user1} do
      assert UserContext.get_user_by(username: user1.username) == user1
      assert UserContext.get_user_by(username: "inexistent") == nil
    end

    test "get_by!/1", %{user1: user1} do
      assert UserContext.get_user_by!(username: user1.username) == user1
      assert_raise Ecto.NoResultsError, fn ->
        UserContext.get_user_by!(username: "inexistent")
      end
    end

    test "get_with_assocs/2", %{user1: user1} do
      assert UserContext.get_user_with_assocs(user1.id, :posts) == Repo.preload(user1, :posts)
    end

    test "get_by_with_assocs/2", %{user1: user1} do
      assert UserContext.get_user_by_with_assocs([username: user1.username], :posts) == Repo.preload(user1, :posts)
    end

    test "get_with_assocs!/2", %{user1: user1} do
      assert UserContext.get_user_with_assocs!(user1.id, :posts) == Repo.preload(user1, :posts)

      assert_raise Ecto.NoResultsError, fn ->
        UserContext.get_user_with_assocs!(-1, :posts)
      end
    end

    test "get_by_with_assocs!/2", %{user1: user1} do
      assert UserContext.get_user_by_with_assocs!([username: user1.username], :posts) == Repo.preload(user1, :posts)

      assert_raise Ecto.NoResultsError, fn ->
        UserContext.get_user_by_with_assocs!([username: "inexistent"], :posts)
      end
    end

    test "update/2 with correct arguments", %{user1: user1} do
      assert {:ok, %User{username: "new"}} = UserContext.update_user(user1, %{username: "new"})
      assert {:ok, %User{username: "brand new"}} = UserContext.update_user(user1.id, %{username: "brand new"})
    end

    test "update/2 when record does not exist", %{user1: user1} do
      user_error = Map.put(user1, :id, -1)
      assert {:error, %Changeset{errors: errors}} = UserContext.update_user(user_error, %{username: "new"})
      assert errors == [user: {"not found", [stale: true]}]

      assert {:error, %Changeset{errors: errors}} = UserContext.update_user(-1, %{username: "new"})
      assert errors == [user: {"not found", [stale: true]}]
    end

    test "update!/2 with correct arguments", %{user1: user1} do
      assert %User{username: "new"} = UserContext.update_user!(user1, %{username: "new"})
      assert %User{username: "brand new"} = UserContext.update_user!(user1.id, %{username: "brand new"})
    end

    test "update!/2 when record does not exist", %{user1: user1} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        user_error = Map.put(user1, :id, -1)
        UserContext.update_user!(user_error, %{username: "new"})
      end

      assert_raise Ecto.NoResultsError, fn ->
        UserContext.update_user!(-1, %{username: "new"})
      end
    end

    test "update_with_assocs/3 with correct arguments", %{user2: user2, user3: user3} do
      assert {:ok, %User{username: "new", posts: [%Post{title: "post"}]}} =
        UserContext.update_user_with_assocs(user2, %{username: "new", posts: [%{title: "post"}]}, :posts)

      assert {:ok, %User{username: "new", posts: [%Post{title: "post"}]}} =
        UserContext.update_user_with_assocs(user3.id, %{username: "new", posts: [%{title: "post"}]}, :posts)
    end

    test "update_with_assocs/3 when record does not exist", %{user2: user2} do
      user_error = Map.put(user2, :id, -1)
      assert {:error, %Changeset{errors: errors}} = UserContext.update_user_with_assocs(user_error, %{username: "new", posts: [%{title: "post"}]}, :posts)
      assert errors == [user: {"not found", [stale: true]}]

      assert {:error, %Changeset{errors: errors}} = UserContext.update_user_with_assocs(-1, %{username: "new", posts: [%{title: "post"}]}, :posts)
      assert errors == [user: {"not found", [stale: true]}]
    end

    test "update_with_assocs!/3", %{user2: user2, user3: user3} do
      assert %User{username: "new", posts: [%Post{title: "post"}]} =
        UserContext.update_user_with_assocs!(user2, %{username: "new", posts: [%{title: "post"}]}, :posts)

      assert %User{username: "new", posts: [%Post{title: "post"}]} =
        UserContext.update_user_with_assocs!(user3.id, %{username: "new", posts: [%{title: "post"}]}, :posts)
    end

    test "delete/1 with correct arguments", %{user2: user2, user3: user3} do
      assert {:ok, user2} = UserContext.delete_user(user2)
      assert {:ok, user3} = UserContext.delete_user(user3.id)

      assert UserContext.get_user(user2.id) == nil
      assert UserContext.get_user(user3.id) == nil
    end

    test "delete/1 when record does not exist", %{user2: user2} do
      user_error = Map.put(user2, :id, -1)
      assert {:error, %Changeset{errors: errors}} = UserContext.delete_user(user_error)
      assert errors == [user: {"not found", [stale: true]}]

      assert {:error, %Changeset{errors: errors}} = UserContext.delete_user(-1)
      assert errors == [user: {"not found", [stale: true]}]
    end

    test "delete!/1", %{user2: user2, user3: user3} do
      assert user2 = UserContext.delete_user!(user2)
      assert user3 = UserContext.delete_user!(user3.id)

      assert UserContext.get_user(user2.id) == nil
      assert UserContext.get_user(user3.id) == nil
    end
  end

  describe "Delete with check constraints" do
    test "return changeset error when deleting a parent record with a child associated constraint" do
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
      defmodule ContextDeleteList do
        alias Crudry.Like
        alias Crudry.User
        alias Crudry.Post

        Crudry.Context.generate_functions(User, check_constraints_on_delete: [:posts, :likes])
        Crudry.Context.generate_functions(Post)
        Crudry.Context.generate_functions(Like)
      end

      assert {:ok, %{} = user} = ContextDeleteList.create_user(@user)

      assert {:ok, %{} = post} =
              ContextDeleteList.create_post(%{title: @post.title, user_id: user.id})

      assert {:ok, %{} = like} =
              ContextDeleteList.create_like(%{post_id: post.id, user_id: user.id})

      assert {:error, %Ecto.Changeset{}} = ContextDeleteList.delete_user(user)

      # Delete successfully after deleting children
      assert {:ok, %{}} = ContextDeleteList.delete_like(like.id)
      assert {:ok, %{}} = ContextDeleteList.delete_post(post.id)
      assert {:ok, %{}} = ContextDeleteList.delete_user(user.id)
    end
  end

  describe "Define custom changeset" do
    test "allow defining of create changeset" do
      defmodule ContextCreate do
        Crudry.Context.generate_functions(Crudry.User, create: :create_changeset)
      end

      assert {:ok, %User{username: "create_changeset"}} = ContextCreate.create_user(@user)
    end

    test "allow defining of update changeset" do
      defmodule ContextUpdate do
        Crudry.Context.generate_functions(Crudry.User, update: :update_changeset)
      end

      assert {:ok, %User{id: id}} = ContextUpdate.create_user(@user)
      assert {:ok, %User{username: "update_changeset"}} = ContextUpdate.update_user(id, @user)
    end

    test "allow defining of both changeset functions" do
      defmodule ContextBoth do
        alias Crudry.Repo

        Crudry.Context.generate_functions(Crudry.User,
          create: :create_changeset,
          update: :update_changeset
        )
      end

      assert {:ok, %User{id: id, username: "create_changeset"}} = ContextBoth.create_user(@user)
      assert {:ok, %User{username: "update_changeset"}} = ContextBoth.update_user(id, @user)
    end

    test "allow defining default changeset functions for context" do
      defmodule ContextDefault do
        Crudry.Context.default(create: :create_changeset, update: :update_changeset)
        Crudry.Context.generate_functions(Crudry.User)
      end

      assert {:ok, %User{id: id, username: "create_changeset"}} = ContextDefault.create_user(@user)
      assert {:ok, %User{username: "update_changeset"}} = ContextDefault.update_user(id, @user)
    end
  end

  describe "Define which functions are to be generated" do
    test "using only" do
      defmodule ContextOnly do
        Crudry.Context.generate_functions(Crudry.User, only: [:create, :list])
      end

      assert Enum.member?(ContextOnly.__info__(:functions), {:create_user, 1})
      assert Enum.member?(ContextOnly.__info__(:functions), {:list_users, 0})
      assert Enum.member?(ContextOnly.__info__(:functions), {:list_users, 1})
      assert Enum.member?(ContextOnly.__info__(:functions), {:list_users_with_assocs, 1})
      assert Enum.member?(ContextOnly.__info__(:functions), {:list_users_with_assocs, 2})
      refute Enum.member?(ContextOnly.__info__(:functions), {:get_user, 1})
    end

    test "using except" do
      defmodule ContextExcept do
        Crudry.Context.generate_functions(Crudry.User, except: [:get, :update, :list, :delete])
      end

      assert Enum.member?(ContextExcept.__info__(:functions), {:create_user, 1})
      refute Enum.member?(ContextExcept.__info__(:functions), {:get_user, 1})
      refute Enum.member?(ContextExcept.__info__(:functions), {:delete_user, 1})
    end

    test "using default only" do
      defmodule ContextOnlyDefault do
        Crudry.Context.default(only: [:create, :list])
        Crudry.Context.generate_functions(Crudry.User)
      end

      assert Enum.member?(ContextOnlyDefault.__info__(:functions), {:create_user, 1})
      assert Enum.member?(ContextOnlyDefault.__info__(:functions), {:list_users, 0})
      assert Enum.member?(ContextOnlyDefault.__info__(:functions), {:list_users, 1})
      assert Enum.member?(ContextOnlyDefault.__info__(:functions), {:list_users_with_assocs, 1})
      assert Enum.member?(ContextOnlyDefault.__info__(:functions), {:list_users_with_assocs, 2})
      refute Enum.member?(ContextOnlyDefault.__info__(:functions), {:get_user, 1})
    end

    test "using default except" do
      defmodule ContextExceptDefault do
        Crudry.Context.default(except: [:get, :update, :list, :delete])
        Crudry.Context.generate_functions(Crudry.User)
      end

      assert Enum.member?(ContextExceptDefault.__info__(:functions), {:create_user, 1})
      refute Enum.member?(ContextExceptDefault.__info__(:functions), {:get_user, 1})
      refute Enum.member?(ContextExceptDefault.__info__(:functions), {:delete_user, 1})
    end
  end

  describe "Generate function name" do
    test "underscore camelized schema name correctly" do
      defmodule ContextUnderscore do
        Crudry.Context.generate_functions(Crudry.CamelizedSchemaName)
      end

      assert {:ok, %Crudry.CamelizedSchemaName{content: "x"} = record} = ContextUnderscore.create_camelized_schema_name(%{content: "x"})
      assert ContextUnderscore.list_camelized_schema_names() == [record]
    end

    test "pluralize name from schema source" do
      defmodule ContextPluralize do
        Crudry.Context.generate_functions(Crudry.Category)
      end

      assert {:ok, %Crudry.Category{content: "x"} = record} = ContextPluralize.create_category(%{content: "x"})
      assert ContextPluralize.list_categories_schema_source() == [record]
    end
  end

  describe "Define stale error configuration" do
    test "using default" do
      defmodule DefaultStaleError do
        Crudry.Context.default(stale_error_field: :field, stale_error_message: "inexistent")
        Crudry.Context.generate_functions(Crudry.User)
      end

      assert {:error, %Changeset{errors: errors}} = DefaultStaleError.update_user(-1, %{username: "new"})
      assert errors == [field: {"inexistent", [stale: true]}]
    end

    test "for a schema" do
      defmodule StaleError do
        Crudry.Context.generate_functions(Crudry.User, stale_error_field: :field, stale_error_message: "inexistent")
      end

      assert {:error, %Changeset{errors: errors}} = StaleError.update_user(-1, %{username: "new"})
      assert errors == [field: {"inexistent", [stale: true]}]
    end
  end
end
