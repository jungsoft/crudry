defmodule Crudry do
  @moduledoc """
  Crudry is a library for DRYing CRUD.
  """

  # Isn't required, only used to update default changeset functions
  # If it isn't needed, should it be a normal macro instead of __using__?
  defmacro __using__(opts) do
    Module.put_attribute(__CALLER__.module, :create_changeset, opts[:create])
    Module.put_attribute(__CALLER__.module, :update_changeset, opts[:update])

    # This is for making it available at run-time. But is it needed?
    quote bind_quoted: [opts: opts] do
      @create_changeset opts[:create]
      @update_changeset opts[:update]
    end
  end

  defmacro create_functions(schema_module, opts \\ []) do
    create_changeset = Module.get_attribute(__CALLER__.module, :create_changeset)
    update_changeset = Module.get_attribute(__CALLER__.module, :update_changeset)

    # Default changeset is defined in `use` or `changeset` if nothing is defined.
    opts = Keyword.merge(
      [create: create_changeset || :changeset,
       update: update_changeset || :changeset,
       only: [],
       except: []],
       opts)

    module = get_module(schema_module)
    name = get_module_name(module) |> String.downcase()

    quote location: :keep do
      if unquote(define_function?(:get, opts[:only], opts[:except])) do
        def unquote(:"get_#{name}")(id) do
          unquote(module)
          |> alias!(Repo).get(id)
        end
      end

      if unquote(define_function?(:get!, opts[:only], opts[:except])) do
        def unquote(:"get_#{name}!")(id) do
          unquote(module)
          |> alias!(Repo).get!(id)
        end
      end

      if unquote(define_function?(:list, opts[:only], opts[:except])) do
        def unquote(:"list_#{name}s")() do
          unquote(module)
          |> alias!(Repo).all()
        end
      end

      if unquote(define_function?(:create, opts[:only], opts[:except])) do
        def unquote(:"create_#{name}")(attrs) do
          unquote(module)
          |> struct()
          |> unquote(module).unquote(opts[:create])(attrs)
          |> alias!(Repo).insert()
        end
      end

      if unquote(define_function?(:update, opts[:only], opts[:except])) do
        def unquote(:"update_#{name}")(%module{} = struct, attrs) do
          struct
          |> unquote(module).unquote(opts[:update])(attrs)
          |> alias!(Repo).update()
        end

        def unquote(:"update_#{name}")(id, attrs) do
          id
          |> unquote(:"get_#{name}")()
          |> unquote(:"update_#{name}")(attrs)
        end
      end

      if unquote(define_function?(:delete, opts[:only], opts[:except])) do
        def unquote(:"delete_#{name}")(%module{} = struct) do
          struct
          |> alias!(Repo).delete()
        end

        def unquote(:"delete_#{name}")(id) do
          id
          |> unquote(:"get_#{name}")()
          |> unquote(:"delete_#{name}")()
        end
      end
    end
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
