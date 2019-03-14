defmodule Crudry.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :age, :integer

      timestamps()
    end

    create table(:posts) do
      add :user_id, references(:users)
      add :title, :string

      timestamps()
    end

    create table(:likes) do
      add :user_id, references(:users)
      add :post_id, references(:posts)

      timestamps()
    end
  end
end
