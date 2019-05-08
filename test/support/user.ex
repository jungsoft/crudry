defmodule Crudry.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:username, :string)
    field(:age, :integer)

    belongs_to :company, Crudry.Company
    has_many(:posts, Crudry.Post)
    has_many(:likes, Crudry.Like)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :age, :company_id])
    |> validate_required([:username])
    |> validate_length(:username, min: 2)
    |> validate_number(:age, greater_than: 0)
  end
end
