defmodule IncomingDialer.Templates do
  @moduledoc false

  def incoming_call do
    """
    <?xml version="1.0" encoding="UTF-8" ?>
    <Response>  
      <%= if fallback do %>
        <Say voice="alice" ><%= fallback_message %></Say>
      <% else %>
        <Dial action=<%= action_url %>><%= number %></Dial>
      <% end %>
    </Response>
    """
  end
end
