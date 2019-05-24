Benchee.run(%{
  "RateLimiter" => fn rate_limiter -> RateLimiter.hit(rate_limiter) end
}, inputs: %{
  "scale: 1000, limit: 10" => RateLimiter.new(1000, 10),
  "scale: 60,000, limit: 10,000" => RateLimiter.new(60_000, 10_000),
  "scale: 1000, limit: 1,000,000" => RateLimiter.new(1000, 1_000_000)
})
