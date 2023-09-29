defmodule CloudflareAccessEx.Application do
  @moduledoc false
  use Application

  alias CloudflareAccessEx.{Config, JwksStrategy}

  @impl true
  def start(_type, args) do
    domains =
      Keyword.get(args, :domains) ||
        Config.get_domain_strings() ||
        []

    children =
      domains
      |> Enum.map(fn domain ->
        {JwksStrategy, [domain: domain]}
      end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CloudflareAccessEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
