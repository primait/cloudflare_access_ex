defmodule CloudflareAccessEx.Support.RSAGenerator do
  @moduledoc """
    Copied from [this gist](https://gist.github.com/InoMurko/aae72fa8e1773556ee4e7b6eb6cf1801)

    Generates an RSA key pair by calling "openssl genrsa 2048" and parsing the output.
  """
  @spec generate_rsa :: map()
  def generate_rsa() do
    port = Port.open({:spawn, "openssl genrsa 2048"}, [:binary])

    priv_key_string =
      receive do
        {^port, {:data, data}} ->
          data
      end

    Port.close(port)
    [pem_entry] = :public_key.pem_decode(priv_key_string)
    pub_key = :public_key.pem_entry_decode(pem_entry) |> public_key

    pub_key_string =
      :public_key.pem_encode([:public_key.pem_entry_encode(:RSAPublicKey, pub_key)])

    %{private: priv_key_string, public: pub_key_string}
  end

  defp public_key({:RSAPrivateKey, _, modulus, public_exponent, _, _, _, _, _, _, _}) do
    {:RSAPublicKey, modulus, public_exponent}
  end
end
