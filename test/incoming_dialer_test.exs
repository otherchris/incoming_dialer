defmodule IncomingDialerTest do
  @moduledoc false

  use ExUnit.Case
  doctest IncomingDialer

  alias IncomingDialer.DialerState

  @before_nums ["5025551234", "5025551235"]
  @incoming_call_data %{
    "CallSid" => "CAd751de46b9ad916470d2840221134936",
    "CallStatus" => "ringing"
  }
  @end_call_data %{
    "CallSid" => "CAd751de46b9ad916470d2840221134936",
    "CallStatus" => "ended"
  }

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

  describe "end call" do
    test "removes call from in progress calls", %{dialer: d} do
      IncomingDialer.set_incoming_numbers(d, @before_nums)
      :sys.get_state(d)
      IncomingDialer.incoming_call(d, @incoming_call_data)
      :sys.get_state(d)
      IncomingDialer.end_call(d, @end_call_data)
      %{calls_in_progress: cip} = :sys.get_state(d)
      assert cip == []
    end
  end

  describe "incoming_call" do
    test "adds call to in progress calls", %{dialer: d} do
      IncomingDialer.set_incoming_numbers(d, @before_nums)
      :sys.get_state(d)
      IncomingDialer.incoming_call(d, @incoming_call_data)
      %{calls_in_progress: [call]} = :sys.get_state(d)
      assert call.to == @before_nums |> hd
      assert call.ref_id == @incoming_call_data["CallSid"]
    end

    test "adds number applied to numbers_in_use", %{dialer: d} do
      IncomingDialer.set_incoming_numbers(d, @before_nums)
      :sys.get_state(d)
      IncomingDialer.incoming_call(d, @incoming_call_data)
      %{numbers_in_use: niu} = :sys.get_state(d)
      assert niu == [@before_nums |> hd]
    end

    test "returns twiml", %{dialer: d} do
      IncomingDialer.set_incoming_numbers(d, @before_nums)
      :sys.get_state(d)
      twiml = IncomingDialer.incoming_call(d, @incoming_call_data)
      assert twiml =~ "xml"
      assert twiml =~ "Dial"
      assert twiml =~ @before_nums |> hd
    end

    test "if no numbers, fallback", %{dialer: d} do
      twiml = IncomingDialer.incoming_call(d, @incoming_call_data)
      assert twiml =~ "xml"
      assert twiml =~ "Say"
    end

    test "if first number is in use, use second", %{dialer: d} do
      IncomingDialer.set_incoming_numbers(d, @before_nums)
      :sys.get_state(d)
      IncomingDialer.incoming_call(d, @incoming_call_data) |> IO.inspect
      :sys.get_state(d)
      IncomingDialer.incoming_call(d, @incoming_call_data)
      %{calls_in_progress: cip} = :sys.get_state(d)
      assert List.last(cip).to == List.last(@before_nums)
    end
  end
end
