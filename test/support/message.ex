defmodule Crudry.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uid, Ecto.UUID, autogenerate: true}

  schema "messages" do
    field(:content, :string)

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    cast(message, attrs, [:content])
  end
end
