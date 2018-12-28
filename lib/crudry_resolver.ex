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

    name =
      schema_module
      |> get_module()
      |> get_module_name()
      |> Macro.underscore()

    for func <- [:get, :list, :create, :update, :delete] do
      if define_function?(func, opts[:only], opts[:except]) do
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

  # Transforms an AST representation like {:__aliases__, [alias: false], [:Module, :Submodule]}
  # into Module.Submodule
  defp get_module(opts) do
    Macro.expand(opts, __ENV__)
  end

  # Get the name of the module as a string.
  # Transforms Module.Submodule into "Submodule"
  defp get_module_name(module) do
    module
    |> to_string()
    |> String.split(".")
    |> List.last()
  end

  # Given the `only` and `except` options, check if a given function should be defined.
  # Here, `function` is an atom: :get, :get!, :list, :create, :update or :delete
  defp define_function?(_function, [] = _only, [] = _except) do
    true
  end

  defp define_function?(function, only, [] = _except) do
    Enum.member?(only, function)
  end

  defp define_function?(function, [] = _only, except) do
    !Enum.member?(except, function)
  end
end
