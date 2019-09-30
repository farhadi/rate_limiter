Benchee.run(%{
  "RateLimiter.hit" => &RateLimiter.hit/1
}, inputs: %{
  "[scale: 1, limit: 1000]" => RateLimiter.new(1, 1000),
  "[scale: 1000, limit: 10]" => RateLimiter.new(1000, 10),
  "[scale: 60,000, limit: 10,000]" => RateLimiter.new(60_000, 10_000),
  "[scale: 1000, limit: 1,000,000]" => RateLimiter.new(1000, 1_000_000),
  "[scale: 1000, limit: 10,000,000]" => RateLimiter.new(1000, 10_000_000)
})
