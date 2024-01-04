defmodule CloudflareAccessEx.Plug do
  @moduledoc """
  This plug is responsible for blocking requets that do not have a valid
  Cloudflare Access application token.

  ## Examples

      plug CloudflareAccessEx.Plug, cfa_app: :my_cfa_app

  To allow anonymous tokens, use the following:

      plug CloudflareAccessEx.Plug, cfa_app: :my_cfa_app, allow_anonymous: true
  """
  require Logger
  import Plug.ErrorHandler

  alias CloudflareAccessEx.{ApplicationTokenVerifier, Principal}

  @behaviour Plug

  @doc false
  @impl Plug
  def init(opts), do: opts

  @doc """
  Verifies the Cloudflare Access application token.

  It will reject the request with 403 (Forbidden) if the token is invalid
  or if the token is anonymous and anonymous access is not allowed.

  If the token is valid, the principal will be set in the conn's private map
  and can be accessed via `CloudflareAccessEx.Plug.get_principal/1`.
  """
  @impl Plug
  def call(conn, opts) do
    verifier = ApplicationTokenVerifier.create(opts[:cfa_app])

    case ApplicationTokenVerifier.verify(conn, verifier) do
      {:ok, token} -> verified(conn, token, opts[:allow_anonymous] || false)
      {:error, _} -> forbidden(conn)
    end
  end

  @spec get_principal(Plug.Conn.t()) :: Principal.t()
  @doc """
  Returns the principal. Will raise if executed on a request that has not passed through the plug
  or if the plug has rejected the request.
  """
  def get_principal(conn) do
    conn.private[:cloudflare_access_ex_principal] ||
      raise "get_principal/1 called on a request that has not passed successfully through CloudflareAccessEx.Plug"
  end

  defp verified(conn, principal, allow_anonymous) do
    case {principal, allow_anonymous} do
      {%Principal{type: :anonymous}, true} ->
        authorized(conn, principal)

      {%Principal{type: :anonymous}, false} ->
        Logger.warn("Anonymous access has been disabled in this application")
        forbidden(conn)

      _ ->
        authorized(conn, principal)
    end
  end

  defp authorized(conn, principal) do
    conn
    |> Plug.Conn.put_private(:cloudflare_access_ex_principal, principal)
  end

  defp forbidden(conn) do
    conn
    |> Plug.Conn.put_private(:cloudflare_access_ex_principal, nil)
    |> Plug.Conn.resp(403, "403 Forbidden")
    |> Plug.Conn.halt()
  end
end
