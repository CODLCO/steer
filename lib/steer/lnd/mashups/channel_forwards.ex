defmodule Steer.Mashups.ChannelForwards do
  def combine(channels, forwards) do
    channels
    |> add_empty_raw_forward_list
    |> add_empty_forward_list
    |> convert_channel_list_to_map
    |> add_forwards_to_channels(forwards)
    |> add_channels_to_forwards(forwards)
    |> map_to_list
    |> sort_forwards
    |> set_latest_forward_field
  end

  defp add_channels_to_forwards(channel_map, forwards) do
    forwards
    |> Enum.reduce(channel_map, fn forward, channel_map ->
      channel_in = Map.get(channel_map, forward.chan_id_in)
      channel_out = Map.get(channel_map, forward.chan_id_out)

      forward = forward
      |> Map.put(:channel_in, channel_in)
      |> Map.put(:channel_out, channel_out)

      channel_in = channel_in
      |> Map.put(:forwards, [forward | channel_in.forwards])

      channel_out = channel_out
      |> Map.put(:forwards, [forward | channel_out.forwards])

      channel_map
      |> Map.put(channel_in.id, channel_in)
      |> Map.put(channel_out.id, channel_out)
    end)
  end

  defp add_forwards_to_channels(channel_map, forwards) do
    channel_map
    |> add_raw_forwards_to_channels(forwards, :chan_id_in)
    |> add_raw_forwards_to_channels(forwards, :chan_id_out)
  end

  defp add_raw_forwards_to_channels(channel_map, forwards, direction) do
    forwards
    |> Enum.reduce(channel_map, fn forward, channel_map ->
      channel_id = Map.get(forward, direction)
      channel = Map.get(channel_map, channel_id)

      channel_map
      |> maybe_add_raw_forward(channel, forward)
    end)
  end

  defp maybe_add_raw_forward(channel_map, nil, _) do
    channel_map
  end

  defp maybe_add_raw_forward(channel_map, channel, forward) do
    channel = channel_map |> Map.get(channel.id)

    channel_map
    |> maybe_add_raw_forward_to_map(channel, forward)
  end

  defp maybe_add_raw_forward_to_map(channel_map, nil, _) do
    channel_map
  end

  defp maybe_add_raw_forward_to_map(channel_map, channel, forward) do
    new_channel = channel
    |> Map.put(:raw_forwards, [forward | channel.forwards])

    channel_map
    |> Map.put(channel.id, new_channel)
  end

  defp add_empty_raw_forward_list(channels) do
    channels
    |> Enum.map(fn channel ->
      channel
      |> Map.put(:raw_forwards, [])
    end)
  end

  defp add_empty_forward_list(channels) do
    channels
    |> Enum.map(fn channel ->
      channel
      |> Map.put(:forwards, [])
    end)
  end

  defp convert_channel_list_to_map(channels) do
    channels
    |> Enum.reduce(%{}, fn channel, acc ->
      acc
      |> Map.put(channel.id, channel)
    end)
  end

  defp map_to_list(channel_map) do
    channel_map
    |> Map.values()
  end

  defp sort_forwards(channels) do
    channels
    |> Enum.map(fn channel ->
      sorted_forwards = channel.forwards
      |> Enum.sort(&(&1.timestamp >= &2.timestamp))

      channel
      |> Map.put(:forwards, sorted_forwards)
    end)
  end

  defp set_latest_forward_field(channels) do
    channels
    |> Enum.map(fn channel ->
      case Enum.any?(channel.forwards) do
        true ->
          [ latest_forward | _ ] = channel.forwards
          channel |> Map.put(:latest_forward, latest_forward)
        false ->
          channel
      end
    end)
  end
end