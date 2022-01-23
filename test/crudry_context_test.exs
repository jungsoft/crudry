defmodule CrudryContextTest do
  use ExUnit.Case
  doctest Crudry.Context

  alias Crudry.Repo
  alias Crudry.{Post, User}

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

    test "get/2", %{user1: user1} do
      assert UserContext.get_user(user1.id, [assocs: :posts]) == Repo.preload(user1, :posts)
    end

    test "get!/2", %{user1: user1} do
      assert UserContext.get_user!(user1.id, [assocs: :posts]) == Repo.preload(user1, :posts)

      assert_raise Ecto.NoResultsError, fn ->
        UserContext.get_user!(-1, [:posts])
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

    test "get_by/2", %{user1: user1} do
      assert UserContext.get_user_by([username: user1.username], [assocs: :posts]) == Repo.preload(user1, :posts)
    end

    test "get_by!/2", %{user1: user1} do
      assert UserContext.get_user_by!([username: user1.username], [assocs: :posts]) == Repo.preload(user1, :posts)

      assert_raise Ecto.NoResultsError, fn ->
        UserContext.get_user_by!([username: "inexistent"], [:posts])
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
    end

    test "update!/2 with correct arguments", %{user1: user1} do
      assert %User{username: "new"} = UserContext.update_user!(user1, %{username: "new"})
    end

    test "update_with_assocs/3 with correct arguments", %{user2: user2} do
      assert {:ok, %User{username: "new", posts: [%Post{title: "post"}]}} =
        UserContext.update_user_with_assocs(user2, %{username: "new", posts: [%{title: "post"}]}, :posts)
    end

    test "update_with_assocs!/3", %{user2: user2} do
      assert %User{username: "new", posts: [%Post{title: "post"}]} =
        UserContext.update_user_with_assocs!(user2, %{username: "new", posts: [%{title: "post"}]}, :posts)
    end

    test "delete/1 with correct arguments", %{user2: user2} do
      assert {:ok, user2} = UserContext.delete_user(user2)
      assert UserContext.get_user(user2.id) == nil
    end

    test "delete!/1", %{user2: user2} do
      assert user2 = UserContext.delete_user!(user2)
      assert UserContext.get_user(user2.id) == nil
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
      assert {:ok, %{} = _post} = ContextDelete.create_post(%{title: @post.title, user_id: user.id})
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
      assert {:ok, %{}} = ContextDeleteList.delete_like(like)
      assert {:ok, %{}} = ContextDeleteList.delete_post(post)
      assert {:ok, %{}} = ContextDeleteList.delete_user(user)
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

      assert {:ok, %User{} = user} = ContextUpdate.create_user(@user)
      assert {:ok, %User{username: "update_changeset"}} = ContextUpdate.update_user(user, @user)
    end

    test "allow defining of both changeset functions" do
      defmodule ContextBoth do
        alias Crudry.Repo

        Crudry.Context.generate_functions(Crudry.User,
          create: :create_changeset,
          update: :update_changeset
        )
      end

      assert {:ok, %User{username: "create_changeset"} = user} = ContextBoth.create_user(@user)
      assert {:ok, %User{username: "update_changeset"}} = ContextBoth.update_user(user, @user)
    end

    test "allow defining default changeset functions for context" do
      defmodule ContextDefault do
        Crudry.Context.default(create: :create_changeset, update: :update_changeset)
        Crudry.Context.generate_functions(Crudry.User)
      end

      assert {:ok, %User{username: "create_changeset"} = user} = ContextDefault.create_user(@user)
      assert {:ok, %User{username: "update_changeset"}} = ContextDefault.update_user(user, @user)
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

  describe "Define Repo" do
    test "by default" do
      defmodule ContextRepoDefault do
        alias Crudry.User

        Crudry.Context.default repo: Crudry.Repo
        Crudry.Context.generate_functions(User)
      end

      username = @user.username
      assert {:ok, %Crudry.User{username: ^username}} = ContextRepoDefault.create_user(@user)
    end

    test "by schema" do
      defmodule ContextRepoSchema do
        alias Crudry.User

        Crudry.Context.generate_functions(User, repo: Crudry.Repo)
      end

      username = @user.username
      assert {:ok, %Crudry.User{username: ^username}} = ContextRepoSchema.create_user(@user)
    end
  end
end
