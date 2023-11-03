defmodule CloudflareAccessEx.AccessTokenVerifierTest do
  use ExUnit.Case, async: true

  alias CloudflareAccessEx.JwksStrategy

  # Importing the test subject
  alias CloudflareAccessEx.AccessTokenVerifier
  alias CloudflareAccessEx.Test.Simulator

  doctest(CloudflareAccessEx.AccessTokenVerifier)

  setup %{} do
    :ok = Simulator.start_test_server()

    {:ok, _} = start_supervised({JwksStrategy, [domain: Simulator.domain()]})
    JwksStrategy.ready?(Simulator.domain())

    verifier =
      AccessTokenVerifier.create(
        domain: Simulator.domain(),
        audience: Simulator.audience()
      )

    {:ok, verifier: verifier}
  end

  test "create/1 :atom reads config from application" do
    :ok =
      Application.put_env(:cloudflare_access_ex, :example,
        domain: "example.com",
        audience: "audience_string"
      )

    verifier = AccessTokenVerifier.create(:example)

    assert verifier.domain == "example.com"
    assert verifier.audience == "audience_string"
    assert verifier.issuer == "https://example.com"
  end

  @tag start_simulator: true
  test "extracts token from plug conn", %{verifier: verifier} do
    token = Simulator.create_access_token()

    conn = %Plug.Conn{req_headers: [{"cf-access-jwt-assertion", token}]}

    assert AccessTokenVerifier.verify(conn, verifier) ==
             {:ok, Simulator.user()}
  end

  test "errors if header missing from plug conn", %{verifier: verifier} do
    conn = %Plug.Conn{req_headers: []}

    assert AccessTokenVerifier.verify(conn, verifier) ==
             {:error, :header_not_found}
  end

  test "errors if multiple headers on plug conn", %{verifier: verifier} do
    token = Simulator.create_access_token()

    conn = %Plug.Conn{
      req_headers: [
        {"cf-access-jwt-assertion", token},
        {"cf-access-jwt-assertion", token}
      ]
    }

    assert AccessTokenVerifier.verify(conn, verifier) ==
             {:error, :multiple_headers_found}
  end

  @tag start_simulator: true
  test "valid token", %{verifier: verifier} do
    token = Simulator.create_access_token()

    assert AccessTokenVerifier.verify(token, verifier) ==
             {:ok, Simulator.user()}
  end

  @tag start_simulator: true
  test "anonymous token", %{verifier: verifier} do
    token = Simulator.create_access_token(anonymous: true)

    assert AccessTokenVerifier.verify(token, verifier) ==
             {:ok, :anonymous}
  end

  @tag start_simulator: true
  test "valid token with aud array", %{verifier: verifier} do
    audience = [Simulator.audience()]
    token = Simulator.create_access_token(audience: audience)

    assert AccessTokenVerifier.verify(token, verifier) ==
             {:ok, Simulator.user()}
  end

  @tag start_simulator: true
  test "valid token with multiple audiences", %{verifier: verifier} do
    audience = ["another_aud", verifier.audience]
    token = Simulator.create_access_token(audience: audience)

    assert AccessTokenVerifier.verify(token, verifier) ==
             {:ok, Simulator.user()}
  end

  @tag start_simulator: true
  test "incorrect audience", %{verifier: verifier} do
    audience = "wrong_audience"
    token = Simulator.create_access_token(audience: audience)

    assert AccessTokenVerifier.verify(token, verifier) ==
             {:error, [message: "Invalid token", claim: "aud", claim_val: audience]}
  end

  @tag start_simulator: true
  test "audience not in array", %{verifier: verifier} do
    audience = ["wrong_audience", "another_wrong_audience"]
    token = Simulator.create_access_token(audience: audience)

    assert AccessTokenVerifier.verify(token, verifier) ==
             {:error, [message: "Invalid token", claim: "aud", claim_val: audience]}
  end

  @tag start_simulator: true
  test "incorrect issuer", %{verifier: verifier} do
    issuer = "wrong_issuer"
    token = Simulator.create_access_token(iss: issuer)

    assert AccessTokenVerifier.verify(token, verifier) ==
             {:error, [message: "Invalid token", claim: "iss", claim_val: issuer]}
  end

  test "malformed token", %{verifier: verifier} do
    token = Simulator.create_access_token() |> String.replace(".", "")

    assert AccessTokenVerifier.verify(token, verifier) == {:error, :token_malformed}
  end

  @tag start_simulator: true
  test "invalid signature", %{verifier: verifier} do
    # change the last char in the signature at the end of the token
    # (still valid base64, but invalid signature)
    token =
      Simulator.create_access_token()
      |> String.graphemes()
      |> Enum.reverse()
      |> Kernel.then(fn
        ["A" | rest] -> ["q" | rest]
        [_ | rest] -> ["A" | rest]
      end)
      |> Enum.reverse()
      |> Enum.join()

    assert {:error, :signature_error} = AccessTokenVerifier.verify(token, verifier)
  end
end
