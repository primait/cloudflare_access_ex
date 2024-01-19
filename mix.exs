defmodule CloudflareAccessEx.MixProject do
  use Mix.Project

  @source_url "https://github.com/primait/cloudflare_access_ex"
  @version "0.1.4"

  def project do
    [
      app: :cloudflare_access_ex,
      description: "An elixir library to verify Cloudflare Access application tokens",
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [
        check: :test,
        credo: :test,
        dialyzer: :test,
        doctor: :test,
        sobelow: :test,
        "deps.audit": :test
      ],
      package: package(),
      docs: docs()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: elixirc_paths(:dev) ++ ["test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
      {:doctor, "~> 0.21.0", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.15.0", only: :test, runtime: false},
      {:ex_doc, "~> 0.27", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.0", only: :test, runtime: false},
      {:httpoison, "~> 1.7 or ~> 2.0"},
      {:joken, "~> 2.6"},
      {:joken_jwks, "~> 1.6.0"},
      {:plug, "~> 1.14"},
      {:test_server, "~> 0.1.13", only: :test}
    ]
  end

  defp docs do
    [
      main: "CloudflareAccessEx",
      extras: [
        "LICENSE.md": [title: "License"]
      ],
      source_url: @source_url,
      source_ref: @version,
      formatters: ["html"]
    ]
  end

  defp package do
    [
      name: "cloudflare_access_ex",
      maintainers: ["Prima"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
