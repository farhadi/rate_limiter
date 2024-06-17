defmodule RateLimiter.MixProject do
  use Mix.Project

  def project do
    [
      app: :rate_limiter,
      version: "0.4.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {RateLimiter.Application, []}
    ]
  end

  defp deps do
    [
      {:stream_data, "~> 1.1", only: [:dev, :test]},
      {:benchee, "~> 1.3", only: :dev},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "A high performance rate limiter on top of erlang atomics for Elixir"
  end

  defp package() do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE", ".formatter.exs"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/farhadi/rate_limiter"}
    ]
  end
end
