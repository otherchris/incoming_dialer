defmodule IncomingDialer.Endpoint do
    @moduledoc false
  
    use Plug.Router
  
    plug(Plug.Logger)
    plug(:match)
    plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
    plug(:dispatch)
  
    get "/ping" do
      send_resp(conn, 200, "pong!")
    end
  
    # A catchall route, 'match' will match no matter the request method,
    # so a response is always returned, even if there is no route to match.
    match _ do
      send_resp(conn, 404, "oops... Nothing here :(")
    end
  end