defmodule Helper do
  @moduledoc false

  @doc """
  Transforms and AST representation like {:__aliases__, [alias: false], [:Module, :SubModule]}
  into a string representation: "sub_module"
  """
  def get_underscored_name(ast_module) do
    ast_module
    |> get_module()
    |> get_module_name()
    |> Macro.underscore()
  end

  @doc """
  Transforms an AST representation like {:__aliases__, [alias: false], [:Module, :Submodule]}
  into Module.Submodule
  """
  def get_module(opts) do
    Macro.expand(opts, __ENV__)
  end

  @doc """
  Get the name of the module as a string.
  Transforms Module.Submodule into "Submodule"
  """
  def get_module_name(module) do
    module
    |> to_string()
    |> String.split(".")
    |> List.last()
  end

  @doc """
  Returns the source (database table name) of a module that defines an Ecto schema.
  """
  def get_pluralized_name(module, caller) do
    module
    |> Macro.expand(caller)
    |> apply(:__schema__, [:source])
  end

  @doc """
  Uses an attribute in the caller's module to make sure the helper functions are only generated once per module.
  """
  def get_functions_to_be_generated(module, all_functions, helper_functions, opts) do
    functions = filter_functions_to_be_generated(all_functions, opts[:only], opts[:except])

    if Module.get_attribute(module, :called) do
      functions
    else
      Module.put_attribute(module, :called, true)
      helper_functions ++ functions
    end
  end

  @doc """
  Given the `only` and `except` options, return which functions should be generated.
  Here, `function` is an atom: :get, :list, etc.
  """
  def filter_functions_to_be_generated(_all_functions, [_ | _] = only, _except) do
    only
  end

  def filter_functions_to_be_generated(all_functions, _only, [_ | _] =  except) do
    all_functions -- except
  end

  def filter_functions_to_be_generated(all_functions, _only, _except) do
    all_functions
  end
end
