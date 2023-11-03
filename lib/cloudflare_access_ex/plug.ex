defmodule CloudflareAccessEx.Plug do
  @moduledoc """
  This plug is responsible for verifying the Cloudflare Access JWT token
  and ensuring that it is valid.

  ## Examples

      plug CloudflareAccessEx.Plug, cfa_app: :my_cfa_app

  To allow anonymous tokens, use the following:

      plug CloudflareAccessEx.Plug, cfa_app: :my_cfa_app, allow_anonymous: true
  """
  require Logger
  import Plug.ErrorHandler

  @doc false
  def init(opts), do: opts

  @doc """
  This function is responsible for verifying the Cloudflare Access JWT token
  It will reject the request if the token is invalid or if the token is anonymous
  and anonymous access is not allowed.
  """
  def call(conn, opts) do
    verifier = CloudflareAccessEx.AccessTokenVerifier.create(opts[:cfa_app])

    case CloudflareAccessEx.AccessTokenVerifier.verify(conn, verifier) do
      {:ok, :anonymous} ->
        if Keyword.get(opts, :allow_anonymous, false) do
          conn
        else
          unauthorized(conn)
        end

      {:ok, _} ->
        conn

      _else ->
        unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
    |> Plug.Conn.resp(401, "401 Unauthorized")
    |> Plug.Conn.halt()
  end
end
