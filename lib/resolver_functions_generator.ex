defmodule ResolverFunctionsGenerator do
  @moduledoc false

  def generate_function(:get, name, _pluralized_name, context, opts) do
    quote do
      def unquote(:"get_#{name}")(%{unquote(opts[:primary_key]) => id}, _info) do
        apply(unquote(context), String.to_existing_atom("get_#{unquote(name)}"), [id])
        |> nil_to_error(unquote(name), fn record -> {:ok, record} end)
      end
    end
  end

  def generate_function(:list, _name, pluralized_name, context, opts) do
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

  def generate_function(:create, name, _pluralized_name, context, opts) do
    quote do
      def unquote(:"create_#{name}")(%{params: params} = args, info) do
        case Keyword.get(unquote(opts), :create_resolver, nil) do
          nil -> apply(unquote(context), String.to_existing_atom("create_#{unquote(name)}"), [params])
          create_resolver -> create_resolver.(unquote(context), unquote(name), args, info)
        end
      end
    end
  end

  def generate_function(:update, name, _pluralized_name, context, opts) do
    quote do
      def unquote(:"update_#{name}")(%{unquote(opts[:primary_key]) => id, params: params} = args, info) do
        unquote(context)
        |> apply(String.to_existing_atom("get_#{unquote(name)}"), [id])
        |> nil_to_error(unquote(name), fn record ->
          case Keyword.get(unquote(opts), :update_resolver, nil) do
            nil -> apply(unquote(context), String.to_existing_atom("update_#{unquote(name)}"), [record, params])
            update_resolver -> update_resolver.(unquote(context), unquote(name), record, args, info)
          end
        end)
      end
    end
  end

  def generate_function(:delete, name, _pluralized_name, context, opts) do
    quote do
      def unquote(:"delete_#{name}")(%{unquote(opts[:primary_key]) => id}, info) do
        unquote(context)
        |> apply(String.to_existing_atom("get_#{unquote(name)}"), [id])
        |> nil_to_error(unquote(name), fn record ->
          case Keyword.get(unquote(opts), :delete_resolver, nil) do
            nil -> apply(unquote(context), String.to_existing_atom("delete_#{unquote(name)}"), [record])
            delete_resolver -> delete_resolver.(unquote(context), unquote(name), record, info)
          end
        end)
      end
    end
  end

  def generate_function(:nil_to_error, _name, _pluralized_name, _context, opts) do
    quote do
      def unquote(:nil_to_error)(result, name, func) do
        case result do
          nil -> {:error, %{message: unquote(opts[:not_found_message]), schema: name}}
          %{} = record -> func.(record)
        end
      end
    end
  end

  def generate_function(:add_info_to_custom_query, _name, _pluralized_name, _context, _opts) do
    quote do
      def unquote(:add_info_to_custom_query)(custom_query, info) do
        fn initial_query -> custom_query.(initial_query, info) end
      end
    end
  end
end
