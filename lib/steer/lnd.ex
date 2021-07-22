defmodule Steer.Lnd do
  alias Steer.Lnd.{Channel, Forward}

  def get_all_channels(args \\ [{:order_by, :local_balance}]) do
    get_lnd_channels()
    |> Channel.convert(args)
    |> add_node_info()
    |> maybe_include_forwards()
  end

  def get_all_forwards() do
    get_lnd_forwards()
    |> Forward.convert()
  end

  defp get_lnd_channels() do
    LndClient.get_channels().channels
  end

  defp get_lnd_forwards() do
    LndClient.get_forwarding_history(%{max_events: 1000}).forwarding_events
  end

  defp maybe_include_forwards(channels) do
    forwards = get_lnd_forwards()
    |> Forward.convert()

    channels
    |> Channel.combine_forwards(forwards)
  end

  defp add_node_info(channels) do
    channels
    |> Enum.map(fn channel ->
      node_info = LndClient.get_node_info(channel.node_pubkey)

      channel
      |> Channel.add_node_info(node_info.node)
    end)
  end
end
