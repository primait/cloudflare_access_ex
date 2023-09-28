defmodule CloudflareAccessEx.JwksStrategy do
  @moduledoc """
    This module is responsible for fetching and caching the public keys from Cloudflare's JWKS endpoint.

    The keys are fetched on startup and then every hour after that.

    The module implements JokenJwks's SignerMatchStrategy behaviour which is used by the JokenJwks hook to attempt to
    retrieve the correct signer to verify the token given the kid (key id) in the token header.
  """

  require Logger

  use GenServer

  alias Joken.Signer
  alias JokenJwks.SignerMatchStrategy
  alias CloudflareAccessEx.Config

  # Default 1 hour poll time for certs
  @poll_time_ms :timer.hours(1)

  @behaviour SignerMatchStrategy

  @impl SignerMatchStrategy
  @spec match_signer_for_kid(String.t(), keyword) ::
          {:error, atom()} | {:ok, Joken.Signer.t()}
  @doc """
  Implementing `SignerMatchStrategy`, attempts to find the `Signer` for the given key ID (`kid`).

  Expects `opts` to contain the domain that owns the key.
  """
  def match_signer_for_kid(kid, opts) do
    domain = Keyword.get(opts, :domain) || throw(":domain is required")

    signers = get_signers(domain)
    signer = signers[kid]

    case {signers, signer} do
      {signers, nil} when signers == %{} -> {:error, :no_signers_fetched}
      {_, nil} -> {:error, :kid_does_not_match}
      {_, signer} -> {:ok, signer}
    end
  end

  @doc """
  Ensures that the `JwksStrategy` for the given domain has initialized OK and is ready to return signers.
  """
  def ready?(domain) do
    signers = get_signers(domain)
    signers != %{}
  end

  @spec get_signers(String.t()) :: %{String.t() => Joken.Signer.t()}
  defp get_signers(domain) do
    GenServer.call(name(domain), :get_signers)
  end

  @type options :: [
          domain: String.t(),
          poll_time_ms: non_neg_integer()
        ]

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    domain = Keyword.get(opts, :domain) || throw(":domain is required")

    GenServer.start_link(__MODULE__, opts, name: name(domain))
  end

  @impl true
  def init(opts) do
    domain = Keyword.get(opts, :domain)

    state = %{
      domain: domain,
      url: get_jwks_url(domain),
      poll_time_ms: Keyword.get(opts, :poll_time_ms, @poll_time_ms),
      signers: %{}
    }

    {:ok, state, {:continue, :update_signers}}
  end

  defp get_jwks_url(domain) do
    "#{Config.get_issuer(domain)}/cdn-cgi/access/certs"
  end

  @impl true
  def handle_call(:get_signers, _from, state) do
    {:reply, state.signers, state}
  end

  @impl true
  def handle_continue(:update_signers, state) do
    state = %{state | signers: fetch_signers(state.url)}
    {:noreply, state}
  end

  @impl true
  def handle_info(:update_signers, state) do
    {:noreply, state, {:continue, :update_signers}}
  end

  defp name(domain) do
    {:global, {__MODULE__, domain}}
  end

  @spec fetch_signers(String.t()) :: %{String.t() => Joken.Signer.t()}
  defp fetch_signers(url) do
    {:ok, response} =
      HTTPoison.get!(url)
      |> Map.get(:body)
      |> Jason.decode()

    signers = Map.get(response, "keys") |> create_signers

    Logger.info("Created #{Enum.count(signers)} signers from keys at #{url}")

    Process.send_after(self(), :update_signers, @poll_time_ms)

    signers
  end

  defp create_signers(keys) do
    Enum.map(keys, fn
      %{"kid" => kid, "alg" => alg} = key ->
        {kid, Signer.create(alg, key)}

      _ ->
        {nil, nil}
    end)
    |> Enum.filter(fn {kid, _} -> !is_nil(kid) end)
    |> Map.new()
  end
end
