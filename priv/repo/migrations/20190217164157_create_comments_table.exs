defmodule Crudry.Repo.Migrations.CreateCommentsTable do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :content, :string
      add :post_id, references(:posts)

      timestamps()
    end
  end
end
