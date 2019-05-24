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
    end
  end

  property "returns :ok when limit not reached" do
    check all scale <- integer(1000..10000),
              limit <- positive_integer() do
      rate_limiter = RateLimiter.new(scale, limit)

      for _ <- 1..limit do
        assert :ok = RateLimiter.hit(rate_limiter)
      end

      assert {:error, ms_to_reset} = RateLimiter.hit(rate_limiter)
      assert ms_to_reset <= scale
    end
  end

  property "returns {:error, _} when limit exceeded" do
    check all scale <- integer(1000..10000),
              limit <- positive_integer() do
      rate_limiter = RateLimiter.new(scale, limit)
      assert :ok = RateLimiter.hit(rate_limiter, limit)
      assert {:error, ms_to_reset} = RateLimiter.hit(rate_limiter)
      assert ms_to_reset <= scale
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

  property "reset rate limiter" do
    check all scale <- integer(100..1000),
              limit <- positive_integer() do
      rate_limiter = RateLimiter.new(scale, limit)
      assert {:error, _} = RateLimiter.hit(rate_limiter, limit + 1)
      RateLimiter.reset(rate_limiter)
      assert :ok = RateLimiter.hit(rate_limiter)
    end
  end
end
