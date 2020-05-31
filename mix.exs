defmodule Covider.MixProject do
  use Mix.Project

  def project do
    [
      app: :Covider,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Covider.Application, []},
      extra_applications: [
        :logger,
        :jason,
        :nimble_csv
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # HTTP
      {:tesla, "~> 1.3.0"},
      {:hackney, "~> 1.15.2"},

      # Parsers
      {:jason, "~> 1.2"},
      {:nimble_csv, "~> 0.6"},

      {:clickhouse_ecto, "== 0.2.4"}
    ]
  end
end

# https://twitter.com/i/search/timeline?f=tweets&vertical=default&q=коронавирус&src=tyah&reset_error_state=false&include_available_features=1&include_entities=1&include_new_items_bar=true
