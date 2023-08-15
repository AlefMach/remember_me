defmodule RememberMe.MixProject do
  use Mix.Project

  def project do
    [
      app: :remember_me,
      version: "0.0.1",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  defp description do
    """
    RememberMe is a robust but simple state memory machine organizer. you can assimilate it like a Redis, but the difference is that you can schedule and define the number of times a function will be executed and of course save any values ​from an assimilated key.
    """
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {RememberMe.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    []
  end

  defp package do
    [
     files: ["lib", "mix.exs", "README.md"],
     maintainers: ["Alef Machado"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/AlefMach/remember_me",
              "Docs" => "https://hexdocs.pm/remember_me/"}
     ]
  end
end
