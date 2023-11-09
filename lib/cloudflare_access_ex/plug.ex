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

  alias CloudflareAccessEx.ApplicationTokenVerifier

  @behaviour Plug

  @doc false
  @impl Plug
  def init(opts), do: opts

  @doc """
  Verifies the Cloudflare Access application token.

  It will reject the request with 401 (Unauthorized) if the token is invalid
  or if the token is anonymous and anonymous access is not allowed.

  If the token is valid, the current user will be set in the conn's private map
  and can be accessed via `CloudflareAccessEx.Plug.current_user/1`.
  """
  @impl Plug
  def call(conn, opts) do
    verifier = ApplicationTokenVerifier.create(opts[:cfa_app])

    case ApplicationTokenVerifier.verify(conn, verifier) do
      {:ok, token} -> verified(conn, token, opts[:allow_anonymous] || false)
      {:error, _} -> unauthorized(conn)
    end
  end

  @spec current_user(Plug.Conn.t()) :: ApplicationTokenVerifier.verified_token()
  @doc """
  Returns the current user. Will raise if executed on a request that has not passed through the plug
  or if the plug has rejected the request.
  """
  def current_user(conn) do
    conn.private[:cloudflare_access_ex_application_token] ||
      raise "current_user/1 called on a request that has not passed successfully through CloudflareAccessEx.Plug"
  end

  defp verified(conn, token, allow_anonymous) do
    case {token, allow_anonymous} do
      {:anonymous, true} ->
        authorized(conn, token)

      {:anonymous, false} ->
        Logger.warn("Anonymous access has been disabled in this application")
        unauthorized(conn)

      _ ->
        authorized(conn, token)
    end
  end

  defp authorized(conn, application_token) do
    conn
    |> Plug.Conn.put_private(:cloudflare_access_ex_application_token, application_token)
  end

  defp unauthorized(conn) do
    conn
    |> Plug.Conn.put_private(:cloudflare_access_ex_application_token, nil)
    |> Plug.Conn.resp(401, "401 Unauthorized")
    |> Plug.Conn.halt()
  end
end
