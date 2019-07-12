defmodule RateLimiter.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    RateLimiter.init()

    opts = [strategy: :one_for_one, name: RateLimiter.Supervisor]
    Supervisor.start_link([], opts)
  end
end
