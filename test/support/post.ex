defmodule Crudry.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field(:title, :string)
    belongs_to(:user, Crudry.User)
    has_many(:likes, Crudry.Like)

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :user_id])
    |> validate_required([:title, :user_id])
    |> foreign_key_constraint(:user_id)
  end

  def nested_changeset(post, attrs) do
    post
    |> changeset(attrs)
    |> cast_assoc(:likes, with: &Crudry.Like.changeset/2)
  end
end
