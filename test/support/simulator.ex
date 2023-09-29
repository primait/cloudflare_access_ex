defmodule CloudflareAccessEx.Test.Simulator do
  @moduledoc """
  Simulates cloudflare certs endpoint using test server and creates
  access tokens that verify against those keys.
  """

  alias CloudflareAccessEx.Test.Signers

  @default_user_id "62fc3fd0-5ac8-11ee-8c99-0242ac120002"
  @default_user_email "test_user@example.com"
  @default_audience "a8d3b7..."
  @default_kid "2b34ecb..."

  def create_access_token(opts \\ []) do
    anonymous = Keyword.get(opts, :anonymous, false)
    sub = (anonymous && "") || Keyword.get(opts, :id, @default_user_id)
    email = Keyword.get(opts, :email, @default_user_email)
    iss = Keyword.get(opts, :iss, domain())
    kid = Keyword.get(opts, :kid, @default_kid)

    signer = Signers.create_signer(kid)
    joken_config = Joken.Config.default_claims(skip: [:jti, :iss, :aud])

    claims = %{
      "aud" => audience(opts),
      "iss" => iss,
      "sub" => sub
    }

    claims = (anonymous && claims) || Map.put(claims, "email", email)

    Joken.generate_and_sign!(
      joken_config,
      claims,
      signer,
      []
    )
  end

  def domain() do
    TestServer.url()
  end

  def audience(opts \\ []) do
    Keyword.get(opts, :audience, @default_audience)
  end

  def user(opts \\ []) do
    {:user,
     %{
       id: Keyword.get(opts, :id, @default_user_id),
       email: Keyword.get(opts, :email, @default_user_email)
     }}
  end

  def start_test_server() do
    start_test_server([Signers.create_jwk(@default_kid)])
  end

  def start_test_server(jwks) do
    TestServer.add("/cdn-cgi/access/certs",
      to: fn conn ->
        Plug.Conn.send_resp(
          conn,
          200,
          Jason.encode!(%{
            keys: jwks
          })
        )
      end
    )
  end
end
