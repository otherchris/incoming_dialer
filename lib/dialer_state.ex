defmodule IncomingDialer.DialerState do
  @moduledoc false

  @type call :: %{
          to: string,
          ref_id: string,
          last_status: string
        }

  defstruct incoming_numbers: [],
            url_base: "",
            numbers_in_use: [],
            calls_in_progress: [],
            incoming_call_assigns: [
              number: "",
              fallback: true,
              fallback_message: "No numbers to call",
              action_url: "hello"
            ]
end
