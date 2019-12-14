defmodule ContextFunctionsGenerator do
  @moduledoc false

  def get_repo_module(opts) do
    quote do
      case Keyword.get(unquote(opts), :repo, nil) do
        nil -> alias!(Repo)
        repo -> repo
      end
    end
  end

  def generate_function(:get, name, _pluralized_name, module, opts) do
    quote do
      def unquote(:"get_#{name}")(id, repo_opts \\ []) do
        unquote(module)
        |> unquote(get_repo_module(opts)).get(id, repo_opts)
      end

      def unquote(:"get_#{name}_by")(clauses, repo_opts \\ []) do
        unquote(module)
        |> unquote(get_repo_module(opts)).get_by(clauses, repo_opts)
      end

      def unquote(:"get_#{name}_with_assocs")(id, assocs, repo_opts \\ []) do
        unquote(module)
        |> unquote(get_repo_module(opts)).get(id, repo_opts)
        |> unquote(get_repo_module(opts)).preload(assocs)
      end

      def unquote(:"get_#{name}_by_with_assocs")(clauses, assocs, repo_opts \\ []) do
        unquote(module)
        |> unquote(get_repo_module(opts)).get_by(clauses, repo_opts)
        |> unquote(get_repo_module(opts)).preload(assocs)
      end

      def unquote(:"get_#{name}!")(id, repo_opts \\ []) do
        unquote(module)
        |> unquote(get_repo_module(opts)).get!(id, repo_opts)
      end

      def unquote(:"get_#{name}_by!")(clauses, repo_opts \\ []) do
        unquote(module)
        |> unquote(get_repo_module(opts)).get_by!(clauses, repo_opts)
      end

      def unquote(:"get_#{name}_with_assocs!")(id, assocs, repo_opts \\ []) do
        unquote(module)
        |> unquote(get_repo_module(opts)).get!(id, repo_opts)
        |> unquote(get_repo_module(opts)).preload(assocs)
      end

      def unquote(:"get_#{name}_by_with_assocs!")(clauses, assocs, repo_opts \\ []) do
        unquote(module)
        |> unquote(get_repo_module(opts)).get_by!(clauses, repo_opts)
        |> unquote(get_repo_module(opts)).preload(assocs)
      end
    end
  end

  def generate_function(:list, _name, pluralized_name, module, opts) do
    quote do
      def unquote(:"list_#{pluralized_name}")(opts \\ [], repo_opts \\ []) do
        unquote(module)
        |> Crudry.Query.list(opts)
        |> unquote(get_repo_module(opts)).all(repo_opts)
      end

      def unquote(:"list_#{pluralized_name}_with_assocs")(assocs, opts \\ [], repo_opts \\ []) do
        unquote(module)
        |> Crudry.Query.list(opts)
        |> unquote(get_repo_module(opts)).all(repo_opts)
        |> unquote(get_repo_module(opts)).preload(assocs)
      end
    end
  end

  def generate_function(:count, _name, pluralized_name, module, opts) do
    quote do
      def unquote(:"count_#{pluralized_name}")(field \\ :id, repo_opts \\ []) do
        unquote(module)
        |> unquote(get_repo_module(opts)).aggregate(:count, field, repo_opts)
      end
    end
  end

  def generate_function(:search, _name, pluralized_name, module, opts) do
    quote do
      def unquote(:"search_#{pluralized_name}")(search_term, repo_opts \\ []) do
        module_fields = unquote(module).__schema__(:fields)

        unquote(module)
        |> Crudry.Query.search(search_term, module_fields)
        |> unquote(get_repo_module(opts)).all(repo_opts)
      end
    end
  end

  def generate_function(:filter, _name, pluralized_name, module, opts) do
    quote do
      def unquote(:"filter_#{pluralized_name}")(filters, repo_opts \\ []) do
        unquote(module)
        |> Crudry.Query.filter(filters)
        |> unquote(get_repo_module(opts)).all(repo_opts)
      end
    end
  end

  def generate_function(:create, name, _pluralized_name, module, opts) do
    quote do
      def unquote(:"create_#{name}")(attrs, opts \\ []) do
        unquote(module)
        |> struct()
        |> unquote(module).unquote(opts[:create])(attrs)
        |> unquote(get_repo_module(opts)).insert(opts)
      end

      def unquote(:"create_#{name}!")(attrs, opts \\ []) do
        unquote(module)
        |> struct()
        |> unquote(module).unquote(opts[:create])(attrs)
        |> unquote(get_repo_module(opts)).insert!(opts)
      end
    end
  end

  def generate_function(:update, name, _pluralized_name, module, opts) do
    quote do
      def unquote(:"update_#{name}")(%unquote(module){} = struct, attrs, repo_opts \\ []) do
        struct
        |> unquote(module).unquote(opts[:update])(attrs)
        |> unquote(get_repo_module(opts)).update(repo_opts)
      end

      def unquote(:"update_#{name}!")(%unquote(module){} = struct, attrs, repo_opts \\ []) do
        struct
        |> unquote(module).unquote(opts[:update])(attrs)
        |> unquote(get_repo_module(opts)).update!(repo_opts)
      end

      def unquote(:"update_#{name}_with_assocs")(%unquote(module){} = struct, attrs, assocs, repo_opts \\ []) do
        struct
        |> unquote(get_repo_module(opts)).preload(assocs)
        |> unquote(module).unquote(opts[:update])(attrs)
        |> unquote(get_repo_module(opts)).update(repo_opts)
      end

      def unquote(:"update_#{name}_with_assocs!")(%unquote(module){} = struct, attrs, assocs, repo_opts \\ []) do
        struct
        |> unquote(get_repo_module(opts)).preload(assocs)
        |> unquote(module).unquote(opts[:update])(attrs)
        |> unquote(get_repo_module(opts)).update!(repo_opts)
      end
    end
  end

  def generate_function(:delete, name, _pluralized_name, module, opts) do
    quote do
      def unquote(:"delete_#{name}")(%unquote(module){} = struct, repo_opts \\ []) do
        struct
        |> Ecto.Changeset.change()
        |> check_assocs(unquote(opts[:check_constraints_on_delete]))
        |> unquote(get_repo_module(opts)).delete(repo_opts)
      end

      def unquote(:"delete_#{name}!")(%unquote(module){} = struct, repo_opts \\ []) do
        struct
        |> Ecto.Changeset.change()
        |> check_assocs(unquote(opts[:check_constraints_on_delete]))
        |> unquote(get_repo_module(opts)).delete!(repo_opts)
      end
    end
  end

  def generate_function(:check_assocs, _, _, _, _) do
    quote do
      defp unquote(:check_assocs)(changeset, constraints) when is_list(constraints) do
        Enum.reduce(constraints, changeset, fn i, acc ->
          Ecto.Changeset.no_assoc_constraint(acc, i)
        end)
      end
    end
  end
end
