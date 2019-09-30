defmodule RateLimiterTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  property "create new rate limiter" do
    check all scale <- positive_integer(),
              limit <- positive_integer() do
      assert %RateLimiter{id: nil, scale: ^scale, limit: ^limit} = RateLimiter.new(scale, limit)
    end
  end

  property "create new rate limiter with id" do
    check all scale <- integer(100..1000),
              limit <- positive_integer() do
      id = :crypto.strong_rand_bytes(10)
      rate_limiter = RateLimiter.new(id, scale, limit)
      assert %RateLimiter{id: ^id, scale: ^scale, limit: ^limit} = rate_limiter
      assert rate_limiter == RateLimiter.new(id, scale, limit)

      rate_limiter = RateLimiter.new(id, scale + 1, limit + 1)
      assert rate_limiter.scale == scale + 1
      assert rate_limiter.limit == limit + 1
    end
  end

  property "returns :ok when limit not reached" do
    check all scale <- integer(1000..10000),
              limit <- positive_integer() do
      rate_limiter = RateLimiter.new(scale, limit)

      for _ <- 1..limit do
        assert :ok = RateLimiter.hit(rate_limiter)
      end

      assert {:error, eta} = RateLimiter.hit(rate_limiter)
      assert eta <= scale
    end
  end

  property "returns {:error, _} when limit exceeded" do
    check all scale <- integer(1000..10000),
              limit <- positive_integer() do
      rate_limiter = RateLimiter.new(scale, limit)
      assert :ok = RateLimiter.hit(rate_limiter, limit)
      assert {:error, eta} = RateLimiter.hit(rate_limiter)
      assert eta <= scale
    end
  end

  property "returns :ok once rate limiter is unblocked" do
    check all scale <- integer(1..10),
              limit <- positive_integer() do
      rate_limiter = RateLimiter.new(scale, limit)
      assert {:error, _} = RateLimiter.hit(rate_limiter, limit + 1)
      Process.sleep(scale)
      assert :ok = RateLimiter.hit(rate_limiter)
    end
  end

  property "rate limiter implicitly created at first hit" do
    check all scale <- integer(100..1000),
              limit <- positive_integer() do
      id = :crypto.strong_rand_bytes(10)
      assert nil == RateLimiter.get(id)
      assert :ok = RateLimiter.hit(id, scale, limit, limit)
      assert RateLimiter.get(id)
      assert {:error, _} = RateLimiter.hit(id, scale, limit)
      assert {:error, _} = RateLimiter.hit(id)
    end
  end

  property "wait for rate limiter to be unblocked" do
    check all scale <- integer(1..10),
              limit <- positive_integer() do
      rate_limiter = RateLimiter.new(scale, limit)
      start = System.monotonic_time(:millisecond)
      assert :ok = RateLimiter.wait(rate_limiter, limit)
      assert System.monotonic_time(:millisecond) - start <= 1
      assert :ok = RateLimiter.wait(rate_limiter)
      assert System.monotonic_time(:millisecond) - start > scale

      id = :crypto.strong_rand_bytes(10)
      assert :ok = RateLimiter.wait(id, scale, limit, limit)
      assert RateLimiter.get(id)
      assert :ok = RateLimiter.wait(id, scale, limit)
    end
  end

  property "update rate limiter" do
    check all scale <- integer(100..1000),
              limit <- positive_integer() do
      rate_limiter = RateLimiter.new(scale, limit)
      rate_limiter = RateLimiter.update(rate_limiter, scale + 1, limit + 1)
      assert rate_limiter.scale == scale + 1
      assert rate_limiter.limit == limit + 1

      id = :crypto.strong_rand_bytes(10)
      rate_limiter = RateLimiter.new(id, scale, limit)
      assert {:error, _} = RateLimiter.hit(rate_limiter, limit + 1)
      rate_limiter = RateLimiter.update(rate_limiter, scale, limit + 10)
      assert :ok = RateLimiter.hit(rate_limiter)

      RateLimiter.update(id, scale + 1, limit)
      assert scale + 1 == RateLimiter.get!(id).scale
    end
  end

  property "reset rate limiter" do
    check all scale <- integer(100..1000),
              limit <- positive_integer() do
      rate_limiter = RateLimiter.new(scale, limit)
      assert {:error, _} = RateLimiter.hit(rate_limiter, limit + 1)
      RateLimiter.reset(rate_limiter)
      assert :ok = RateLimiter.hit(rate_limiter)
    end
  end

  property "delete rate limiter" do
    check all scale <- integer(100..1000),
              limit <- positive_integer() do
      id = :crypto.strong_rand_bytes(10)
      rate_limiter = RateLimiter.new(id, scale, limit)
      RateLimiter.delete(rate_limiter)
      assert nil == RateLimiter.get(id)

      rate_limiter = RateLimiter.new(id, scale, limit)
      RateLimiter.delete(id)
      assert nil == RateLimiter.get(id)
    end
  end

  property "inspect bucket" do
    check all scale <- integer(100..1000),
              limit <- positive_integer(),
              hits <- integer(1..limit) do
      id = :crypto.strong_rand_bytes(10)
      rate_limiter = RateLimiter.new(id, scale, limit)
      assert :ok = RateLimiter.hit(rate_limiter, hits)
      bucket = RateLimiter.inspect_bucket(id)
      assert bucket == RateLimiter.inspect_bucket(rate_limiter)
      assert bucket.hits == hits
      assert bucket.created_at <= System.monotonic_time(:millisecond)
    end
  end

  test "hiting non-existing rate limiter raises error" do
    assert_raise RuntimeError, ~s'Rate limiter "non-existing" not found', fn ->
      RateLimiter.hit("non-existing")
    end
  end
end
