defmodule HandleChangesetErrorsTest do
  use ExUnit.Case

  alias Ecto.Changeset
  alias Crudry.Middlewares.HandleChangesetErrors
  alias Crudry.{Like, Post, User}

  test "ignore not changeset errors" do
    resolution = build_resolution("Not logged in")

    assert HandleChangesetErrors.call(resolution, :_) == build_resolution("Not logged in")
  end

  test "translate can't be blank changeset error" do
    changeset = User.changeset(%User{}, %{})
    resolution = build_resolution(changeset)

    assert HandleChangesetErrors.call(resolution, :_) ==
             build_resolution("username can't be blank")
  end

  test "translate length changeset error" do
    changeset = User.changeset(%User{}, %{username: "a"})
    resolution = build_resolution(changeset)

    assert HandleChangesetErrors.call(resolution, :_) ==
             build_resolution("username should be at least 2 character(s)")
  end

  test "translate multiple changeset errors" do
    changeset = Post.changeset(%Post{}, %{})
    resolution = build_resolution(changeset)

    assert HandleChangesetErrors.call(resolution, :_) ==
             build_resolution(["title can't be blank", "user_id can't be blank"])
  end

  test "translate nested changeset errors" do
    changeset =
      %User{}
      |> User.changeset(%{posts: [%{}]})
      |> Changeset.cast_assoc(:posts, with: &Post.changeset/2)

    resolution = build_resolution(changeset)

    assert HandleChangesetErrors.call(resolution, :_) ==
             build_resolution([
               "posts: title can't be blank",
               "posts: user_id can't be blank",
               "username can't be blank"
             ])
  end

  test "translate deeply nested changeset errors" do
    changeset =
      %User{}
      |> User.changeset(%{posts: [%{likes: [%{}]}]})
      |> Changeset.cast_assoc(:posts, with: &Post.nested_changeset/2)

    resolution = build_resolution(changeset)

    assert HandleChangesetErrors.call(resolution, :_) ==
             build_resolution([
               "likes: post_id can't be blank",
               "likes: user_id can't be blank",
               "posts: title can't be blank",
               "posts: user_id can't be blank",
               "username can't be blank"
             ])
  end

  test "translate multiple nested changeset errors" do
    changeset =
      %User{}
      |> User.changeset(%{posts: [%{}], likes: [%{}]})
      |> Changeset.cast_assoc(:posts, with: &Post.changeset/2)
      |> Changeset.cast_assoc(:likes, with: &Like.changeset/2)

    resolution = build_resolution(changeset)

    assert HandleChangesetErrors.call(resolution, :_) ==
             build_resolution([
               "likes: post_id can't be blank",
               "likes: user_id can't be blank",
               "posts: title can't be blank",
               "posts: user_id can't be blank",
               "username can't be blank"
             ])
  end

  test "translate multiple nested changeset errors when one doesn't have errors" do
    changeset =
      %User{}
      |> User.changeset(%{posts: [%{}], likes: [%{post_id: 1, user_id: 1}]})
      |> Changeset.cast_assoc(:posts, with: &Post.changeset/2)
      |> Changeset.cast_assoc(:likes, with: &Like.changeset/2)

    resolution = build_resolution(changeset)

    assert HandleChangesetErrors.call(resolution, :_) ==
             build_resolution([
               "posts: title can't be blank",
               "posts: user_id can't be blank",
               "username can't be blank"
             ])
  end

  defp build_resolution(errors) when is_list(errors) do
    %{errors: errors, state: :resolved}
  end

  defp build_resolution(errors) do
    build_resolution([errors])
  end
end
