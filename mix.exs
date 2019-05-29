defmodule RateLimiter.MixProject do
  use Mix.Project

  def project do
    [
      app: :rate_limiter,
      version: "0.2.2",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {RateLimiter.Application, []}
    ]
  end

  defp deps do
    [
      {:stream_data, "~> 0.4.3", only: :test},
      {:benchee, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
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
