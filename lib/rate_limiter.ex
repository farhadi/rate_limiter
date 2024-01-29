defmodule RateLimiter do
  @moduledoc """
  A high performance rate limiter implemented on top of erlang `:atomics`
  which uses only atomic hardware instructions without any software level locking.
  As a result RateLimiter is ~20x faster than `ExRated` and ~80x faster than `Hammer`.
  """

  @ets_table Application.compile_env(:rate_limiter, :ets_table, :rate_limiters)

  @enforce_keys [:ref, :limit, :scale]
  defstruct [:id, :ref, :limit, :scale]

  def init() do
    :ets.new(@ets_table, [:named_table, :ordered_set, :public])
    :ok
  end

  def new(scale, limit) do
    %RateLimiter{scale: scale, limit: limit, ref: atomics()}
  end

  def new(id, scale, limit) do
    case get(id) do
      rate_limiter = %RateLimiter{scale: ^scale, limit: ^limit} ->
        reset(rate_limiter)

      rate_limiter = %RateLimiter{} ->
        rate_limiter
        |> update(scale, limit)
        |> reset()

      nil ->
        rate_limiter = %RateLimiter{id: id, scale: scale, limit: limit, ref: atomics()}
        :ets.insert(@ets_table, {id, rate_limiter})
        rate_limiter
    end
  end

  def update(rate_limiter = %RateLimiter{id: nil}, scale, limit) do
    %{rate_limiter | scale: scale, limit: limit}
  end

  def update(rate_limiter = %RateLimiter{id: id}, scale, limit) do
    rate_limiter = %{rate_limiter | scale: scale, limit: limit}
    :ets.insert(@ets_table, {id, rate_limiter})
    rate_limiter
  end

  def update(id, scale, limit) do
    get!(id) |> update(scale, limit)
  end

  def delete(%RateLimiter{id: id}) do
    delete(id)
  end

  def delete(id) do
    :ets.delete(@ets_table, id)
  end

  def get(id) do
    case :ets.lookup(@ets_table, id) do
      [{_, rate_limiter}] -> rate_limiter
      [] -> nil
    end
  end

  def get!(id) do
    get(id) || raise "Rate limiter #{inspect(id)} not found"
  end

  def hit(rate_limiter, hits \\ 1)

  def hit(rate_limiter = %RateLimiter{ref: ref, scale: scale, limit: limit}, hits) do
    if :atomics.add_get(ref, 2, hits) > limit do
      now = :erlang.monotonic_time(:millisecond)
      last_reset = :atomics.get(ref, 1)

      if last_reset + scale < now do
        if :ok == :atomics.compare_exchange(ref, 1, last_reset, now) do
          :atomics.put(ref, 2, 0)
        end

        hit(rate_limiter, hits)
      else
        {:error, last_reset + scale - now}
      end
    else
      :ok
    end
  end

  def hit(id, hits) do
    get!(id) |> hit(hits)
  end

  def hit(id, scale, limit, hits \\ 1) do
    case get(id) do
      rate_limiter = %RateLimiter{} -> rate_limiter
      nil -> new(id, scale, limit)
    end
    |> hit(hits)
  end

  def wait(rate_limiter, hits \\ 1) do
    case hit(rate_limiter, hits) do
      :ok ->
        :ok

      {:error, eta} ->
        Process.sleep(eta)
        wait(rate_limiter, hits)
    end
  end

  def wait(id, scale, limit, hits \\ 1) do
    case hit(id, scale, limit, hits) do
      :ok ->
        :ok

      {:error, eta} ->
        Process.sleep(eta)
        wait(id, hits)
    end
  end

  def inspect_bucket(%RateLimiter{ref: ref}) do
    %{
      hits: :atomics.get(ref, 2),
      created_at: :atomics.get(ref, 1)
    }
  end

  def inspect_bucket(id) do
    get!(id) |> inspect_bucket()
  end

  def reset(rate_limiter = %RateLimiter{ref: ref}) do
    :atomics.put(ref, 1, :erlang.monotonic_time(:millisecond))
    :atomics.put(ref, 2, 0)
    rate_limiter
  end

  defp atomics do
    ref = :atomics.new(2, signed: true)
    :atomics.put(ref, 1, :erlang.monotonic_time(:millisecond))
    ref
  end
end
