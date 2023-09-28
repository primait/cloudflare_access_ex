defmodule CloudflareAccessEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :cloudflare_access_ex,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [
        check: :test,
        credo: :test,
        dialyzer: :test,
        doctor: :test,
        sobelow: :test,
        "deps.audit": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CloudflareAccessEx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: :test, runtime: false},
      {:dialyxir, "~> 1.3", only: :test, runtime: false},
      {:ex_check, "~> 0.14.0", only: :test, runtime: false}
    ]
  end
end
