defmodule CrudryQueryTest do
  use ExUnit.Case

  alias Crudry.{Repo, User}

  @user %{username: "Chuck Norris"}
  @user2 %{username: "Will Smith"}
  @user3 %{username: "Aa"}
  @user4 %{username: "Zz"}
  @user5 %{username: "Crudry"}

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

    test "ignores search term when it is nil" do
      users =
        User
        |> Crudry.Query.search(nil, [:username])
        |> Repo.all()

      assert length(users) == 2
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

  describe "combinate functions" do
    setup do
      UserContext.create_user(@user3)
      UserContext.create_user(@user4)
      UserContext.create_user(@user5)
      :ok
    end

    test "to do pagination" do
      pagination_params = %{limit: 10, offset: 1, order_by: "id", sorting_order: :desc} # Removes Crudry
      filter_params = %{username: [@user.username, @user2.username, @user3.username]} # Removes Zz
      search_params = %{text: "i", fields: [:username]} # Removes Aa

      users =
        User
        |> Crudry.Query.filter(filter_params)
        |> Crudry.Query.list(pagination_params)
        |> Crudry.Query.search(search_params.text, search_params.fields)
        |> Repo.all()

      assert length(users) == 2
      assert Enum.map(users, & &1.username) == ["Will Smith", "Chuck Norris"]
    end
  end
end
