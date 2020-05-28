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

  # Server callbacks

  @impl true
  def init(:ok) do
    {:ok, %DialerState{}}
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
        {:form, [Body: message, From: E.host_number(), To: "+15025551234"]},
        [],
        hackney: [basic_auth: {E.account_sid(), E.api_key()}]
      )

    body
    |> Jason.decode!()
    |> IO.inspect()

    {:noreply, state}
  end
end
