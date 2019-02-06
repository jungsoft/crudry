defmodule Crudry.Query do
  @moduledoc """
  Generates Ecto Queries.

  All functions in this module return an `Ecto.Query`.
  """

  import Ecto.Query

  @doc """
  Applies some restrictions to the query.

  Expects `opts` to be a map containing some of these fields:

  * `limit`: defaults to not limiting
  * `offset`: defaults to `0`
  * `sorting_order`: defaults to `:asc` (only works if there is also a `order_by` specified)
  * `order_by`: defaults to not ordering

  ## Examples

      Crudry.Query.list(MySchema, [limit: 10])
      Crudry.Query.list(MySchema, [limit: 10, offset: 3, sorting_order: :desc, order_by: :value])
      Crudry.Query.list(MySchema, [order_by: "value"])
  """
  def list(initial_query, opts \\ []) do
    limit = Keyword.get(opts, :limit, nil)
    offset = Keyword.get(opts, :offset, 0)
    sorting_order = Keyword.get(opts, :sorting_order, :asc)
    order_by = Keyword.get(opts, :order_by)
    order = if order_by, do: [{sorting_order, to_atom(order_by)}], else: []

    initial_query
    |> limit(^limit)
    |> offset(^offset)
    |> order_by(^order)
  end

  defp to_atom(value) when is_atom(value), do: value
  defp to_atom(value) when is_binary(value), do: String.to_atom(value)

  @doc """
  Searches for the `search_term` in the given `fields`.

  ## Examples

      Crudry.Query.search(MySchema, "John", [:name])
  """
  def search(initial_query, nil, _fields) do
    from(initial_query)
  end

  def search(initial_query, search_term, fields) do
    Enum.reduce(fields, from(initial_query), fn
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
      {field, filter_arr}, query_acc ->
        query_acc
        |> where(
          [m],
          field(m, ^field) in ^filter_arr
        )
    end)
  end
end
