defmodule Mongoex.Server do
  def start do
    :ok = :application.start(:mongodb)
    setup_pool
  end

  def setup(options // []) do
    :ets.new(:mongoex_server, [:set, :protected, :named_table])
    :ets.insert(:mongoex_server, {:mongoex_server, Keyword.merge(default_options, options)})
  end

  def authenticate do
    execute(fn() -> :mongo.auth(config[:username], config[:password]) end)
  end

  def config do
    :ets.lookup(:mongoex_server, :mongoex_server)[:mongoex_server]
  end

  def insert(table, tuple) do
    execute(fn() -> :mongo.insert(table, tuple) end)
  end

  def replace(table, selector, tuple) do
     execute(fn() -> :mongo.replace(table, selector, tuple) end)
  end

  def delete_all(table, tuple) do
    execute(fn() -> :mongo.delete(table, tuple) end)
  end

  def find(table, selector) do
    execute(fn() -> :mongo.find_one(table, selector) end)
  end

  def find_all(table, selector) do
    execute(fn() -> :mongo.find(table,selector) end)
  end

  def count(table, selector) do
    execute(fn() -> :mongo.count(table,selector) end)
  end

  def execute(fun) do
    #{:ok, conn} = connect

    #if not nil?(config[:username]) and not nil?(config[:password]) do
    #  auth = fn() -> :mongo.auth(config[:username], config[:password]) end
    #  mongo_do = function(:mongo, :do, 5)
    #  mongo_do.(:safe, :master, conn, config[:database], auth)
    #end
    conn = get_connection

    mongo_do = function(:mongo, :do, 5)
    mongo_do.(:safe, :master, conn, config[:database], fun)
  end

  defp connect do
    :mongo.connect({config[:address], config[:port]})
  end

  defp setup_pool do
    sequence = :lists.seq(1,10)
    {_seqs, pool} = Enum.map_reduce sequence, [], fn(seq, acc) ->
      {:ok, conn} = connect
      auth = fn() ->
        :mongo.auth(config[:username], config[:password])
      end
      mongo_do = function(:mongo, :do, 5)
      mongo_do.(:safe, :master, conn, config[:database], auth)
      {seq, [conn|acc]}
    end

    :ets.new(:mongoex_pool, [:set, :protected, :named_table])
    :ets.insert(:mongoex_pool, {:mongoex_pool, pool})
  end

  defp get_connection do
    pool = :ets.lookup(:mongoex_pool, :mongoex_pool)[:mongoex_pool]
    List.last pool
  end

  defp default_options do
    [ address: 'localhost',
      port: 27017,
      database: :mongoex_test,
      username: nil,
      password: nil
    ]
  end
end
