# RateLimiter

`RateLimiter` is a high performance rate limiter implemented on top of erlang `:atomics`
which uses only atomic hardware instructions without any software level locking.
As a result RateLimiter is ~20x faster than `ExRated` and ~80x faster than `Hammer`.

## Installation

The package can be installed by adding `rate_limiter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rate_limiter, "~> 0.3.1"}
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
    
  {:error, eta}
    # limit exceeded, you need to wait `eta` milliseconds until its unblocked again
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

You can also use RateLimiter in a blocking way using `RateLimiter.wait` with the same API as `hit`,
expect that when the limit is reached, the process will be blocked until ratelimiter is free for
the next hit, and it always returns `:ok`:

```elixir
rate_limiter = RateLimiter.new(1000, 5)
RateLimiter.wait(rate_limiter)

# or
RateLimiter.new("my_rate_limiter", 1000, 5)
RateLimiter.wait("my_rate_limiter")

# or
RateLimiter.wait("my_rate_limiter", 1000, 5)
```

`RateLimiter.wait` is suitable for use cases where there is a lot of processes racing for a single ratelimited resource.

## License

RateLimiter is released under MIT license.