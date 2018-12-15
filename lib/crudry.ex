defmodule Crudry do
  @moduledoc """
  Documentation for Crudry.
  """

  defmacro define_functions(opts) do
    module = get_module(opts)
    name = get_module_name(module) |> String.downcase()

    quote location: :keep do
      def unquote(:"get_#{name}")(id) do
        unquote(module)
        |> alias!(Repo).get(id)
      end

      def unquote(:"get_#{name}!")(id) do
        unquote(module)
        |> alias!(Repo).get!(id)
      end

      def unquote(:"list_#{name}s")() do
        unquote(module)
        |> alias!(Repo).all()
      end

      def unquote(:"create_#{name}")(attrs) do
        unquote(module)
        |> struct()
        |> unquote(module).changeset(attrs)
        |> alias!(Repo).insert()
      end

      def unquote(:"update_#{name}")(%module{} = struct, attrs) do
        struct
        |> unquote(module).changeset(attrs)
        |> alias!(Repo).update()
      end

      def unquote(:"update_#{name}")(id, attrs) do
        id
        |> unquote(:"get_#{name}")()
        |> unquote(:"update_#{name}")(attrs)
      end

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

  defp get_module(opts) do
    Macro.expand(opts, __ENV__)
  end

  defp get_module_name(module) do
    module
    |> to_string()
    |> String.split(".")
    |> List.last()
  end
end
