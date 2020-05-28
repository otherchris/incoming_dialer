defmodule IncomingDialerTest do
  @moduledoc false

  use ExUnit.Case
  doctest IncomingDialer

  alias IncomingDialer.DialerState

  setup do
    dialer = start_supervised!(IncomingDialer)
    %{dialer: dialer}
  end

  describe "report" do
    test "reports the state of the dialer", %{dialer: d} do
      %DialerState{} = IncomingDialer.report(d)
    end
  end

  describe "send_sms" do
    test "sends an sms", %{dialer: d} do
      :ok = IncomingDialer.send_sms(d, "message", "phonenumber")
      state = :sys.get_state(d)
    end
  end
end
