defmodule ContextFunctionsGenerator do
  @moduledoc false

  def generate_function(:get, name, _pluralized_name, module, _opts) do
    quote do
      def unquote(:"get_#{name}")(id) do
        unquote(module)
        |> alias!(Repo).get(id)
      end

      def unquote(:"get_#{name}_by")(clauses) do
        unquote(module)
        |> alias!(Repo).get_by(clauses)
      end

      def unquote(:"get_#{name}_with_assocs")(id, assocs) do
        unquote(module)
        |> alias!(Repo).get(id)
        |> alias!(Repo).preload(assocs)
      end

      def unquote(:"get_#{name}_by_with_assocs")(clauses, assocs) do
        unquote(module)
        |> alias!(Repo).get_by(clauses)
        |> alias!(Repo).preload(assocs)
      end

      def unquote(:"get_#{name}!")(id) do
        unquote(module)
        |> alias!(Repo).get!(id)
      end

      def unquote(:"get_#{name}_by!")(clauses) do
        unquote(module)
        |> alias!(Repo).get_by!(clauses)
      end

      def unquote(:"get_#{name}_with_assocs!")(id, assocs) do
        unquote(module)
        |> alias!(Repo).get!(id)
        |> alias!(Repo).preload(assocs)
      end

      def unquote(:"get_#{name}_by_with_assocs!")(clauses, assocs) do
        unquote(module)
        |> alias!(Repo).get_by!(clauses)
        |> alias!(Repo).preload(assocs)
      end
    end
  end

  def generate_function(:list, _name, pluralized_name, module, _opts) do
    quote do
      def unquote(:"list_#{pluralized_name}")() do
        unquote(module)
        |> alias!(Repo).all()
      end

      def unquote(:"list_#{pluralized_name}")(opts) do
        unquote(module)
        |> Crudry.Query.list(opts)
        |> alias!(Repo).all()
      end

      def unquote(:"list_#{pluralized_name}_with_assocs")(assocs) do
        unquote(module)
        |> alias!(Repo).all()
        |> alias!(Repo).preload(assocs)
      end

      def unquote(:"list_#{pluralized_name}_with_assocs")(assocs, opts) do
        unquote(module)
        |> Crudry.Query.list(opts)
        |> alias!(Repo).all()
        |> alias!(Repo).preload(assocs)
      end
    end
  end

  def generate_function(:count, _name, pluralized_name, module, _opts) do
    quote do
      def unquote(:"count_#{pluralized_name}")(field \\ :id) do
        unquote(module)
        |> alias!(Repo).aggregate(:count, field)
      end
    end
  end

  def generate_function(:search, _name, pluralized_name, module, _opts) do
    quote do
      def unquote(:"search_#{pluralized_name}")(search_term) do
        module_fields = unquote(module).__schema__(:fields)

        unquote(module)
        |> Crudry.Query.search(search_term, module_fields)
        |> alias!(Repo).all()
      end
    end
  end

  def generate_function(:filter, _name, pluralized_name, module, _opts) do
    quote do
      def unquote(:"filter_#{pluralized_name}")(filters) do
        unquote(module)
        |> Crudry.Query.filter(filters)
        |> alias!(Repo).all()
      end
    end
  end

  def generate_function(:create, name, _pluralized_name, module, opts) do
    quote do
      def unquote(:"create_#{name}")(attrs) do
        unquote(module)
        |> struct()
        |> unquote(module).unquote(opts[:create])(attrs)
        |> alias!(Repo).insert()
      end

      def unquote(:"create_#{name}!")(attrs) do
        unquote(module)
        |> struct()
        |> unquote(module).unquote(opts[:create])(attrs)
        |> alias!(Repo).insert!()
      end
    end
  end

  def generate_function(:update, name, _pluralized_name, module, opts) do
    quote do
      def unquote(:"update_#{name}")(%module{} = struct, attrs) do
        struct
        |> unquote(module).unquote(opts[:update])(attrs)
        |> alias!(Repo).update()
      end

      def unquote(:"update_#{name}!")(%module{} = struct, attrs) do
        struct
        |> unquote(module).unquote(opts[:update])(attrs)
        |> alias!(Repo).update!()
      end

      def unquote(:"update_#{name}_with_assocs")(%module{} = struct, attrs, assocs) do
        struct
        |> alias!(Repo).preload(assocs)
        |> unquote(module).unquote(opts[:update])(attrs)
        |> alias!(Repo).update()
      end

      def unquote(:"update_#{name}_with_assocs!")(%module{} = struct, attrs, assocs) do
        struct
        |> alias!(Repo).preload(assocs)
        |> unquote(module).unquote(opts[:update])(attrs)
        |> alias!(Repo).update!()
      end
    end
  end

  def generate_function(:delete, name, _pluralized_name, module, opts) do
    quote do
      def unquote(:"delete_#{name}")(%module{} = struct) do
        struct
        |> Ecto.Changeset.change()
        |> check_assocs(unquote(opts[:check_constraints_on_delete]))
        |> alias!(Repo).delete()
      end

      def unquote(:"delete_#{name}!")(%module{} = struct) do
        struct
        |> Ecto.Changeset.change()
        |> check_assocs(unquote(opts[:check_constraints_on_delete]))
        |> alias!(Repo).delete!()
      end
    end
  end

  def generate_function(:check_assocs, _, _, _, _) do
    quote do
      defp unquote(:check_assocs)(changeset, nil), do: changeset

      defp unquote(:check_assocs)(changeset, constraints) when is_list(constraints) do
        Enum.reduce(constraints, changeset, fn i, acc ->
          Ecto.Changeset.no_assoc_constraint(acc, i)
        end)
      end
    end
  end
end
