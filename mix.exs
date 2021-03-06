defmodule TweetQuest.MixProject do
  use Mix.Project

  def project do
    [
      app: :tweet_quest,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bypass, "~> 2.1", only: :test},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:httpoison, "~> 1.7"},
      {:jason, "~> 1.0"},
      {:oauther, "~> 1.1"}
    ]
  end
end
