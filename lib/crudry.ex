defmodule Crudry do
  @moduledoc """
  Crudry is a library for DRYing CRUD.
  """

  defmacro default(opts) do
    Module.put_attribute(__CALLER__.module, :create_changeset, opts[:create])
    Module.put_attribute(__CALLER__.module, :update_changeset, opts[:update])
    Module.put_attribute(__CALLER__.module, :only, opts[:only])
    Module.put_attribute(__CALLER__.module, :except, opts[:except])
  end

  defmacro create_functions(schema_module, opts \\ []) do
    opts = Keyword.merge(load_default(__CALLER__.module), opts)

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
