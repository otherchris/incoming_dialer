defmodule IncomingDialer.Templates do
@moduledoc false

  def incoming_call do
    """
    <?xml version="1.0" encoding="UTF-8" ?>
    <Response>  
      <%= if fallback do %>
        <Say voice="alice" ><%= fallback_message %></Say>
      <% else %>
        <Dial><%= number %></Dial>
      <% end %>
    </Response>
    """
  end
end