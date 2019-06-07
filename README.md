# Crudry

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

* [Context Generation](https://hexdocs.pm/crudry/Crudry.Context.html#module-usage)
* [Resolver Generation](https://hexdocs.pm/crudry/Crudry.Resolver.html#module-usage)
* [Middleware](https://hexdocs.pm/crudry/Crudry.Middlewares.HandleChangesetErrors.html)
