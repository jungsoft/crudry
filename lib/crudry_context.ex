defmodule Crudry.Context do
  @moduledoc """
  Generates CRUD functions to DRY Phoenix Contexts.

  * Assumes `Ecto.Repo` is being used as the repository.

  * Uses the Ecto Schema source name to generate the pluralized name for the functions, and the module name to generate the singular name.

    This follows the same pattern as the [Mix.Tasks.Phx.Gen.Context](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Context.html), so it should be straightforward to replace Phoenix's auto-generated functions with Crudry.

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

        def get_my_schema_with_assocs!(id, assocs) do
          Repo.get!(MySchema, id)
          |> Repo.preload(assocs)
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
          |> Repo.all()
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
          |> Ecto.Changeset.change()
          |> check_assocs([])
          |> Repo.delete()
        end

        def delete_my_schema(id) do
          id
          |> get_my_schema()
          |> delete_my_schema()
        end

        # Function to check no_assoc_constraints
        defp check_assocs(changeset, nil), do: changeset
        defp check_assocs(changeset, constraints) do
          Enum.reduce(constraints, changeset, fn i, acc -> Ecto.Changeset.no_assoc_constraint(acc, i) end)
        end
      end

  Now, suppose the changeset for create and update are different,
  and we want to delete the record only if the association `has_many :assocs` is empty:

      defmodule MyApp.MyContext do
        alias MyApp.Repo
        alias MyApp.MySchema
        require Crudry.Context

        Crudry.Context.generate_functions MySchema,
          create: :create_changeset,
          update: :update_changeset,
          check_constraints_on_delete: [:assocs]
      end

  """

  @all_functions ~w(get list count search filter create update delete)a
  # Always generate helper functions since they are used in the other generated functions
  @helper_functions ~w(check_assocs)a

  @doc """
  Sets default options for the context.

  ## Options

    * `:create` - the name of the changeset function used in the `create` function.
    Defaults to `:changeset`.

    * `:update` - the name of the changeset function used in the `update` function.
    Defaults to `:changeset`.

    * `:only` - list of functions to be generated. If not empty, functions not
    specified in this list are not generated. Defaults to `[]`.

    * `:except` - list of functions to not be generated. If not empty, only functions not specified
    in this list will be generated. Defaults to `[]`.

    * `:stale_error_field` - The field where stale errors will be added in the returning changeset.
    This is also used when updating or deleting by ID and the record is not found.
    See [Repo.Update options](https://hexdocs.pm/ecto/Ecto.Repo.html#c:update/2-options) for more information.
    Defaults to `:id`

    * `:stale_error_message` - The message to add to the configured :stale_error_field when stale errors happen. Defaults to "not found".

    The accepted values for `:only` and `:except` are: `#{inspect(@all_functions)}`.

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
    Module.put_attribute(__CALLER__.module, :stale_error_field, opts[:stale_error_field])
    Module.put_attribute(__CALLER__.module, :stale_error_message, opts[:stale_error_message])
  end

  @doc """
  Generates CRUD functions for the `schema_module`.

  Custom options can be given. To see the available options, refer to the documenation of `Crudry.Context.default/1`.
  There is also one extra option that cannot be set by default:

    * `check_constraints_on_delete` - list of associations that must be empty to allow deletion.
  `Ecto.Changeset.no_assoc_constraint` will be called for each association before deleting. Default to `[]`.

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
      Accounts.get_user_with_assocs!(id, assocs)
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
    pluralized_name = Helper.get_pluralized_name(schema_module, __CALLER__)

    for func <- Helper.get_functions_to_be_generated(__CALLER__.module, @all_functions, @helper_functions, opts) do
      ContextFunctionsGenerator.generate_function(func, name, pluralized_name, schema_module, opts)
    end
  end

  # Load user-defined defaults or fall back to the library's default.
  defp load_default(module) do
    create_changeset = Module.get_attribute(module, :create_changeset)
    update_changeset = Module.get_attribute(module, :update_changeset)
    only = Module.get_attribute(module, :only)
    except = Module.get_attribute(module, :except)
    stale_error_field = Module.get_attribute(module, :stale_error_field)
    stale_error_message = Module.get_attribute(module, :stale_error_message)

    [
      create: create_changeset || :changeset,
      update: update_changeset || :changeset,
      only: only || [],
      except: except || [],
      check_constraints_on_delete: [],
      stale_error_field: stale_error_field || :id,
      stale_error_message: stale_error_message || "not found"
    ]
  end
end
