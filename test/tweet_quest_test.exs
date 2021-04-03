defmodule TweetQuestTest do
  use ExUnit.Case
  doctest TweetQuest

  test "greets the world" do
    assert TweetQuest.hello() == :world
  end
end
