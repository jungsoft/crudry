defmodule Crudry.Middlewares.HandleChangesetErrors do
  @moduledoc """
  Absinthe Middleware to translate changeset errors into human readable messages. It supports nested errors.

  ## Usage

  To handle errors for a field, add it after the resolve, using [`middleware/2`](https://hexdocs.pm/absinthe/Absinthe.Middleware.html#module-the-middleware-2-macro):

      alias Crudry.Middlewares.HandleChangesetErrors

      field :create_user, :user do
        arg :params, non_null(:user_params)

        resolve &UsersResolver.create_user/2
        middleware HandleChangesetErrors
      end

  To handle errors for all fields, use [Object Wide Authentication](https://hexdocs.pm/absinthe/Absinthe.Middleware.html#module-object-wide-authentication):

      alias Crudry.Middlewares.HandleChangesetErrors

      # Only add the middleware to mutations
      def middleware(middleware, _field, %Absinthe.Type.Object{identifier: identifier})
      when identifier in [:mutation] do
        middleware ++ [HandleChangesetErrors]
      end

      def middleware(middleware, _field, _object) do
        middleware
      end

  ## Examples

  For a simple changeset error:

      #Ecto.Changeset<
        action: nil,
        changes: %{},
        errors: [username: {"can't be blank", [validation: :required]}],
        data: #Crudry.User<>,
        valid?: false
      >

  The resulting error will be `["username can't be blank"]`

  For a changeset with nested errors:

      #Ecto.Changeset<
        action: nil,
        changes: %{
          posts: [
            #Ecto.Changeset<
              action: :insert,
              changes: %{},
              errors: [
                title: {"can't be blank", [validation: :required]},
                user_id: {"can't be blank", [validation: :required]}
              ],
              data: #Crudry.Post<>,
              valid?: false
            >
          ]
        },
        errors: [
          username: {"should be at least %{count} character(s)",
          [count: 2, validation: :length, kind: :min]}
        ],
        data: #Crudry.User<>,
        valid?: false
      >

  The resulting error will be `["posts: title can't be blank", "posts: user_id can't be blank", "username should be at least 2 character(s)"]`
  """

  @behaviour Absinthe.Middleware

  alias Absinthe.Resolution
  alias Ecto.Changeset

  def call(%{errors: errors} = resolution, _config) do
    resolution
    |> Resolution.put_result({:error, Enum.flat_map(errors, &handle_error/1)})
  end

  defp handle_error(%Ecto.Changeset{} = changeset) do
    changeset
    |> Changeset.traverse_errors(&translate_error/1)
    |> Enum.map(fn {key, value} -> message_to_string(key, value) end)
    |> List.flatten()
  end

  defp handle_error(error), do: [error]

  # The error message is a tuple like this:
  # {"should be at least %{count} characters", [count: 3, validation: :length, min: 3]}
  # So here we translate it to become like this:
  # "should be at least 3 characters"
  defp translate_error({err, opts}) do
    Enum.reduce(opts, err, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  # Simple case (e.g. key: `label`, value: `"does not exist"`)
  # Just concatenate strings
  defp message_to_string(key, [value]) when is_binary(value) do
    "#{key} #{value}"
  end

  # Nested case, like this:
  # %{project_workflow_steps: [%{map: %{definition: ["cant be blank"]}}, %{}]}
  # key: `project_workflow_steps`, value: `[%{map: %{definition: ["cant be blank"]}}, %{}]`
  # Remove empty maps and recursively convert nested messages to string
  defp message_to_string(key, value) when is_list(value) do
    value
    |> Enum.reject(fn x -> x == %{} end)
    |> Enum.map(fn x ->
      Enum.map(x, fn {inner_key, inner_value} ->
        message_to_string(key, Map.new([{inner_key, inner_value}]))
      end)
    end)
  end

  # When there are no more nested errors, the input is
  # key: `map`, value: `%{definition: ["cant be blank"]}`
  # Only add `key: ` to the start of the string if this is the last level of nesting.
  defp message_to_string(key, %{} = value) do
    Enum.map(value, fn {inner_key, inner_value} ->
      case get_value(inner_value) do
        %{} -> message_to_string(inner_key, inner_value)
        _ -> "#{key}: #{message_to_string(inner_key, inner_value)}"
      end
    end)
  end

  defp get_value(%{} = value), do: value
  defp get_value(value), do: List.first(value)
end
