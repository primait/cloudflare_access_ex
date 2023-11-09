defmodule CloudflareAccessEx.PlugTest do
  use ExUnit.Case, async: true

  alias CloudflareAccessEx.JwksStrategy

  # Importing the test subject
  alias CloudflareAccessEx.Plug, as: CloudflareAccessExPlug
  alias CloudflareAccessEx.Test.Simulator

  test "current_user/1 raises if plug not executed" do
    conn = %Plug.Conn{}

    assert_raise RuntimeError, fn ->
      CloudflareAccessExPlug.current_user(conn)
    end
  end

  describe "with simulator" do
    setup [:start_simulator]

    @tag start_simulator: true
    test "extracts token from plug conn", %{cfa_app: cfa_app} do
      token = Simulator.create_application_token()

      conn = %Plug.Conn{req_headers: [{"cf-access-jwt-assertion", token}]}

      conn = CloudflareAccessExPlug.call(conn, cfa_app: cfa_app)

      assert CloudflareAccessExPlug.current_user(conn) == Simulator.user()
      refute conn.halted
    end

    @tag start_simulator: true
    test "errors if header missing from plug conn", %{cfa_app: cfa_app} do
      conn = %Plug.Conn{req_headers: []}

      conn = CloudflareAccessExPlug.call(conn, cfa_app: cfa_app)

      assert conn.status == 401
      assert conn.halted

      assert_raise RuntimeError, fn ->
        CloudflareAccessExPlug.current_user(conn)
      end
    end

    @tag start_simulator: true
    test "anonymous token is allowed when enabled", %{cfa_app: cfa_app} do
      token = Simulator.create_application_token(anonymous: true)
      conn = %Plug.Conn{req_headers: [{"cf-access-jwt-assertion", token}]}

      conn = CloudflareAccessExPlug.call(conn, cfa_app: cfa_app, allow_anonymous: true)

      assert CloudflareAccessExPlug.current_user(conn) == :anonymous
      refute conn.halted
    end

    test "anonymous token is denied when disabled", %{cfa_app: cfa_app} do
      token = Simulator.create_application_token(anonymous: true)
      conn = %Plug.Conn{req_headers: [{"cf-access-jwt-assertion", token}]}

      conn = CloudflareAccessExPlug.call(conn, cfa_app: cfa_app, allow_anonymous: false)

      assert conn.halted
      assert conn.status == 401

      assert_raise RuntimeError, fn ->
        CloudflareAccessExPlug.current_user(conn)
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
