# RateLimiter

`RateLimiter` is a high performance rate limiter implemented on top of erlang `:atomics`
which uses only atomic hardware instructions without any software level locking.
As a result RateLimiter is ~20x faster than `ExRated` and ~80x faster than `Hammer`.

## Installation

The package can be installed by adding `rate_limiter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rate_limiter, "~> 0.1.0"}
  ]
end
```

## Usage 

First you need to create a new RateLimiter by calling `RateLimiter.new/2`
For example to create a rate limiter with a limitaion of 5 hits per second:

```elixir
rate_limiter = RateLimiter.new(1000, 5)
```

You can also give your rate limiter an id using `RateLimiter.new/3`

```elixir
rate_limiter = RateLimiter.new("my_rate_limiter", 1000, 5)
```

Subsequent calls to `RateLimiter.new/3` with the same id will return the already created
rate limiter instead of creating a new one, so that you can easily use a single ratelimiter
across different processes in your application.

By calling `RateLimiter.hit/2` you can check whether you reached the limit or not.
The second parameter is optional number of hits with a default value of 1:

```elixir
case RateLimiter.hit(rate_limiter, 2) do
  :ok ->
    # limit not reached yet
    
  {:error, milliseconds_remaining}
    # limit exceeded, you need to wait `milliseconds_remaining` until its free again
end
```

In use cases where you don't have a state to store your RateLimiter struct you can pass
an id instead, but keep in mind using id makes it around 50% slower because it does an
ets lookup to get to the rate limiter:

```elixir
RateLimiter.hit("my_rate_limiter")
```

You can also create and check the rate limiter in one go if it's not already created:

```elixir
RateLimiter.hit("my_rate_limiter", 1000, 5)
```
