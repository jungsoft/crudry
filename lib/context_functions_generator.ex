defmodule ContextFunctionsGenerator do
  @moduledoc false

  def generate_function(:get, name, module, _create, _update) do
    quote location: :keep do
      def unquote(:"get_#{name}")(id) do
        unquote(module)
        |> alias!(Repo).get(id)
      end

      def unquote(:"get_#{name}_with_assocs")(id, assocs) do
        unquote(module)
        |> alias!(Repo).get(id)
        |> alias!(Repo).preload(assocs)
      end
    end
  end

  def generate_function(:get!, name, module, _create, _update) do
    quote location: :keep do
      def unquote(:"get_#{name}!")(id) do
        unquote(module)
        |> alias!(Repo).get!(id)
      end
    end
  end

  def generate_function(:list, name, module, _create, _update) do
    quote location: :keep do
      def unquote(:"list_#{Inflex.pluralize(name)}")() do
        unquote(module)
        |> alias!(Repo).all()
      end
    end
  end

  def generate_function(:create, name, module, create, _update) do
    quote location: :keep do
      def unquote(:"create_#{name}")(attrs) do
        unquote(module)
        |> struct()
        |> unquote(module).unquote(create)(attrs)
        |> alias!(Repo).insert()
      end
    end
  end

  def generate_function(:update, name, module, _create, update) do
    quote location: :keep do
      def unquote(:"update_#{name}")(%module{} = struct, attrs) do
        struct
        |> unquote(module).unquote(update)(attrs)
        |> alias!(Repo).update()
      end

      def unquote(:"update_#{name}")(id, attrs) do
        id
        |> unquote(:"get_#{name}")()
        |> unquote(:"update_#{name}")(attrs)
      end

      def unquote(:"update_#{name}_with_assocs")(%module{} = struct, attrs, assocs) do
        struct
        |> alias!(Repo).preload(assocs)
        |> unquote(module).unquote(update)(attrs)
        |> alias!(Repo).update()
      end

      def unquote(:"update_#{name}_with_assocs")(id, attrs, assocs) do
        id
        |> unquote(:"get_#{name}")()
        |> unquote(:"update_#{name}_with_assocs")(attrs, assocs)
      end
    end
  end

  def generate_function(:delete, name, module, _create, _update) do
    quote location: :keep, bind_quoted: [module: module], unquote: true do
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
