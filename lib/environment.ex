defmodule IncomingDialer.Environment do
  @moduledoc false

  def account_sid(), do: Application.get_env(:incoming_dialer, :account_sid)
  def api_key(), do: Application.get_env(:incoming_dialer, :api_key)
  def base_url(), do: "https://api.twilio.com/2010-04-01/Accounts/#{account_sid()}/"
  def sms_url(), do: "#{base_url}Messages.json"
  def host_number(), do: "+15005550006"
end
