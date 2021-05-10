defmodule CrudryQueryTest do
  use ExUnit.Case

  alias Crudry.{Repo, User}

  @user %{username: "Chuck Norris", age: 60}
  @user2 %{username: "Will Smith", age: 60}
  @user3 %{username: "Aa", age: 40}
  @user4 %{username: "Zz", age: 66}
  @user5 %{username: "Crudry", age: 3}

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
      assert 0 == length(users)
    end

    test "ignores search term when it is nil" do
      initial_query = User
      query = Crudry.Query.search(initial_query, nil, [:username])

      users = Repo.all(query)

      assert initial_query == query
      assert 2 == length(users)
    end

    test "ignores search term when it is empty string" do
      initial_query = User
      query = Crudry.Query.search(initial_query, "", [:username])

      users = Repo.all(query)

      assert initial_query == query
      assert 2 == length(users)
    end
  end

  describe "list/2" do
    setup do
      UserContext.create_user(@user4)
      :ok
    end

    test "works with keyword list as parameter" do
      users =
        User
        |> Crudry.Query.list(limit: 1)
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

    test "works with multiple order bys" do
      pagination_params = %{order_by: [asc: :age, desc: :username]}

      users =
        User
        |> Crudry.Query.list(pagination_params)
        |> Repo.all()

      assert length(users) == 3
      assert Enum.map(users, & &1.username) == ["Will Smith", "Chuck Norris", "Zz"]
    end

    test "works with tuples with strings in order by" do
      pagination_params = %{order_by: [{"desc", "age"}, {"asc", "username"}]}

      users =
        User
        |> Crudry.Query.list(pagination_params)
        |> Repo.all()

      assert length(users) == 3
      assert Enum.map(users, & &1.username) == ["Zz", "Chuck Norris", "Will Smith"]
    end

    test "works with simple list in order by" do
      pagination_params = %{order_by: [:age, :username]}

      users =
        User
        |> Crudry.Query.list(pagination_params)
        |> Repo.all()

      assert length(users) == 3
      assert Enum.map(users, & &1.username) == ["Chuck Norris", "Will Smith", "Zz"]
    end

    test "works with simple list of strings in order by" do
      pagination_params = %{order_by: ["age", "username"]}

      users =
        User
        |> Crudry.Query.list(pagination_params)
        |> Repo.all()

      assert length(users) == 3
      assert Enum.map(users, & &1.username) == ["Chuck Norris", "Will Smith", "Zz"]
    end

    test "works with list of maps in order by" do
      pagination_params = %{order_by: [%{field: "age", order: :asc}, %{field: "username", order: :desc}]}

      users =
        User
        |> Crudry.Query.list(pagination_params)
        |> Repo.all()

      assert length(users) == 3
      assert Enum.map(users, & &1.username) == ["Will Smith", "Chuck Norris", "Zz"]
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
      # Removes Crudry
      pagination_params = %{limit: 10, offset: 1, order_by: "id", sorting_order: :desc}
      # Removes Zz
      filter_params = %{username: [@user.username, @user2.username, @user3.username]}
      # Removes Aa
      search_params = %{text: "i", fields: [:username]}

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
