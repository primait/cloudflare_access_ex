defmodule CloudflareAccessEx.PlugTest do
  use ExUnit.Case, async: true

  alias CloudflareAccessEx.JwksStrategy

  # Importing the test subject
  alias CloudflareAccessEx.Plug, as: CloudflareAccessExPlug
  alias CloudflareAccessEx.Test.Simulator

  setup %{} do
    :ok = Simulator.start_test_server()

    {:ok, _} = start_supervised({JwksStrategy, [domain: Simulator.domain()]})
    JwksStrategy.ready?(Simulator.domain())

    cfa_app = [
      domain: Simulator.domain(),
      audience: Simulator.audience()
    ]

    {:ok, cfa_app: cfa_app}
  end

  @tag start_simulator: true
  test "extracts token from plug conn", %{cfa_app: cfa_app} do
    token = Simulator.create_application_token()

    conn = %Plug.Conn{req_headers: [{"cf-access-jwt-assertion", token}]}

    conn = CloudflareAccessExPlug.call(conn, cfa_app: cfa_app)

    refute conn.halted
  end

  test "errors if header missing from plug conn", %{cfa_app: cfa_app} do
    conn = %Plug.Conn{req_headers: []}

    conn = CloudflareAccessExPlug.call(conn, cfa_app: cfa_app)

    assert conn.status == 401
    assert conn.halted
  end

  describe "anonymous token" do
    @tag start_simulator: true
    test "is allowed when enabled", %{cfa_app: cfa_app} do
      token = Simulator.create_application_token(anonymous: true)
      conn = %Plug.Conn{req_headers: [{"cf-access-jwt-assertion", token}]}

      conn = CloudflareAccessExPlug.call(conn, cfa_app: cfa_app, allow_anonymous: true)

      refute conn.halted
    end

    @tag start_simulator: true
    test "is denied when disabled", %{cfa_app: cfa_app} do
      token = Simulator.create_application_token(anonymous: true)
      conn = %Plug.Conn{req_headers: [{"cf-access-jwt-assertion", token}]}

      conn = CloudflareAccessExPlug.call(conn, cfa_app: cfa_app, allow_anonymous: false)

      assert conn.halted
      assert conn.status == 401
    end
  end
end
