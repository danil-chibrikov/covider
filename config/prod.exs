import Config

config :Covider, Covider.Repo,
  adapter: ClickhouseEcto,
  hostname: "hcr3.wirknode.com",
  port: 8124,
  database: "workshop",
  timeout: 60_000,
  pool_timeout: 60_000,
  ownership_timeout: 60_000,
  pool_size: 30
