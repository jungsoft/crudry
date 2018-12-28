defmodule Helper do
  @moduledoc false

  # Transforms and AST representation like {:__aliases__, [alias: false], [:Module, :SubModule]}
  # into a string represetation: "sub_module"
  def get_underscored_name(ast_module) do
    ast_module
    |> get_module()
    |> get_module_name()
    |> Macro.underscore()
  end

  # Transforms an AST representation like {:__aliases__, [alias: false], [:Module, :Submodule]}
  # into Module.Submodule
  def get_module(opts) do
    Macro.expand(opts, __ENV__)
  end

  # Get the name of the module as a string.
  # Transforms Module.Submodule into "Submodule"
  def get_module_name(module) do
    module
    |> to_string()
    |> String.split(".")
    |> List.last()
  end

  # Given the `only` and `except` options, check if a given function should be defined.
  # Here, `function` is an atom: :get, :get!, :list, :create, :update or :delete
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
