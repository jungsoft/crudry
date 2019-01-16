defmodule Crudry.Context do
  @moduledoc """
  Generates CRUD functions to DRY Phoenix Contexts.

  Assumes `Ecto.Repo` is being used as the repository.

  ## Usage

  To generate CRUD functions for a given schema, simply do

      defmodule MyApp.MyContext do
        alias MyApp.Repo
        alias MyApp.MySchema
        require Crudry.Context

        Crudry.Context.generate_functions MySchema
      end

  And the context will become

      defmodule MyApp.MyContext do
        alias MyApp.Repo
        alias MyApp.MySchema
        require Crudry.Context

        def get_my_schema(id) do
          Repo.get(MySchema, id)
        end

        def get_my_schema_with_assocs(id, assocs) do
          Repo.get(MySchema, id)
          |> Repo.preload(assocs)
        end

        def get_my_schema!(id) do
          Repo.get!(MySchema, id)
        end

        def list_my_schemas() do
          Repo.all(MySchema)
        end

        def list_my_schemas(opts) do
          Crudry.Query.list(MySchema, opts)
          |> Repo.all()
        end

        def count_my_schemas(field \\\\ :id) do
          Repo.aggregate(MySchema, :count, field)
        end

        def search_my_schemas(search_term) do
          module_fields = MySchema.__schema__(:fields)

          Crudry.Query.search(MySchema, search_term, module_fields)
          |> Repo.all()
        end

        def filter_my_schemas(filters) do
          Crudry.Query.filter(MySchema, filters)
        end

        def create_my_schema(attrs) do
          %MySchema{}
          |> MySchema.changeset(attrs)
          |> Repo.insert()
        end

        def update_my_schema(%MySchema{} = my_schema, attrs) do
          my_schema
          |> MySchema.changeset(attrs)
          |> Repo.update()
        end

        def update_my_schema(id, attrs) do
          id
          |> get_my_schema()
          |> update_my_schema(attrs)
        end

        def update_my_schema_with_assocs(%MySchema{} = my_schema, attrs, assocs) do
          my_schema
          |> Repo.preload(assocs)
          |> MySchema.changeset(attrs)
          |> Repo.update()
        end

        def update_my_schema_with_assocs(id, attrs, assocs) do
          id
          |> get_my_schema()
          |> update_my_schema_with_assocs(attrs, assocs)
        end

        def delete_my_schema(%MySchema{} = my_schema) do
          my_schema
          |> Repo.delete()
        end

        def delete_my_schema(id) do
          id
          |> get_my_schema()
          |> delete_my_schema()
        end
      end
  """

  @doc """
  Sets default options for the context.

  ## Options

    * `:create` - the name of the changeset function used in the `create` function.
    Default to `:changeset`.

    * `:update` - the name of the changeset function used in the `update` function.
    Default to `:changeset`.

    * `:only` - list of functions to be generated. If not empty, functions not
    specified in this list are not generated. Default to `[]`.

    * `:except` - list of functions to not be generated. If not empty, only functions not specified
    in this list will be generated. Default to `[]`.

    The accepted values for `:only` and `:except` are: `[:get, :get!, :list, :search, :filter, :count, :create, :update, :delete]`.

  ## Examples

      iex> Crudry.Context.default create: :create_changeset, update: :update_changeset
      :ok

      iex> Crudry.Context.default only: [:create, :list]
      :ok

      iex> Crudry.Context.default except: [:get!, :list, :delete]
      :ok
  """
  defmacro default(opts) do
    Module.put_attribute(__CALLER__.module, :create_changeset, opts[:create])
    Module.put_attribute(__CALLER__.module, :update_changeset, opts[:update])
    Module.put_attribute(__CALLER__.module, :only, opts[:only])
    Module.put_attribute(__CALLER__.module, :except, opts[:except])
  end

  @doc """
  Generates CRUD functions for the `schema_module`.

  Custom options can be given. To see the available options, refer to the documenation of `Crudry.Context.default/1`.

  ## Examples

    Suppose we want to implement basic CRUD functionality for a User schema,
    exposed through an Accounts context:

      defmodule MyApp.Accounts do
        alias MyApp.Repo
        require Crudry.Context

        # Assuming Accounts.User implements a `changeset/2` function, used both to create and update a user.
        Crudry.Context.generate_functions Accounts.User
      end

    Now, all this functionality is available:

      Accounts.get_user(id)
      Accounts.get_user_with_assocs(id, assocs)
      Accounts.get_user!(id)
      Accounts.list_users()
      Accounts.list_users(opts)
      Accounts.count_users(field \\\\ :id)
      Accounts.search_users(search_term)
      Accounts.filter_users(filters)
      Accounts.create_user(attrs)
      Accounts.update_user(%User{}, attrs)
      Accounts.update_user(id, attrs)
      Accounts.update_user_with_assocs(%User{}, attrs, assocs)
      Accounts.update_user_with_assocs(id, attrs, assocs)
      Accounts.delete_user(%User{})
      Accounts.delete_user(id)
  """
  defmacro generate_functions(schema_module, opts \\ []) do
    opts = Keyword.merge(load_default(__CALLER__.module), opts)
    name = Helper.get_underscored_name(schema_module)

    for func <- [:get, :get!, :list, :search, :filter, :count, :create, :update, :delete, :check_assocs] do
      if func == :check_assocs || Helper.define_function?(func, opts[:only], opts[:except]) do
        ContextFunctionsGenerator.generate_function(func, name, schema_module, opts[:create], opts[:update])
      end
    end
  end

  # Load user-defined defaults or fall back to the library's default.
  defp load_default(module) do
    create_changeset = Module.get_attribute(module, :create_changeset)
    update_changeset = Module.get_attribute(module, :update_changeset)
    only = Module.get_attribute(module, :only)
    except = Module.get_attribute(module, :except)

    [
      create: create_changeset || :changeset,
      update: update_changeset || :changeset,
      only: only || [],
      except: except || []
    ]
  end
end
