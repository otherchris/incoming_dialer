defmodule IncomingDialer do
  @moduledoc """
  Documentation for `IncomingDialer`.
  """

  use GenServer
  alias IncomingDialer.DialerState
  alias IncomingDialer.Environment, as: E

  import SweetXml

  # Client API

  @doc """
  Start the dialer
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def report(dialer) do
    GenServer.call(dialer, :report)
  end

  def send_sms(dialer, message, phone_number) do
    GenServer.cast(dialer, {:send_sms, message, phone_number})
  end

  def incoming_call(dialer, call_data) do
    GenServer.call(dialer, {:incoming_call, call_data})
  end

  # Server callbacks

  @impl true
  def init(:ok) do
    {:ok, %DialerState{}}
  end

  def handle_call({:incoming_call, call_data}, _from, state) do
    resp = """
    <?xml version=”1.0" encoding=”UTF-8" ?>
    <Response>
      <Say>Hamburger Bambuger</Say>
    </Response>
    """
    {:reply, resp, state}
  end

  @impl true
  def handle_call(:report, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:send_sms, message, phone_number}, state) do
    {:ok, %{body: body}} =
      HTTPoison.post(
        E.sms_url(),
        {:form, [Body: message, From: E.from_number(), To: phone_number]},
        [],
        hackney: [basic_auth: {E.account_sid(), E.api_key()}]
      )

    body
    |> Jason.decode!()
    |> IO.inspect()

    {:noreply, state}
  end
end
