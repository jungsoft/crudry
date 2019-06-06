defmodule CrudryQueryTest do
  use ExUnit.Case

  alias Crudry.{Repo, User}

  @user %{username: "Chuck Norris"}
  @user2 %{username: "Will Smith"}

  defmodule UserContext do
    require Crudry.Context
    Crudry.Context.generate_functions(User)
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    UserContext.create_user(@user)
    UserContext.create_user(@user2)
    :ok
  end

  describe "search/3" do
    test "does not affect other where in initial query" do
      users =
        User
        |> Crudry.Query.filter(%{username: @user.username})
        |> Crudry.Query.search(@user2.username, [:username])
        |> Repo.all()

      # Since we first filtered out all users that don't have @user.username,
      # the search for @user2.username shouldn't find anything
      assert length(users) == 0
    end
  end

  describe "list/2" do
    test "works with keyword list as parameter" do
      users =
        User
        |> Crudry.Query.list([limit: 1])
        |> Repo.all()

      assert length(users) == 1
    end

    test "works with map as parameter" do
      users =
        User
        |> Crudry.Query.list(%{limit: 1})
        |> Repo.all()

      assert length(users) == 1
    end
  end
end
