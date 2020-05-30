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

  describe "set_incoming_numbers" do
    test "sets the list of incoming numbers", %{dialer: d} do
      before_nums = ["5025551234", "5025551235"]
      IncomingDialer.set_incoming_numbers(d, before_nums) 
      %{incoming_numbers: nums} = :sys.get_state(d)
      assert nums == before_nums
    end
  end

  describe "send_sms" do
    test "sends an sms", %{dialer: d} do
      :ok = IncomingDialer.send_sms(d, "message", "502-555-1354")
      state = :sys.get_state(d)
    end
  end

  describe "incoming_call" do
    test "", %{dialer: d} do

      twiml = IncomingDialer.incoming_call(d, %{})
    end
  end
end
