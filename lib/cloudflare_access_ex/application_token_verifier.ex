defmodule CloudflareAccessEx.ApplicationTokenVerifier do
  @moduledoc """
    Verifies a Cloudflare Access application token (JWT) and returns decoded information from the token.
  """

  require Logger
  alias CloudflareAccessEx.{Config, JwksStrategy}

  @opaque t :: %__MODULE__{
            domain: String.t(),
            audience: String.t(),
            issuer: String.t(),
            jwks_strategy: atom()
          }

  @enforce_keys [:domain, :audience, :issuer, :jwks_strategy]
  defstruct [:domain, :audience, :issuer, :jwks_strategy]

  @type verified_token() ::
          :anonymous
          | {:user,
             %{
               required(id: String.t()) => String.t(),
               required(email: String.t()) => String.t()
             }}
  @type verify_result() :: {:ok, verified_token()} | {:error, atom() | Keyword.t()}

  @doc """
  Creates an ApplicationTokenVerifier that can be used by `ApplicationTokenVerifier.verify/2`.

  If the config is an atom, it will be used to lookup the config in the `:cloudflare_access_ex` `Application` environment.

  Alternatively, the config can be a keyword list with the following keys:

  * `:domain` - The domain to verify the token against. This can be a string or an atom that is used to lookup the domain in the `:cloudflare_access_ex` `Application` environment.
  * `:audience` - The audience to verify the token against.
  * `:jwks_strategy` - The module to use to fetch the public keys from Cloudflare's JWKS endpoint. Defaults to `CloudflareAccessEx.JwksStrategy`.

  ## Examples

      iex> Application.put_env(:cloudflare_access_ex, :my_cfa_app, [
      ...>   domain: "example.com",
      ...>   audience: "audience_string",
      ...> ])
      ...>
      ...> ApplicationTokenVerifier.create(:my_cfa_app)
      %ApplicationTokenVerifier{
        audience: "audience_string",
        domain: "example.com",
        issuer: "https://example.com",
        jwks_strategy: CloudflareAccessEx.JwksStrategy
      }

      iex> Application.put_env(:cloudflare_access_ex, :my_cfa_app, [
      ...>   domain: :example,
      ...>   audience: "audience_string",
      ...> ])
      ...> Application.put_env(:cloudflare_access_ex, :example,
      ...>   domain: "example.com"
      ...> )
      ...>
      ...> ApplicationTokenVerifier.create(:my_cfa_app)
      %ApplicationTokenVerifier{
        audience: "audience_string",
        domain: "example.com",
        issuer: "https://example.com",
        jwks_strategy: CloudflareAccessEx.JwksStrategy
      }

      iex> ApplicationTokenVerifier.create(
      ...>   domain: "example.com",
      ...>   audience: "audience_string",
      ...>   jwks_strategy: MyCustomJwksStrategy
      ...> )
      %ApplicationTokenVerifier{
        audience: "audience_string",
        domain: "example.com",
        issuer: "https://example.com",
        jwks_strategy: MyCustomJwksStrategy
      }
  """
  @spec create(atom | keyword) :: __MODULE__.t()
  def create(config_key) when is_atom(config_key) do
    opts =
      Application.get_env(:cloudflare_access_ex, config_key) ||
        throw("Could not find config for #{inspect(config_key)} in :cloudflare_access_ex")

    create(opts)
  end

  def create(opts) when is_list(opts) do
    audience =
      Keyword.get(opts, :audience) ||
        throw(":audience is required in cloudflare_access_ex config")

    domain =
      Keyword.get(opts, :domain) || throw(":domain is required in cloudflare_access_ex config")

    jwks_strategy = Keyword.get(opts, :jwks_strategy) || JwksStrategy

    domain = Config.resolve_domain(domain)
    issuer = Config.get_issuer(domain)

    %__MODULE__{
      domain: domain,
      issuer: issuer,
      audience: audience,
      jwks_strategy: jwks_strategy
    }
  end

  @doc """
  Verifies the authenticity of the Cloudflare Access application token in the given `Plug.Conn` or application_token against the given verifier.
  """
  @spec verify(Plug.Conn.t() | binary(), __MODULE__.t()) ::
          verify_result()
  def verify(conn = %Plug.Conn{}, config) do
    header = Plug.Conn.get_req_header(conn, "cf-access-jwt-assertion")

    case header do
      [application_token] -> verify(application_token, config)
      [] -> {:error, :header_not_found}
      _ -> {:error, :multiple_headers_found}
    end
  end

  def verify(application_token, verifier) do
    joken_result =
      Joken.verify_and_validate(
        token_config(),
        application_token,
        nil,
        verifier,
        hooks(verifier)
      )

    joken_result |> to_verify_result()
  end

  defp to_verify_result(joken_result) do
    case joken_result do
      {:ok, claims = %{"sub" => ""}} ->
        Logger.debug("Cloudflare Access application token is anonymous: #{log_inspect(claims)}")
        {:ok, :anonymous}

      {:ok, claims = %{"sub" => sub, "email" => email}} when email != "" ->
        user = {:user, %{id: sub, email: email}}
        Logger.debug("Cloudflare Access application token is for user #{log_inspect(claims)}")
        {:ok, user}

      {:ok, claims} ->
        Logger.warning(
          "Cloudflare Access application token did not have expected claims #{log_inspect(claims)}"
        )

        {:error, [message: "Invalid token", claims: claims]}

      error ->
        Logger.warning("Cloudflare Access error #{inspect(error)}")
        error
    end
  end

  defp token_config() do
    Joken.Config.default_claims(skip: [:jti, :iss, :aud])
    # Default audience claim does not verify against an array of audiences
    |> Joken.Config.add_claim("aud", nil, &verify_audience/3)
    |> Joken.Config.add_claim("iss", nil, &verify_issuer/3)
  end

  defp verify_audience(aud, _claims, %{audience: expected}) when is_list(aud),
    do: expected in aud

  defp verify_audience(aud, _claims, %{audience: expected})
       when is_binary(expected) and expected != "",
       do: expected == aud

  defp verify_audience(_, _, verifier),
    do: throw("Expected audience not provided on verifier: #{inspect(verifier)}")

  defp verify_issuer(iss, _claims, %{issuer: expected})
       when is_binary(expected) and expected != "",
       do: expected == iss

  defp verify_issuer(_, _, verifier),
    do: throw("Expected issuer not provided on verifier: #{inspect(verifier)}")

  defp hooks(verifier) do
    [
      {
        JokenJwks,
        strategy: verifier.jwks_strategy, domain: verifier.domain
      }
    ]
  end

  defp log_inspect(claims) do
    inspect(claims |> Map.delete("identity_nonce"))
  end
end
