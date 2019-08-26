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

  And the context will have all these functions available:

      defmodule MyApp.MyContext do
        alias MyApp.Repo
        alias MyApp.MySchema
        require Crudry.Context

        ## Get functions

        def get_my_schema(id) do
          Repo.get(MySchema, id)
        end

        def get_my_schema!(id) do
          Repo.get!(MySchema, id)
        end

        def get_my_schema_with_assocs(id, assocs) do
          MySchema
          |> Repo.get(id)
          |> Repo.preload(assocs)
        end

        def get_my_schema_with_assocs!(id, assocs) do
          MySchema
          |> Repo.get!(id)
          |> Repo.preload(assocs)
        end

        def get_my_schema_by(clauses) do
          Repo.get_by(MySchema, clauses)
        end

        def get_my_schema_by!(clauses) do
          Repo.get_by!(MySchema, clauses)
        end

        def get_my_schema_by_with_assocs(clauses, assocs) do
          MySchema
          |> Repo.get_by(clauses)
          |> Repo.preload(assocs)
        end

        def get_my_schema_by_with_assocs!(clauses, assocs) do
          MySchema
          |> Repo.get_by!(clauses)
          |> Repo.preload(assocs)
        end

        ## List functions

        def list_my_schemas() do
          Repo.all(MySchema)
        end

        def list_my_schemas(opts) do
          MySchema
          |> Crudry.Query.list(opts)
          |> Repo.all()
        end

        def list_my_schemas_with_assocs(assocs) do
          MySchema
          |> Repo.all()
          |> Repo.preload(assocs)
        end

        def list_my_schemas_with_assocs(assocs, opts) do
          MySchema
          |> Crudry.Query.list(opts)
          |> Repo.all()
          |> Repo.preload(assocs)
        end

        def filter_my_schemas(filters) do
          MySchema
          |> Crudry.Query.filter(filters)
          |> Repo.all()
        end

        def search_my_schemas(search_term) do
          module_fields = MySchema.__schema__(:fields)

          MySchema
          |> Crudry.Query.search(search_term, module_fields)
          |> Repo.all()
        end

        def count_my_schemas(field \\\\ :id) do
          Repo.aggregate(MySchema, :count, field)
        end

        ## Create functions

        def create_my_schema(attrs) do
          %MySchema{}
          |> MySchema.changeset(attrs)
          |> Repo.insert()
        end

        def create_my_schema!(attrs) do
          %MySchema{}
          |> MySchema.changeset(attrs)
          |> Repo.insert!()
        end

        ## Update functions

        def update_my_schema(%MySchema{} = my_schema, attrs) do
          my_schema
          |> MySchema.changeset(attrs)
          |> Repo.update()
        end

        def update_my_schema!(%MySchema{} = my_schema, attrs) do
          my_schema
          |> MySchema.changeset(attrs)
          |> Repo.update!()
        end

        def update_my_schema_with_assocs(%MySchema{} = my_schema, attrs, assocs) do
          my_schema
          |> Repo.preload(assocs)
          |> MySchema.changeset(attrs)
          |> Repo.update()
        end

        def update_my_schema_with_assocs!(%MySchema{} = my_schema, attrs, assocs) do
          my_schema
          |> Repo.preload(assocs)
          |> MySchema.changeset(attrs)
          |> Repo.update!()
        end

        ## Delete functions

        def delete_my_schema(%MySchema{} = my_schema) do
          my_schema
          |> Ecto.Changeset.change()
          |> check_assocs([])
          |> Repo.delete()
        end

        def delete_my_schema!(%MySchema{} = my_schema) do
          my_schema
          |> Ecto.Changeset.change()
          |> check_assocs([])
          |> Repo.delete!()
        end

        # Function to check no_assoc_constraints, always generated.
        defp check_assocs(changeset, nil), do: changeset
        defp check_assocs(changeset, constraints) do
          Enum.reduce(constraints, changeset, fn i, acc -> Ecto.Changeset.no_assoc_constraint(acc, i) end)
        end
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
    Module.put_attribute(__CALLER__.module, :repo, opts[:repo])
  end

  @doc """
  Generates CRUD functions for the `schema_module`.

  Custom options can be given. To see the available options, refer to the documenation of `Crudry.Context.default/1`.
  There is also one extra option that cannot be set by default:

    * `check_constraints_on_delete` - list of associations that must be empty to allow deletion.
  `Ecto.Changeset.no_assoc_constraint` will be called for each association before deleting. Defaults to `[]`.

  ## Examples

    Suppose we want to implement basic CRUD functionality for a User schema,
    exposed through an Accounts context:

      defmodule MyApp.Accounts do
        alias MyApp.Repo
        require Crudry.Context

        # Assuming Accounts.User implements a `changeset/2` function, used both to create and update a user.
        Crudry.Context.generate_functions Accounts.User
      end

    Now, suppose the changeset for create and update are different, and we want to delete the record only if the association `has_many :assocs` is empty:

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
    repo = Module.get_attribute(module, :repo)

    [
      create: create_changeset || :changeset,
      update: update_changeset || :changeset,
      only: only || [],
      except: except || [],
      check_constraints_on_delete: [],
      repo: repo,
    ]
  end
end
