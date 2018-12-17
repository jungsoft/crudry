defmodule Crudry do
  @moduledoc """
  Crudry is a library for DRYing CRUD.

  The library was made with Phoenix contexts in mind, using Ecto.Repo as the repository.
  """

  @doc """
  Sets default options for the context.

  ## Options

    * `:create` - the name of the changeset function used in the `create` function.
    Default to `:changeset`.

    * `:update` - the name of the changeset function used in the `update` function.
    Default to `:changeset`.

    * `:only` - list of functions to be generated. If not empty, functions not
    specified in this list are not generated. Default to `[]`.

    * `:except` - list of functions to not be generated. If not empty, only functions not specified
    in this list will be generated. Default to `[]`.

  ## Examples

      iex> Crudry.default create: :create_changeset, update: :update_changeset
      :ok

      iex> Crudry.default only: [:create, :list]
      :ok

      iex> Crudry.default except: [:get!, :list, :delete]
      :ok
  """
  defmacro default(opts) do
    Module.put_attribute(__CALLER__.module, :create_changeset, opts[:create])
    Module.put_attribute(__CALLER__.module, :update_changeset, opts[:update])
    Module.put_attribute(__CALLER__.module, :only, opts[:only])
    Module.put_attribute(__CALLER__.module, :except, opts[:except])
  end

  @doc """
  Generates CRUD functions for the `schema_module`.

  Custom options can be given. To see the available options, refer to the documenation of `default/1`.

  ## Examples

    Suppose we want to implement basic CRUD functionality for a User schema,
    exposed through an Accounts context:

      defmodule MyApp.Accounts do
        alias MyApp.Repo
        require Crudry

        # Assuming Accounts.User implements a `changeset/2` function, used both to create and update a user.
        Crudry.generate_functions MyApp.Accounts.User
      end

    Now, all this functionality is available:

      Accounts.get_user(id)
      Accounts.get_user!(id)
      Accounts.list_users()
      Accounts.create_user(attrs)
      Accounts.update_user(%User{}, attrs)
      Accounts.update_user(id, attrs)
      Accounts.delete_user(%User{})
      Accounts.delete_user(id)
  """
  defmacro generate_functions(schema_module, opts \\ []) do
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
          |> alias!()
          |> IO.inspect()
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

  # Load user-defined defaults or fall back to the library's default.
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
