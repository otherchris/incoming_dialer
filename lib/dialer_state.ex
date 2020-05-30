defmodule IncomingDialer.DialerState do
  @moduledoc false

  defstruct [
    incoming_voice_numbers: [],
    calls_in_progress: [],
    incoming_call_assigns: [
      number: "",
      fallback: true,
      fallback_message: "No numbers to call"
    ]
  ]
end
