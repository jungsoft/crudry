defmodule Crudry.CamelizedSchemaName do
  use Ecto.Schema
  import Ecto.Changeset

  schema "camelized_schema_names" do
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
