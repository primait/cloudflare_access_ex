defmodule CloudflareAccessEx.MixProject do
  use Mix.Project

  @source_url "https://github.com/primait/cloudflare_access_ex"

  def project do
    [
      app: :cloudflare_access_ex,
      description: "An elixir library to verify Cloudflare Access application tokens",
      version: version(),
      aliases: aliases(),
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
      {:plug, "~> 1.14.2"},
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
      source_ref: version(),
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

  defp aliases do
    [
      "version.to_build": &show_version/1,
      "version.recommended": &show_recommended_version/1
    ]
  end

  defmodule GHA do
    def in_github_actions? do
      env_true?("GITHUB_ACTION")
    end

    def ref_name!, do: env!("GITHUB_REF_NAME")

    def sha!, do: env!("GITHUB_SHA")

    def short_sha!, do: String.slice(sha!(), 0, 7)

    def event_type!() do
      case env!("GITHUB_EVENT_NAME") do
        "push" ->
          :push

        "pull_request" ->
          :pull_request

        "pull_request_target" ->
          :pull_request_target

        "published" ->
          :published

        nil ->
          nil

        unknown ->
          IO.puts("GITHUB_EVENT_NAME is set to an unknown value: #{inspect(unknown)}")
          :unknwon
      end
    end

    defp env_true?(name) do
      String.match?(env(name, ""), ~r/^true$/i)
    end

    defp env(name, default \\ nil), do: System.get_env(name, default)
    defp env!(name), do: env(name) || raise("Expected #{name} to be set in the environment")
  end

  defp show_version(_args) do
    IO.puts(version())
  end

  # Used to show
  defp show_recommended_version(_args) do
    if GHA.event_type!() != :published,
      do: throw("This command is only available on published events")

    recomended = %Version{Version.parse(version()) | patch: 0, pre: [], build: nil}
    IO.puts("~> #{Version.to_string(recomended)}")
  end

  @dev_version Version.parse!("0.0.0")

  defp version do
    version =
      if System.get_env("CI") == "true" do
        if not GHA.in_github_actions?(),
          do: raise("CI is set to true but GITHUB_ACTION is not set")

        case GHA.event_type!() do
          :published -> published_version()
          :pull_request -> branch_version()
          :push -> branch_version()
          _ -> %Version{@dev_version | pre: ["unknown"]}
        end
      else
        %Version{@dev_version | pre: ["dev"]}
      end

    Version.to_string(version)
  end

  defp published_version() do
    case Version.parse(GHA.ref_name!()) do
      {:ok, version} ->
        version

      :error ->
        raise "Expected GITHUB_REF_NAME in sem-ver format, got: #{inspect(GHA.ref_name!())}"
    end
  end

  defp branch_version() do
    ref_name = String.replace(GHA.ref_name!(), ~r/[^0-9A-Za-z-]/, "-")
    %Version{@dev_version | pre: [String.slice(ref_name, -16..-1)], build: GHA.short_sha!()}
  end
end
