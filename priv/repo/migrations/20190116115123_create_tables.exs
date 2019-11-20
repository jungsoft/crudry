defmodule Crudry.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :name, :string

      timestamps()
    end

    create table(:users) do
      add :username, :string
      add :age, :integer
      add :password, :string
      add :company_id, references(:companies)

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

    create table(:comments) do
      add :content, :string
      add :post_id, references(:posts)

      timestamps()
    end

    create table(:camelized_schema_names) do
      add :content, :string

      timestamps()
    end

    create table(:categories_schema_source) do
      add :content, :string

      timestamps()
    end
  end
end
