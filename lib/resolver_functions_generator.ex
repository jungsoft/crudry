defmodule ResolverFunctionsGenerator do
  @moduledoc false

  def generate_function(:get, name, context) do
    quote location: :keep do
      def unquote(:"get_#{name}")(%{id: id}, _info) do
        case apply(unquote(context), String.to_existing_atom("get_#{unquote(name)}"), [id]) do
         nil -> {:error, "#{String.capitalize(unquote(name))} not found."}
         %{} = any -> {:ok, any}
        end
      end
    end
  end

  def generate_function(:list, name, context) do
    pluralized_name = Inflex.pluralize(name)

    quote location: :keep do
      def unquote(:"list_#{pluralized_name}")(_args, _info) do
        {:ok, apply(unquote(context), String.to_existing_atom("list_#{unquote(pluralized_name)}"), [])}
      end
    end
  end

  def generate_function(:create, name, context) do
    quote location: :keep do
      def unquote(:"create_#{name}")(%{unquote(String.to_existing_atom(name)) => params}, _info) do
        apply(unquote(context), String.to_existing_atom("create_#{unquote(name)}"), [params])
      end
    end
  end

  def generate_function(:update, name, context) do
    quote location: :keep do
      def unquote(:"update_#{name}")(%{:id => id, unquote(String.to_existing_atom(name)) => params}, _info) do
        case apply(unquote(context), String.to_existing_atom("get_#{unquote(name)}"), [id]) do
          nil -> {:error, "#{String.capitalize(unquote(name))} not found."}
          %{} = any -> apply(unquote(context), String.to_existing_atom("update_#{unquote(name)}"), [any, params])
        end
      end
    end
  end

  def generate_function(:delete, name, context) do
    quote location: :keep do
      def unquote(:"delete_#{name}")(%{id: id}, _info) do
        case apply(unquote(context), String.to_existing_atom("get_#{unquote(name)}"), [id]) do
          nil -> {:error, "#{String.capitalize(unquote(name))} not found."}
          %{} = any -> apply(unquote(context), String.to_existing_atom("delete_#{unquote(name)}"), [any])
        end
      end
    end
  end
end
