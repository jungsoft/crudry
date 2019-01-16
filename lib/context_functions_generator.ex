defmodule ContextFunctionsGenerator do
  @moduledoc false

  def generate_function(:get, name, module, _create, _update) do
    quote location: :keep do
      def unquote(:"get_#{name}")(id) do
        unquote(module)
        |> alias!(Repo).get(id)
      end

      def unquote(:"get_#{name}_with_assocs")(id, assocs) do
        unquote(module)
        |> alias!(Repo).get(id)
        |> alias!(Repo).preload(assocs)
      end
    end
  end

  def generate_function(:get!, name, module, _create, _update) do
    quote location: :keep do
      def unquote(:"get_#{name}!")(id) do
        unquote(module)
        |> alias!(Repo).get!(id)
      end
    end
  end

  def generate_function(:list, name, module, _create, _update) do
    quote location: :keep do
      def unquote(:"list_#{Inflex.pluralize(name)}")() do
        unquote(module)
        |> alias!(Repo).all()
      end

      def unquote(:"list_#{Inflex.pluralize(name)}")(opts) do
        unquote(module)
        |> Crudry.Query.list(opts)
        |> alias!(Repo).all()
      end
    end
  end

  def generate_function(:count, name, module, _create, _update) do
    quote location: :keep do
      def unquote(:"count_#{Inflex.pluralize(name)}")(field \\ :id) do
        unquote(module)
        |> alias!(Repo).aggregate(:count, field)
      end
    end
  end

  def generate_function(:search, name, module, _create, _update) do
    quote location: :keep do
      def unquote(:"search_#{Inflex.pluralize(name)}")(search_term) do
        module_fields = unquote(module).__schema__(:fields)

        unquote(module)
        |> Crudry.Query.search(search_term, module_fields)
        |> alias!(Repo).all()
      end
    end
  end

  def generate_function(:filter, name, module, _create, _update) do
    quote location: :keep do
      def unquote(:"filter_#{Inflex.pluralize(name)}")(filters) do
        unquote(module)
        |> Crudry.Query.filter(filters)
        |> alias!(Repo).all()
      end
    end
  end

  def generate_function(:create, name, module, create, _update) do
    quote location: :keep do
      def unquote(:"create_#{name}")(attrs) do
        unquote(module)
        |> struct()
        |> unquote(module).unquote(create)(attrs)
        |> alias!(Repo).insert()
      end
    end
  end

  def generate_function(:update, name, module, _create, update) do
    quote location: :keep do
      def unquote(:"update_#{name}")(%module{} = struct, attrs) do
        struct
        |> unquote(module).unquote(update)(attrs)
        |> alias!(Repo).update()
      end

      def unquote(:"update_#{name}")(id, attrs) do
        id
        |> unquote(:"get_#{name}")()
        |> unquote(:"update_#{name}")(attrs)
      end

      def unquote(:"update_#{name}_with_assocs")(%module{} = struct, attrs, assocs) do
        struct
        |> alias!(Repo).preload(assocs)
        |> unquote(module).unquote(update)(attrs)
        |> alias!(Repo).update()
      end

      def unquote(:"update_#{name}_with_assocs")(id, attrs, assocs) do
        id
        |> unquote(:"get_#{name}")()
        |> unquote(:"update_#{name}_with_assocs")(attrs, assocs)
      end
    end
  end

  # defp check_constraints(changeset, constraints) do
  #   Enum.reduce(constraints, changeset, fn i, acc -> Ecto.Changeset.no_assoc_constraint(acc, i) end)
  # end

  def generate_function(:check_assocs, _, _, _, _) do
    quote location: :keep do
      def unquote(:check_assocs)(changeset, nil), do: changeset

      def unquote(:check_assocs)(changeset, constraints) when is_list(constraints) do
        Enum.reduce(constraints, changeset, fn i, acc -> Ecto.Changeset.no_assoc_constraint(acc, i) end)
      end

      def unquote(:check_assocs)(changeset, constraint) do
        Ecto.Changeset.no_assoc_constraint(changeset, constraint)
      end

    end
  end

  def generate_function(:delete, name, module, _create, _update) do
    quote location: :keep, bind_quoted: [module: module], unquote: true do
      def unquote(:"delete_#{name}")(struct, assoc_list \\ nil)
      def unquote(:"delete_#{name}")(%module{} = struct, assoc_list) do
        struct
        |> Ecto.Changeset.change()
        |> check_assocs(assoc_list)
        |> alias!(Repo).delete()
      end

      def unquote(:"delete_#{name}")(id, assoc_list) do
        id
        |> unquote(:"get_#{name}")()
        |> unquote(:"delete_#{name}")(assoc_list)
      end
    end
  end
end
