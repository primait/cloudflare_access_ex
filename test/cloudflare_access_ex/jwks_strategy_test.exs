defmodule CloudflareAccessEx.JwksStrategyTest do
  use ExUnit.Case, async: true

  alias CloudflareAccessEx.JwksStrategy

  # Importing the test subject
  alias CloudflareAccessEx.ApplicationTokenVerifier
  alias CloudflareAccessEx.Test.Simulator

  # Yes, we're testing the GenServer callback. No we shouldn't really be doing this.
  # But it's a good way to test the behaviour of the module.
  test "handles invalid response from cloudflare" do
    :ok = Simulator.start_broken_test_server()

    # We set the retry time to 0ms and the poll time to 60 seconds, this means that the message we receive in the
    # assert_receive is for the retry, not for regular polling.
    {:ok, state, _} =
      CloudflareAccessEx.JwksStrategy.init(
        domain: Simulator.domain(),
        poll_retry_time_ms: 0,
        poll_time_ms: 60_000
      )

    assert {:noreply, _} = CloudflareAccessEx.JwksStrategy.handle_continue(:update_signers, state)

    assert_receive :update_signers, 100
  end

  test "handles valid response from cloudflare" do
    :ok = Simulator.start_test_server()

    # See the previous comment for how/why this works.
    {:ok, state, _} =
      CloudflareAccessEx.JwksStrategy.init(
        domain: Simulator.domain(),
        poll_time_ms: 0,
        poll_retry_time_ms: 60_000
      )

    assert {:noreply, _} = CloudflareAccessEx.JwksStrategy.handle_continue(:update_signers, state)

    assert_receive :update_signers, 100
  end
end
