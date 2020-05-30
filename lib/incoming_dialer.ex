defmodule IncomingDialer do
  @moduledoc """
  Documentation for `IncomingDialer`.
  """

  use GenServer
  alias IncomingDialer.DialerState
  alias IncomingDialer.Environment, as: E
  alias IncomingDialer.Templates, as: T

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

  def set_incoming_numbers(dialer, nums) when is_list(nums) do
    GenServer.cast(dialer, {:set_incoming_numbers, nums})
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

  def handle_call({:incoming_call, call_data}, _from, state = %{incoming_numbers: []}) do
    resp = EEx.eval_string(T.incoming_call, state.incoming_call_assigns)
    {:reply, resp, state}
  end

  def handle_call({:incoming_call, call_data}, _from, state = %{incoming_numbers: inc_nums}) do
    {resp, to_num} = 
      with [to_num | _] <- Enum.reject(inc_nums, &number_in_use(state.calls_in_progress, &1)) do
        {
          EEx.eval_string(T.incoming_call, incoming_template_data([fallback: false, number: to_num])),
          to_num
        }
      else
        _ -> {EEx.eval_string(T.incoming_call, incoming_template_data([])), ""}
      end
    new_call = %{
      to: to_num,
      ref_id: call_data["CallSid"]
    }
    {:reply, resp, state, {:continue, {:new_call, new_call}}}
  end

  @impl true
  def handle_call(:report, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_continue({:new_call, new_call}, state = %{calls_in_progress: cip, numbers_in_use: niu}) do
    new_state = %{
      calls_in_progress: cip ++ [new_call],
      numbers_in_use: niu ++ [new_call.to]
    }
    {:noreply, Map.merge(state, new_state)}
  end

  @impl true
  def handle_cast({:set_incoming_numbers, nums}, state) do
    {:noreply, Map.put(state, :incoming_numbers, nums)}
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

    {:noreply, state}
  end

  defp incoming_template_data(kwl) do
    default = [number: "", fallback: true, fallback_message: "no_number"]
    Keyword.merge(default, kwl)
  end

  defp number_in_use(call_list, number) do
    call_list
    |> Enum.find(&(&1.to == number))
    |> is_nil
    |> Kernel.!
  end
end
