defmodule Mongoex do
  def start do
    :ok = :application.start(:mongoex)
  end
end
