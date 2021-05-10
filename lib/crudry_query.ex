defmodule Crudry.Query do
  @moduledoc """
  Generates Ecto Queries.

  All functions in this module return an `Ecto.Query`.

  Combining the functions in this module can be very powerful. For example, to do pagination with filter and search:

      pagination_params = %{limit: 10, offset: 1, order_by: "id", sorting_order: :desc}
      filter_params = %{username: ["username1", "username2"]}
      search_params = %{text: "search text", fields: [:username]}

      User
      |> Crudry.Query.filter(filter_params)
      |> Crudry.Query.list(pagination_params)
      |> Crudry.Query.search(search_params.text, search_params.fields)
      |> Repo.all()
  """

  import Ecto.Query

  @doc """
  Applies some restrictions to the query.

  Expects `opts` to be a keyword list or a map containing some of these fields:

  * `limit`: defaults to not limiting
  * `offset`: defaults to `0`
  * `sorting_order`: defaults to `:asc` (only works if there is also a `order_by` specified)
  * `order_by`: defaults to not ordering
  * `custom_query`: A function that receives the initial query as argument and returns a custom query. Defaults to `initial_query`

  ## Examples

      Crudry.Query.list(MySchema, [limit: 10])
      Crudry.Query.list(MySchema, [limit: 10, offset: 3, sorting_order: :desc, order_by: :value])
      Crudry.Query.list(MySchema, %{order_by: "value"})
      Crudry.Query.list(MySchema, %{order_by: :value})
      Crudry.Query.list(MySchema, %{order_by: ["age", "username"]})
      Crudry.Query.list(MySchema, %{order_by: [:age, :username]})
      Crudry.Query.list(MySchema, %{order_by: [asc: :age, desc: :username]})
      Crudry.Query.list(MySchema, %{order_by: [%{field: "age", order: :asc}, %{field: "username", order: :desc}]})
      Crudry.Query.list(MySchema, custom_query: &MySchema.scope_list/1)
  """
  def list(initial_query, opts \\ []) do
    access_module = get_access_module(opts)

    custom_query = access_module.get(opts, :custom_query, nil)
    limit = access_module.get(opts, :limit, nil)
    offset = access_module.get(opts, :offset, 0)
    sorting_order = access_module.get(opts, :sorting_order, :asc)
    order_by = access_module.get(opts, :order_by)
    order = parse_order_by_args(sorting_order, order_by)

    initial_query
    |> get_custom_query(custom_query)
    |> limit(^limit)
    |> offset(^offset)
    |> order_by(^order)
  end

  defp get_access_module(opts) when is_map(opts), do: Map
  defp get_access_module(opts) when is_list(opts), do: Keyword

  @doc """
  Searches for the `search_term` in the given `fields`.

  ## Examples

      Crudry.Query.search(MySchema, "John", [:name])
  """
  def search(initial_query, nil, _fields) do
    initial_query
  end

  def search(initial_query, "", _fields) do
    initial_query
  end

  def search(initial_query, search_term, fields) do
    Enum.reduce(fields, subquery(initial_query), fn
      module_field, query_acc ->
        query_acc
        |> or_where(
          [m],
          fragment(
            "CAST(? AS varchar) ILIKE ?",
            field(m, ^module_field),
            ^"%#{search_term}%"
          )
        )
    end)
  end

  @doc """
  Filters the query.

  ## Examples

      Crudry.Query.filter(MySchema, %{id: 5, name: "John"})
      Crudry.Query.filter(MySchema, %{name: ["John", "Doe"]})
  """
  def filter(initial_query, filters \\ []) do
    Enum.reduce(filters, initial_query, fn
      {field, filter_arr}, query_acc when is_list(filter_arr) ->
        query_acc
        |> where(
          [m],
          field(m, ^field) in ^filter_arr
        )

      {field, filter}, query_acc ->
        query_acc
        |> where(
          [m],
          field(m, ^field) == ^filter
        )
    end)
  end

  defp get_custom_query(initial_query, nil), do: initial_query

  defp get_custom_query(initial_query, custom_query), do: custom_query.(initial_query)

  defp parse_order_by_args(_, nil), do: []

  defp parse_order_by_args(sorting_order, orders_by) when is_list(orders_by) do
    Enum.map(orders_by, fn
      %{order: sort, field: order} -> {to_atom(sort), to_atom(order)}
      {sort, order} -> {to_atom(sort), to_atom(order)}
      order -> {to_atom(sorting_order), to_atom(order)}
    end)
  end

  defp parse_order_by_args(sorting_order, order_by), do: parse_order_by_args(sorting_order, List.wrap(order_by))

  defp to_atom(value) when is_atom(value), do: value
  defp to_atom(value) when is_binary(value), do: String.to_atom(value)
end
