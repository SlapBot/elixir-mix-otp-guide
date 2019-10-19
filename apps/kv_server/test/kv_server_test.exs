defmodule KVServerTest do
  use ExUnit.Case
  doctest KVServer

  test "greets the world" do
    assert KVServer.hello() == :world
  end
end
