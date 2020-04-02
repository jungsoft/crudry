defmodule Crudry.Resolver do
  @moduledoc """
  Generates CRUD functions to DRY Absinthe Resolvers.

  Requires a previously generated Context.

  ## Usage

  To generate CRUD functions for a given schema resolver, simply do

      defmodule MyApp.MyResolver do
        alias MyApp.Repo
        alias MyApp.MyContext
        alias MyApp.MySchema
        require Crudry.Resolver

        Crudry.Resolver.generate_functions MyContext, MySchema
      end

  And the resolver will have all these functions available:

      defmodule MyApp.MyResolver do
        alias MyApp.Repo
        alias MyApp.MyContext
        alias MyApp.MySchema
        require Crudry.Resolver

        def get_my_schema(%{id: id}, _info) do
          id
          |> MyContext.get_my_schema()
          |> nil_to_error("my_schema", fn record -> {:ok, record} end)
        end

        def list_my_schemas(_args, _info) do
          {:ok, MyContext.list_my_schemas([])}
        end

        def create_my_schema(%{params: params}, _info) do
          MyContext.create_my_schema(params)
        end

        def update_my_schema(%{id: id, params: params}, _info) do
          id
          |> MyContext.get_my_schema()
          |> nil_to_error("my_schema", fn record -> MyContext.update_my_schema(record, params) end)
        end

        def delete_my_schema(%{id: id}, _info) do
          id
          |> MyContext.get_my_schema()
          |> nil_to_error("my_schema", fn record -> MyContext.delete_my_schema(record) end)
        end

        # If `result` is `nil`, return an error. Otherwise, apply `func` to the `result`.
        def nil_to_error(result, name, func) do
          case result do
            nil -> {:error, %{message: "not found", schema: name}}
            %{} = record -> func.(record)
          end
        end

        def add_info_to_custom_query(custom_query, info) do
          fn initial_query -> custom_query.(initial_query, info) end
        end
      end
  """

  @all_functions ~w(get list create update delete)a
  # Always generate helper functions since they are used in the other generated functions
  @helper_functions ~w(nil_to_error add_info_to_custom_query)a

  @doc """
  Sets default options for the resolver.

  ## Options

    * `:only` - list of functions to be generated. If not empty, functions not
    specified in this list are not generated. Defaults to `[]`.

    * `:except` - list of functions to not be generated. If not empty, only functions not specified
    in this list will be generated. Defaults to `[]`.

    * `list_opts` - options for the `list` function. See available options in `Crudry.Query.list/2`. Defaults to `[]`.

    * `create_resolver` - custom `create` resolver function with arity 4. Receives the following arguments: [Context, schema_name, args, info]. Defaults to `nil`.

    * `not_found_message` - custom message for the `nil_to_error` function. Defaults to `"not found"`.

    * `primary_key` - custom primary key argument to use in get, update and delete resolvers. Defaults to `:id`.

  Note: in `list_opts`, `custom_query` will receive absinthe's info as the second argument and, therefore, must have arity 2. See example in `generate_functions/3`.

  The accepted values for `:only` and `:except` are: `#{inspect(@all_functions)}`.

  ## Examples

      iex> Crudry.Resolver.default only: [:create, :list]
      :ok

      iex> Crudry.Resolver.default except: [:get!, :list, :delete]
      :ok

      iex> Crudry.Resolver.default list_opts: [order_by: :id]
      :ok

      iex> Crudry.Resolver.default list_opts: [custom_query: &scope_list/2]
      :ok
  """
  defmacro default(opts) do
    Module.put_attribute(__CALLER__.module, :only, opts[:only])
    Module.put_attribute(__CALLER__.module, :except, opts[:except])
    Module.put_attribute(__CALLER__.module, :list_opts, opts[:list_opts])
    Module.put_attribute(__CALLER__.module, :create_resolver, opts[:create_resolver])
    Module.put_attribute(__CALLER__.module, :update_resolver, opts[:update_resolver])
    Module.put_attribute(__CALLER__.module, :delete_resolver, opts[:delete_resolver])
    Module.put_attribute(__CALLER__.module, :not_found_message, opts[:not_found_message])
    Module.put_attribute(__CALLER__.module, :primary_key, opts[:primary_key])
  end

  @doc """
  Generates CRUD functions for the `schema_module` resolver.

  Custom options can be given. To see the available options, refer to the documenation of `Crudry.Resolver.default/1`, noting that the `not_found_message` must only be configured using `default/1`.

  ## Examples

  ### Overriding functions

    To define a custom function, add it to `except` and define your own. In the following example, the schema is updated with its association.

      defmodule MyApp.Resolver do
        alias MyApp.Repo
        alias MyApp.MyContext
        alias MyApp.MySchema
        require Crudry.Resolver

        Crudry.Resolver.generate_functions MyContext, MySchema, except: [:update]

        def update_my_schema(%{id: id, params: params}, _info) do
          id
          |> MyContext.get_my_schema()
          |> nil_to_error("My Schema", fn record -> MyContext.update_my_schema_with_assocs(record, params, [:assoc]) end)
        end
      end

    By using the `nil_to_error` function, we DRY the nil checking and also ensure the error message is the same as the other auto-generated functions.

  ### Custom create resolver

    It's possible to define a custom create function, useful when all functions in a resolver change the data in the same way before creating:

      defmodule MyApp.Resolver do
        alias MyApp.Repo
        alias MyApp.MyContext
        alias MyApp.MySchema
        require Crudry.Resolver

        Crudry.Resolver.default create_resolver: &create_resolver/4)
        Crudry.Resolver.generate_functions MyContext, MySchema
        Crudry.Resolver.generate_functions MyContext, OtherSchema

        def create_resolver(context, schema_name, args, %{context: %{current_user: %{company_id: company_id}}}) do
          apply(context, :"create_\#{schema_name}", [Map.put(args.params, :company_id, company_id)])
        end
      end

    Now when creating `MySchema` and `OtherSchema`, the custom function will put the current user's `company_id` in the params.

  ### Custom query

    It's also possible to use a custom query that has access to absinthe's `info`:

      defmodule MyApp.Resolver do
        alias MyApp.Repo
        alias MyApp.MyContext
        alias MyApp.MySchema
        require Crudry.Resolver

        def scope_list(MySchema, %{context: %{current_user: current_user}} = _info) do
          where(MySchema, [p], p.user_id == ^current_user.id)
        end

        Crudry.Resolver.generate_functions MyContext, MySchema, list_opts: [custom_query: &scope_list/2]
      end

    With this, the list function will effectively become:

      def list_my_schemas(_args, info) do
        {:ok, MyContext.list_my_schemas(custom_query: add_info_to_custom_query(scope_list, info))}
      end

    See `Crudry.Query.list/2` for further information on the `custom_query` option.
  """
  defmacro generate_functions(context, schema_module, opts \\ []) do
    if Keyword.has_key?(opts, :not_found_message), do: raise "not_found_message can only be configured using default/1"

    opts = Keyword.merge(load_default(__CALLER__.module), opts)
    name = Helper.get_underscored_name(schema_module)
    pluralized_name = Helper.get_pluralized_name(schema_module, __CALLER__)
    _ = String.to_atom(name)

    for func <- Helper.get_functions_to_be_generated(__CALLER__.module, @all_functions, @helper_functions, opts) do
      ResolverFunctionsGenerator.generate_function(func, name, pluralized_name, context, opts)
    end
  end

  # Load user-defined defaults or fall back to the library's default.
  defp load_default(module) do
    only = Module.get_attribute(module, :only)
    except = Module.get_attribute(module, :except)
    list_opts = Module.get_attribute(module, :list_opts)
    create_resolver = Module.get_attribute(module, :create_resolver)
    update_resolver = Module.get_attribute(module, :update_resolver)
    delete_resolver = Module.get_attribute(module, :delete_resolver)
    not_found_message = Module.get_attribute(module, :not_found_message)
    primary_key = Module.get_attribute(module, :primary_key)

    [
      only: only || [],
      except: except || [],
      list_opts: list_opts || [],
      create_resolver: create_resolver || nil,
      update_resolver: update_resolver || nil,
      delete_resolver: delete_resolver || nil,
      not_found_message: not_found_message || "not found",
      primary_key: primary_key || :id
    ]
  end
end
