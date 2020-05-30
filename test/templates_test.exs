defmodule IncomingDialer.TemplatesTest do
  @moduledoc false

  use ExUnit.Case
  alias IncomingDialer.Templates, as: T

  describe "incoming call template" do
    test "with number" do
      EEx.eval_string(T.incoming_call, [fallback: false, number: "5025551234", fallback_message: "hey"])
      |> IO.puts
    end
    test "with fallback" do
      EEx.eval_string(T.incoming_call, [fallback: true, number: "5025551234", fallback_message: "hey"])
      |> IO.puts
    end
  end
end