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
  Given the `only` and `except` options, check if a given function should be defined.
  Here, `function` is an atom: :get, :get!, :list, :create, :update or :delete
  """
  def define_function?(_function, [] = _only, [] = _except) do
    true
  end

  def define_function?(function, only, [] = _except) do
    Enum.member?(only, function)
  end

  def define_function?(function, [] = _only, except) do
    !Enum.member?(except, function)
  end
end
