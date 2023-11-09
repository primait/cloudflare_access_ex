defmodule CloudflareAccessEx.PlugTest do
  use ExUnit.Case, async: true

  alias CloudflareAccessEx.{JwksStrategy, Principal}
  alias CloudflareAccessEx.Test.Simulator

  test "get_principal/1 raises if plug not executed" do
    conn = %Plug.Conn{}

    assert_raise RuntimeError, fn ->
      CloudflareAccessEx.Plug.get_principal(conn)
    end
  end

  describe "with simulator" do
    setup [:start_simulator]

    @tag start_simulator: true
    test "extracts token from plug conn", %{cfa_app: cfa_app} do
      token = Simulator.create_application_token()

      conn = %Plug.Conn{req_headers: [{"cf-access-jwt-assertion", token}]}

      conn = CloudflareAccessEx.Plug.call(conn, cfa_app: cfa_app)

      assert CloudflareAccessEx.Plug.get_principal(conn) == Simulator.user()
      refute conn.halted
    end

    @tag start_simulator: true
    test "errors if header missing from plug conn", %{cfa_app: cfa_app} do
      conn = %Plug.Conn{req_headers: []}

      conn = CloudflareAccessEx.Plug.call(conn, cfa_app: cfa_app)

      assert conn.status == 401
      assert conn.halted

      assert_raise RuntimeError, fn ->
        CloudflareAccessEx.Plug.get_principal(conn)
      end
    end

    @tag start_simulator: true
    test "anonymous token is allowed when enabled", %{cfa_app: cfa_app} do
      token = Simulator.create_application_token(anonymous: true)
      conn = %Plug.Conn{req_headers: [{"cf-access-jwt-assertion", token}]}

      conn = CloudflareAccessEx.Plug.call(conn, cfa_app: cfa_app, allow_anonymous: true)

      assert CloudflareAccessEx.Plug.get_principal(conn) == Principal.anonymous()
      refute conn.halted
    end

    test "anonymous token is denied when disabled", %{cfa_app: cfa_app} do
      token = Simulator.create_application_token(anonymous: true)
      conn = %Plug.Conn{req_headers: [{"cf-access-jwt-assertion", token}]}

      conn = CloudflareAccessEx.Plug.call(conn, cfa_app: cfa_app, allow_anonymous: false)

      assert conn.halted
      assert conn.status == 401

      assert_raise RuntimeError, fn ->
        CloudflareAccessEx.Plug.get_principal(conn)
      end
    end
  end

  def start_simulator(_) do
    :ok = Simulator.start_test_server()

    {:ok, _} = start_supervised({JwksStrategy, [domain: Simulator.domain()]})
    JwksStrategy.ready?(Simulator.domain())

    cfa_app = [
      domain: Simulator.domain(),
      audience: Simulator.audience()
    ]

    [cfa_app: cfa_app]
  end
end
