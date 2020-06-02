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
  def start_link(initial, opts) do
    GenServer.start_link(__MODULE__, initial, opts)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Returns the state of the dialer
  """
  @spec report(pid) :: DialerState.t()
  def report(dialer) do
    GenServer.call(dialer, :report)
  end

  @doc """
  Set the incoming_numbers filed in the dialer state. These are the numbers that
  will receive incoming calls
  """
  @spec set_incoming_numbers(pid, list(String.t())) :: :ok
  def set_incoming_numbers(dialer, nums) when is_list(nums) do
    GenServer.cast(dialer, {:set_incoming_numbers, nums})
  end

  @doc """
  Remove a number from the list of answering numbers
  """
  @spec remove_incoming_number(pid, String.t()) :: :ok
  def remove_incoming_number(dialer, number) do
    GenServer.cast(dialer, {:remove_incoming_number, number})
  end

  @doc """
  Add a number to the list of answering numbers
  """
  @spec add_incoming_number(pid, String.t()) :: :ok
  def add_incoming_number(dialer, number) do
    GenServer.cast(dialer, {:add_incoming_number, number})
  end

  @doc """
  Send an sms message
  """
  @spec send_sms(pid, String.t(), String.t()) :: :ok
  def send_sms(dialer, message, phone_number) do
    GenServer.cast(dialer, {:send_sms, message, phone_number})
  end

  @doc """
  Handle the incoming call webhook
  """
  @spec incoming_call(pid, map) :: DialerState.t()
  def incoming_call(dialer, call_data) do
    GenServer.call(dialer, {:incoming_call, call_data})
  end

  @doc """
  Handle the end call webhook
  """
  def end_call(dialer, end_call_data) do
    GenServer.call(dialer, {:end_call, end_call_data})
  end

  # Server callbacks

  @impl true
  def init(:ok) do
    {:ok, %DialerState{}}
  end

  @impl true
  def init(initial) do
    {:ok, struct(%DialerState{}, initial)}
  end

  def handle_call({:incoming_call, call_data}, _from, state = %{incoming_numbers: []}) do
    resp = EEx.eval_string(T.incoming_call(), state.incoming_call_assigns)
    {:reply, resp, state}
  end

  def handle_call({:incoming_call, call_data}, _from, state = %{incoming_numbers: inc_nums}) do
    {resp, to_num} =
      with [to_num | _] <- Enum.reject(inc_nums, &Enum.member?(state.numbers_in_use, &1)) do
        {
          EEx.eval_string(
            T.incoming_call(),
            incoming_template_data(fallback: false, number: to_num, action_url: end_call_url(state, to_num))
          ),
          to_num
        }
      else
        _ -> {EEx.eval_string(T.incoming_call(), incoming_template_data([])), ""}
      end

    new_call = %{
      to: to_num,
      ref_id: call_data["CallSid"]
    }

    {:reply, resp, state, {:continue, {:new_call, new_call}}}
  end

  def handle_call({:end_call, call_data}, _from, state) do
    call_number = call_data["call_number"]
    new_niu = Enum.reject(state.numbers_in_use, &(&1 == call_number))
    new_state =
      state
      |> Map.put(:numbers_in_use, new_niu)
    {:reply, nil, new_state}
  end

  @impl true
  def handle_call(:report, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_continue(
        {:new_call, new_call},
        state = %{calls_in_progress: cip, numbers_in_use: niu}
      ) do
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
  def handle_cast({:add_incoming_number, number}, state = %{incoming_numbers: inc_nums}) do
    new = 
      inc_nums
      |> Kernel.++([number])
      |> Enum.uniq
    {:noreply, Map.put(state, :incoming_numbers, new)}
  end

  @impl true
  def handle_cast({:remove_incoming_number, number}, state = %{incoming_numbers: inc_nums}) do
    new = Enum.reject(inc_nums, &(&1 == number))
    {:noreply, Map.put(state, :incoming_numbers, new)}
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
    default = [number: "", fallback: true, fallback_message: "no_number", action_url: "hello"]
    Keyword.merge(default, kwl)
  end

  defp end_call_url(state, number) do
    "#{state.url_base}/end-call/#{number}"
  end
end
