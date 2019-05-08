defmodule ResolverFunctionsGenerator do
  @moduledoc false

  def generate_function(:get, name, context, _opts) do
    quote do
      def unquote(:"get_#{name}")(%{id: id}, _info) do
        apply(unquote(context), String.to_existing_atom("get_#{unquote(name)}"), [id])
        |> nil_to_error(unquote(name), fn record -> {:ok, record} end)
      end
    end
  end

  def generate_function(:list, name, context, opts) do
    pluralized_name = Inflex.pluralize(name)

    quote do
      def unquote(:"list_#{pluralized_name}")(_args, info) do
        list_opts = unquote(opts[:list_opts])
        custom_list_opts =
          case Keyword.get(list_opts, :custom_query, nil) do
            nil -> list_opts
            custom_query -> Keyword.put(list_opts, :custom_query, add_info_to_custom_query(custom_query, info))
          end

        {:ok,
          apply(unquote(context), String.to_existing_atom("list_#{unquote(pluralized_name)}"), [custom_list_opts])
        }
      end
    end
  end

  def generate_function(:create, name, context, opts) do
    quote do
      def unquote(:"create_#{name}")(%{params: params} = args, info) do
        case Keyword.get(unquote(opts), :create_generator, nil) do
          nil -> apply(unquote(context), String.to_existing_atom("create_#{unquote(name)}"), [params])
          create_generator -> create_generator.(unquote(context), unquote(name), args, info)
        end
      end
    end
  end

  def generate_function(:update, name, context, _opts) do
    quote do
      def unquote(:"update_#{name}")(%{id: id, params: params}, _info) do
        apply(unquote(context), String.to_existing_atom("get_#{unquote(name)}"), [id])
        |> nil_to_error(unquote(name), fn record ->
          apply(unquote(context), String.to_existing_atom("update_#{unquote(name)}"), [
            record,
            params
          ])
        end)
      end
    end
  end

  def generate_function(:delete, name, context, _opts) do
    quote do
      def unquote(:"delete_#{name}")(%{id: id}, _info) do
        apply(unquote(context), String.to_existing_atom("get_#{unquote(name)}"), [id])
        |> nil_to_error(unquote(name), fn record ->
          apply(unquote(context), String.to_existing_atom("delete_#{unquote(name)}"), [record])
        end)
      end
    end
  end

  def generate_function(:nil_to_error, _name, _context, _opts) do
    quote do
      def unquote(:nil_to_error)(result, name, func) do
        case result do
          nil -> {:error, "#{Macro.camelize(name)} not found."}
          %{} = record -> func.(record)
        end
      end
    end
  end

  def generate_function(:add_info_to_custom_query, _name, _context, _opts) do
    quote do
      def unquote(:add_info_to_custom_query)(custom_query, info) do
        fn initial_query -> custom_query.(initial_query, info) end
      end
    end
  end
end
