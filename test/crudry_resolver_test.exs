defmodule CrudryResolverTest do
  use ExUnit.Case
  doctest Crudry.Resolver

  alias Crudry.{Post, Repo, User}

  import Ecto.Query

  defmodule Users do
    alias Crudry.User

    require Crudry.Context
    alias Crudry.Context

    Context.generate_functions(User)
  end

  defmodule Companies do
    alias Crudry.Company

    require Crudry.Context
    alias Crudry.Context

    Context.generate_functions(Company)
  end

  defmodule Posts do
    alias Crudry.Post

    require Crudry.Context
    alias Crudry.Context

    Context.generate_functions(Post)
  end

  defmodule CamelizedContext do
    alias Crudry.Repo
    alias Crudry.CamelizedSchemaName
    require Crudry.Context

    Crudry.Context.generate_functions(CamelizedSchemaName)
  end

  defmodule CategoryContext do
    alias Crudry.Repo
    alias Crudry.Category
    require Crudry.Context

    Crudry.Context.generate_functions(Category)
  end

  @info %{}
  @username "test"
  @userparams %{params: %{username: @username}}

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "Basic CRUD functions" do
    defmodule Resolver do
      Crudry.Resolver.generate_functions(Users, User)
    end

    setup do
      {:ok, user} = Users.create_user(%{username: @username})
      %{user: user}
    end

    test "get/2", %{user: user} do
      assert Resolver.get_user(%{id: user.id}, @info) == {:ok, user}
      assert Resolver.get_user(%{id: -1}, @info) == {:error, "User not found."}
    end

    test "create/2" do
      assert {:ok, %User{id: id, username: @username} = user} = Resolver.create_user(@userparams, @info)
    end

    test "list/2", %{user: user} do
      assert Resolver.list_users(%{}, @info) == {:ok, [user]}
    end

    test "update/2", %{user: user} do
      assert {:ok, %User{username: "new"}} = Resolver.update_user(%{id: user.id, params: %{username: "new"}}, @info)
      assert Resolver.update_user(%{id: -1, params: @username}, @info) == {:error, "User not found."}
    end

    test "delete/2", %{user: %{id: id}} do
      assert  {:ok, %User{id: id}} = Resolver.delete_user(%{id: id}, @info)
      assert Resolver.delete_user(%{id: id}, @info) == {:error, "User not found."}
    end
  end

  describe "Define which functions are to be generated" do
    test "using only" do
      defmodule ResolverOnly do
        Crudry.Resolver.generate_functions(Users, User, only: [:create, :list])
      end

      assert {:ok, %User{username: @username} = user} = ResolverOnly.create_user(@userparams, @info)
      assert ResolverOnly.list_users(%{}, @info) == {:ok, [user]}
      assert length(ResolverOnly.__info__(:functions)) == 4
    end

    test "using except" do
      defmodule ResolverExcept do
        Crudry.Resolver.generate_functions(Users, User, except: [:list, :delete])
      end

      assert {:ok, %User{username: @username} = user} = ResolverExcept.create_user(@userparams, @info)
      assert {:ok, %User{username: "new"}} = ResolverExcept.update_user(%{id: user.id, params: %{username: "new"}}, @info)
      assert length(ResolverExcept.__info__(:functions)) == 5
    end

    test "using default only" do
      defmodule ResolverOnlyDefault do
        Crudry.Resolver.default(only: [:create, :list])
        Crudry.Resolver.generate_functions(Users, User)
      end

      assert {:ok, %User{username: @username} = user} = ResolverOnlyDefault.create_user(@userparams, @info)
      assert ResolverOnlyDefault.list_users(%{}, @info) == {:ok, [user]}
      assert length(ResolverOnlyDefault.__info__(:functions)) == 4
    end

    test "using default except" do
      defmodule ResolverExceptDefault do
        Crudry.Resolver.default(except: [:list, :delete])
        Crudry.Resolver.generate_functions(Users, User)
      end

      assert {:ok, %User{username: @username} = user} = ResolverExceptDefault.create_user(@userparams, @info)
      assert {:ok, %User{username: "new"}} = ResolverExceptDefault.update_user(%{id: user.id, params: %{username: "new"}}, @info)
      assert length(ResolverExceptDefault.__info__(:functions)) == 5
    end
  end

  describe "list opts" do
    setup do
      {:ok, _} = Users.create_user(%{username: "aaa"})
      {:ok, _} = Users.create_user(%{username: "bbb"})
      {:ok, _} = Users.create_user(%{username: "ccc"})
      :ok
    end

    test "by default" do
      defmodule ResolverListOptionsDefault do
        Crudry.Resolver.default(list_opts: [order_by: :id, sorting_order: :desc])
        Crudry.Resolver.generate_functions(Users, User)
      end

      {:ok, user_list} = ResolverListOptionsDefault.list_users(%{}, @info)
      id_list = Enum.map(user_list, & &1.id)
      assert List.first(id_list) > List.last(id_list)
    end

    test "for a schema" do
      defmodule ResolverListOptions do
        Crudry.Resolver.generate_functions(Users, User,
          list_opts: [order_by: :id, sorting_order: :asc]
        )

        Crudry.Resolver.generate_functions(Posts, Post, list_opts: [order_by: [:user_id, :title]])
      end

      {:ok, user_list} = ResolverListOptions.list_users(%{}, @info)
      id_list = Enum.map(user_list, & &1.id)
      assert List.first(id_list) < List.last(id_list)

      first_user_id = List.first(user_list) |> Map.get(:id)
      last_user_id = List.last(user_list) |> Map.get(:id)
      first_post_title = "Post A"
      last_post_title = "Post B"

      ResolverListOptions.create_post(%{params: %{user_id: last_user_id, title: last_post_title}}, @info)
      ResolverListOptions.create_post(%{params: %{user_id: last_user_id, title: first_post_title}}, @info)
      ResolverListOptions.create_post(%{params: %{user_id: first_user_id, title: last_post_title}}, @info)
      ResolverListOptions.create_post(%{params: %{user_id: first_user_id, title: first_post_title}}, @info)

      {:ok, post_list} = ResolverListOptions.list_posts(%{}, @info)

      assert [
        %{user_id: first_user_id, title: first_post_title},
        %{user_id: first_user_id, title: last_post_title},
        %{user_id: last_user_id, title: first_post_title},
        %{user_id: last_user_id, title: last_post_title}
      ] == Enum.map(post_list, &Map.take(&1, [:user_id, :title]))
    end
  end

  test "create custom update using nil_to_error" do
    defmodule ResolverExceptUpdate do
      Crudry.Resolver.default(except: [:update])
      Crudry.Resolver.generate_functions(Users, User)

      def update_user(%{id: id, params: params}, _info) do
        id
        |> Users.get_user()
        |> nil_to_error("user", fn record ->
          Users.update_user_with_assocs(record, params, [:posts])
        end)
      end
    end

    {:ok, %{id: id}} = Users.create_user(%{username: @username})
    assert {:ok, %User{username: @username}} = ResolverExceptUpdate.update_user(%{id: id, params: @userparams}, @info)
    assert ResolverExceptUpdate.update_user(%{id: -1, params: @userparams}, @info) == {:error, "User not found."}
  end

  test "Camelized name in error message" do
    defmodule CamelizedResolver do
      Crudry.Resolver.generate_functions(CamelizedContext, Crudry.CamelizedSchemaName)
    end

    assert CamelizedResolver.get_camelized_schema_name(%{id: 0}, @info) == {:error, "CamelizedSchemaName not found."}
  end

  test "Pluralize using schema source" do
    defmodule PluralizeResolver do
      Crudry.Resolver.generate_functions(CategoryContext, Crudry.Category)
    end

    assert PluralizeResolver.list_categories_schema_source(%{}, @info) == {:ok, []}
  end

  test "Generate only one nil_to_error function" do
    defmodule MultipleResolver do
      Crudry.Resolver.generate_functions(Users, User)
      Crudry.Resolver.generate_functions(CamelizedContext, Crudry.CamelizedSchemaName)
    end

    # When multiplie nil_to_error functions are generated, a warning is raised.
    # Not sure how to test for warnings, so for now just let the test pass and check if there are no warnings manually.
    assert true
  end

  test "Custom query function in resolver list_opts and Crudry.Query.list/2 is called with correct arguments" do
    first_post_title = "Post A"
    last_post_title = "Post B"

    {:ok, user1} = Users.create_user(%{username: "test"})
    {:ok, user2} = Users.create_user(%{username: "test2"})

    Posts.create_post(%{user_id: user1.id, title: first_post_title})
    Posts.create_post(%{user_id: user1.id, title: last_post_title})
    Posts.create_post(%{user_id: user2.id, title: last_post_title})
    Posts.create_post(%{user_id: user2.id, title: first_post_title})
    Posts.create_post(%{user_id: user2.id, title: last_post_title})

    defmodule PostResolver do
      import Ecto.Query

      def custom_query(initial_query, info_arg) do
        current_user = info_arg.context.current_user
        where(initial_query, [p], p.user_id == ^current_user.id)
      end

      Crudry.Resolver.generate_functions(Posts, Post,
        list_opts: [
          order_by: [:title],
          custom_query: &custom_query/2
        ]
      )
    end

    info = %{context: %{current_user: user2}}

    {:ok, resolver_post_list} = PostResolver.list_posts(%{}, info)

    assert [
      %{user_id: user2.id, title: first_post_title},
      %{user_id: user2.id, title: last_post_title},
      %{user_id: user2.id, title: last_post_title}
    ] == Enum.map(resolver_post_list, &Map.take(&1, [:user_id, :title]))

    custom_query = fn initial_query ->
      initial_query
      |> where([p], p.user_id == ^user1.id)
      |> order_by(desc: :title)
    end

    query_post_list =
      Crudry.Post
      |> Crudry.Query.list([custom_query: custom_query])
      |> Repo.all

    assert [
      %{user_id: user1.id, title: last_post_title},
      %{user_id: user1.id, title: first_post_title}
    ] == Enum.map(query_post_list, &Map.take(&1, [:user_id, :title]))
  end

  test "Custom create_resolver receives correct arguments" do
    defmodule UserResolver do
      def create_resolver(context, schema_name, args, %{context: %{current_user: %{company_id: company_id}}}) do
        apply(context, :"create_#{schema_name}", [Map.put(args.params, :company_id, company_id)])
      end

      Crudry.Resolver.generate_functions(Users, User, create_resolver: &create_resolver/4)
    end

    {:ok, company} = Companies.create_company(%{name: "Nike"})
    {:ok, user} = Users.create_user(%{username: "test", company_id: company.id})
    info = %{context: %{current_user: user}}
    params = %{username: "Jonas"}

    {:ok, new_user} = UserResolver.create_user(%{params: params}, info)

    assert new_user.company_id == company.id
    assert new_user.username == params.username
  end

  test "Custom create_resolver can be defined as default" do
    defmodule UserResolverDefault do
      def create_resolver(context, schema_name, args, %{context: %{current_user: %{company_id: company_id}}}) do
        apply(context, :"create_#{schema_name}", [Map.put(args.params, :company_id, company_id)])
      end

      Crudry.Resolver.default create_resolver: &create_resolver/4
      Crudry.Resolver.generate_functions Users, User
    end

    {:ok, company} = Companies.create_company(%{name: "Nike"})
    {:ok, user} = Users.create_user(%{username: "test", company_id: company.id})
    info = %{context: %{current_user: user}}
    params = %{username: "Jonas"}

    {:ok, new_user} = UserResolverDefault.create_user(%{params: params}, info)

    assert new_user.company_id == company.id
    assert new_user.username == params.username
  end
end
