defmodule Covider.Repo.Migrations.CreateTweets do
  use Ecto.Migration

  def change do
    create_if_not_exists table(
      :covid,
      engine: """
        ReplicatedSummingMergeTree('/clickhouse/tables/1-1/covid', 'hcr')
        PARTITION BY toStartOfMonth(date)
        ORDER BY (date, country, state)
      """
    ) do
      ## key

      add(:date, :date)
      add(:country, :string, default: "-")
      add(:state, :string, default: "-")

      ## value

      add(:fips, :Int64, default: 0)
      add(:cases, :Int64, default: 0)
      add(:deaths, :Int64, default: 0)
    end
  end
end
