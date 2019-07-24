# Crudry

[![Coverage Status](https://coveralls.io/repos/github/gabrielpra1/crudry/badge.svg?branch=master)](https://coveralls.io/github/gabrielpra1/crudry?branch=master)

Crudry is an elixir library for DRYing CRUD of Phoenix Contexts and Absinthe Resolvers.

It also provides a simple middleware for translating changeset errors into readable messages.

Documentation can be found at [https://hexdocs.pm/crudry](https://hexdocs.pm/crudry).

## Installation

The package can be installed by adding `crudry` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:crudry, "~> 1.5.0"},
  ]
end
```

## Usage

### Context Generation

To generate CRUD functions for a given schema in your context, simply do:

```elixir
defmodule MyApp.MyContext do
  alias MyApp.Repo

  require Crudry.Context
  Crudry.Context.generate_functions MyApp.MySchema
end
```

To see the functions that are generated and custom options, refer to the [Crudry.Context docs](https://hexdocs.pm/crudry/Crudry.Context.html#module-usage).

### Resolver Generation

With the context all set up, the resolver is ready to be generated:

```elixir
defmodule MyApp.MyResolver do
  alias MyApp.Repo

  require Crudry.Resolver
  Crudry.Resolver.generate_functions MyApp.MyContext, MyApp.MySchema
end
```

To see the functions that are generated and custom options, refer to the [Crudry.Resolver docs](https://hexdocs.pm/crudry/Crudry.Resolver.html#module-usage).

### Translate Errors middleware

Absinthe Middleware to translate errors and changeset errors into human readable messages. It support nested changeset errors and internationalization, using [Gettext](https://github.com/elixir-lang/gettext).

The `create`, `update` and `delete` functions in the resolver all return `Ecto.Changeset` as errors, so it's useful to translate them into human readable messages.

Crudry provides an `Absinthe.Middleware` to help with that, handling nested changeset errors. Just add it as a middleware to your mutations:

```elxixir
field :create_user, :user do
  arg :params, non_null(:user_params)

  resolve &UsersResolver.create_user/2
  middleware Crudry.Middlewares.TranslateErrors
end
```

Or define it for all queries and mutations, using [middleware/3](https://hexdocs.pm/absinthe/Absinthe.Middleware.html#module-object-wide-authentication):

```elixir
alias Crudry.Middlewares.TranslateErrors

def middleware(middleware, _field, _object) do
  middleware ++ [TranslateErrors]
end
```

`Cudry.Translator` is used by default to translate error messages to the default locale `en`. You can also use your own Gettext module by adding it to your Absinthe's schema `context/1` function:

```elixir
def context(context) do
  Map.put(context, :translator, MyAppWeb.Gettext)
end
```

Or just override the default locale in your [Context Plug](https://hexdocs.pm/absinthe/context-and-authentication.html#context-and-plugs):

```elixir
def call(conn, _) do
  Absinthe.Plug.put_options(conn, context: %{locale: "pt_BR"})
end
```

Refer to the [TranslateErrors docs](https://hexdocs.pm/crudry/Crudry.Middlewares.TranslateErrors.html) for more information.

## Related Projects

* [Rajska](https://github.com/rschef/rajska) is an elixir authorization library for Absinthe.
* [Uploadex](https://github.com/gabrielpra1/uploadex) is an elixir library for handling uploads using Ecto and Arc

## License

MIT License.

See [LICENSE](./LICENSE) for more information.
