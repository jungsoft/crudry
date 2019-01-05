defmodule Crudry.Resolver do
  @moduledoc """

  """

  @doc """
    Sets default options for the resolver.

    ## Options

      * `:only` - list of functions to be generated. If not empty, functions not
      specified in this list are not generated. Default to `[]`.

      * `:except` - list of functions to not be generated. If not empty, only functions not specified
      in this list will be generated. Default to `[]`.

    ## Examples

        iex> Crudry.Resolver.default only: [:create, :list]
        :ok

        iex> Crudry.Resolver.default except: [:get!, :list, :delete]
        :ok
  """
  defmacro default(opts) do
    Module.put_attribute(__CALLER__.module, :only, opts[:only])
    Module.put_attribute(__CALLER__.module, :except, opts[:except])
  end

  @doc """
    Generates CRUD functions for the `schema_module` resolver.

    Custom options can be given. To see the available options, refer to the documenation of `Crudry.Resolver.default/1`.

    ## Examples

  """
  defmacro generate_functions(context, schema_module, opts \\ []) do
    opts = Keyword.merge(load_default(__CALLER__.module), opts)
    name = Helper.get_underscored_name(schema_module)

    # Always generate nil_to_error function since it's used in the other generated functions
    for func <- [:nil_to_error, :get, :list, :create, :update, :delete] do
      if func == :nil_to_error || Helper.define_function?(func, opts[:only], opts[:except]) do
        ResolverFunctionsGenerator.generate_function(func, name, context)
      end
    end
  end

  # Load user-defined defaults or fall back to the library's default.
  defp load_default(module) do
    only = Module.get_attribute(module, :only)
    except = Module.get_attribute(module, :except)

    [
      only: only || [],
      except: except || []
    ]
  end
end
