defmodule Crudry.Translator do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext),
  your module gains a set of macros for translations, for example:

      import Crudry.Gettext

      # Simple translation
      gettext("Here is the string to translate")

      # Plural translation
      ngettext("Here is the string to translate",
               "Here are the strings to translate",
               3)

      # Domain-based translation
      dgettext("errors", "Here is the error message to translate")

  See the [Gettext Docs](https://hexdocs.pm/gettext) for detailed usage.

  ## Usage with `Crudry.Middlewares.TranslateErrors`

  This module defines `errors_domain/0` and `schemas_domain/0` functions, which return the domains that will be used to translate changeset errors and ecto schema keys.

  You can also define and use your own Translator module in `Crudry.Middlewares.TranslateErrors` by adding it to your Absinthe's schema `context/1` function:

      def context(context) do
        Map.put(context, :translator, MyApp.Translator)
      end
  """
  use Gettext, otp_app: :crudry

  @spec errors_domain :: String.t()
  def errors_domain, do: "errors"

  @spec schemas_domain :: String.t()
  def schemas_domain, do: "schemas"
end
