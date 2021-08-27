defmodule SteerWeb.AttemptsLive do
  use SteerWeb, :live_view
  require Logger

  @impl true
  @spec mount(any, any, Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
