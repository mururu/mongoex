defmodule Mongoex do
  defmacro __using__(_) do
    Mongoex.Server.setup
    Mongoex.Server.start
  end
end
