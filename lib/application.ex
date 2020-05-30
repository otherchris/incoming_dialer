defmodule IncomingDialer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Sumthin.Worker.start_link(arg)
      # {Sumthin.Worker, arg}
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: IncomingDialer.Endpoint,
        options: [port: 4000]
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IncomingDialer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
