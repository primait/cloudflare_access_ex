defmodule CloudflareAccessEx.Test.Signers do
  @moduledoc "Utilities for generating signer and matching JWK"

  alias Joken.Signer
  alias CloudflareAccessEx.Support.RSAGenerator

  @key_pair RSAGenerator.generate_rsa()

  # Same alg as cloudflare currently uses
  @alg "RS256"

  def create_jwk(kid) do
    {_, from_pem} =
      @key_pair.public
      |> JOSE.JWK.from_pem()
      |> JOSE.JWK.to_map()

    from_pem
    |> Map.put("kid", kid)
    |> Map.put("alg", @alg)
    |> Map.put("use", "sig")
  end

  @doc """
  Create a signer that can encode tokens (i.e. it has the private key)
  """
  def create_signer(kid) do
    Signer.create(@alg, %{"pem" => @key_pair.private}, %{"kid" => kid})
  end
end
