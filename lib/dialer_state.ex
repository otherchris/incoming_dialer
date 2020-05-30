defmodule IncomingDialer.DialerState do
  @moduledoc false

  defstruct [
    incoming_call_assigns: [
      number: "",
      fallback: true,
      fallback_message: "No numbers to call"
    ]
  ]
end
