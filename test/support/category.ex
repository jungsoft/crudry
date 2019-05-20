defmodule Crudry.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories_schema_source" do
    field(:content, :string)
    timestamps()
  end

  @doc false
  def changeset(record, attrs) do
    record
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end
