defmodule SteerWeb.PageLive do
  use SteerWeb, :live_view

  alias SteerWeb.Endpoint

  @htlc_topic "htlc"
  @new_message "new"

  @invoice_topic "invoice"
  @created_message "created"
  @paid_message "paid"

  @channel_topic "channel"
  @open_message "open"
  @pending_message "pending"
  @closed_message "closed"
  @active_message "active"
  @inactive_message "inactive"

  @impl true
  def mount(_params, _session, socket) do
    socket = socket
    |> add_channels()

    {:ok, socket}
  end

  defp add_channels(socket) do
    if connected?(socket) do
      Endpoint.subscribe(@htlc_topic)
      Endpoint.subscribe(@invoice_topic)
      Endpoint.subscribe(@channel_topic)
    end

    channels = Steer.Lnd.get_all_channels()

    socket
    |> assign(:channels, channels)
  end

  @impl true
  def handle_event("toggle_forwards", %{"channel-id" => channel_id}, socket) do
    { channel_id, _ } = Integer.parse(channel_id)

    channels = socket.assigns.channels
    |> Enum.map(fn channel ->
      case channel.id do
        ^channel_id ->
          if channel.show_forwards do
            IO.puts "collapsing #{channel.alias}"
          else
            IO.puts "expanding #{channel.alias}"
          end

          channel |> Map.put(:show_forwards, !channel.show_forwards)
        _ -> channel
      end
    end)

    {:noreply, assign(socket, :channels, channels)}
  end

  @impl true
  def handle_info(%{
    topic: @htlc_topic,
    event: @new_message,
    payload: %Routerrpc.HtlcEvent{
      event_type: event_type
    } }, socket) do

    write_in_blue "New HTLC received: #{event_type}"
    write_in_blue ".... updating channels ...."

    channels = Steer.Lnd.get_all_channels()

    { :noreply, socket
      |> assign(:channels, channels)
      |> put_flash(:info, "New forward received")}
  end

  @impl true
  def handle_info(%{ topic: @invoice_topic, event: @created_message }, socket) do
    write_in_yellow "New invoice created"

    # nothing to be done, except maybe inform the user

    { :noreply, socket }
  end

  @impl true
  def handle_info(%{ topic: @invoice_topic, event: @paid_message }, socket) do
    write_in_yellow "New paid invoice received"
    write_in_yellow ".... updating channels ...."

    channels = Steer.Lnd.get_all_channels()

    { :noreply, socket
      |> assign(:channels, channels)
      |> put_flash(:info, "New forward received")}
  end

  @impl true
  def handle_info(%{ topic: @channel_topic, event: @open_message }, socket) do
    write_in_green "A new channel opened"
    write_in_green ".... NOT updating channels until active ...."

    ### would be nice to refresh the graph at that point, but it seems
    ### a channel refresh poses a problem before the channel becomes active
    ### so we wait at that point...

    { :noreply, socket }
  end

  @impl true
  def handle_info(%{ topic: @channel_topic, event: @pending_message }, socket) do
    write_in_green "A channel is pending..."

    { :noreply, socket }
  end

  @impl true
  def handle_info(%{ topic: @channel_topic, event: @closed_message }, socket) do
    write_in_green "A channel has been closed"
    write_in_green ".... updating channels ...."

    channels = Steer.Lnd.get_all_channels()

    { :noreply, socket
      |> assign(:channels, channels)
      |> put_flash(:info, "A channel has been closed")}
  end

  @impl true
  def handle_info(%{ topic: @channel_topic, event: @active_message }, socket) do
    write_in_green "A channel became active"
    write_in_green ".... updating channels in 5s ...."

    :timer.sleep 5000

    channels = Steer.Lnd.get_all_channels()

    { :noreply, socket
      |> assign(:channels, channels)
      |> put_flash(:info, "A channel became active")}
  end

  @impl true
  def handle_info(%{ topic: @channel_topic, event: @inactive_message }, socket) do
    write_in_green "A channel became inactive"
    write_in_green ".... updating channels ...."

    channels = Steer.Lnd.get_all_channels()

    { :noreply, socket
      |> assign(:channels, channels)
      |> put_flash(:info, "A channel became inactive")}
  end

  @impl true
  def handle_info(event, socket) do
    write_in_red "Unknown event received"

    IO.inspect event

    { :noreply, socket}
  end

  defp write_in_blue message do
    IO.puts(IO.ANSI.blue_background() <> IO.ANSI.black() <> message <> IO.ANSI.reset())
  end

  defp write_in_yellow message do
    IO.puts(IO.ANSI.yellow_background() <> IO.ANSI.black() <> message <> IO.ANSI.reset())
  end

  defp write_in_red message do
    IO.puts(IO.ANSI.red_background() <> IO.ANSI.black() <> message <> IO.ANSI.reset())
  end

  defp write_in_green message do
    IO.puts(IO.ANSI.green_background() <> IO.ANSI.black() <> message <> IO.ANSI.reset())
  end
end
