defmodule Mongoex.Server do
  def start do
    :ok = :application.start(:mongodb)
    setup_pool
  end

  def setup(options // []) do
    :ets.new(:mongoex_server, [:set, :protected, :named_table])
    :ets.insert(:mongoex_server, {:mongoex_server, Keyword.merge(default_options, options)})
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

  def find_all(table, selector, options // []) do
    skip = options[:skip]
    if skip == nil do
      skip = 0
    end

    batch_size = options[:batch_size]
    if batch_size == nil do
      batch_size = 0
    end

    execute(fn() -> :mongo.find(table, selector, {}, skip, batch_size) end)
  end

  def count(table, selector) do
    execute(fn() -> :mongo.count(table,selector) end)
  end

  def execute(fun) do
    conn = get_connection_from_pool

    mongo_do = Module.function(:mongo, :do, 5)
    result = mongo_do.(:safe, :master, conn, config[:database], fun)

    return_connection_to_pool conn

    result
  end

  defp connect do
    :mongo.connect({config[:address], config[:port]})
  end

  defp setup_pool do
    sequence = :lists.seq(1, config[:pool])
    {_seqs, pool} = Enum.map_reduce sequence, [], fn(seq, acc) ->

      {:ok, conn} = connect

      if config[:username] !== nil and config[:password] !== nil do
        auth = fn() ->
          :mongo.auth(config[:username], config[:password])
        end
        mongo_do = Module.function(:mongo, :do, 5)
        mongo_do.(:safe, :master, conn, config[:database], auth)
      end
      
      {seq, [conn|acc]}
    end

    :ets.new(:mongoex_pool, [:set, :public, :named_table])
    :ets.insert(:mongoex_pool, {:mongoex_pool, pool})
  end

  defp get_connection_from_pool do
    pool = :ets.lookup(:mongoex_pool, :mongoex_pool)[:mongoex_pool]
 
    case Enum.count(pool) do
      0 ->
        {:error, :no_available_connections}
      _ ->
        conn = :erlang.hd(pool)
        new_pool = :erlang.tl(pool)
        :ets.insert(:mongoex_pool, {:mongoex_pool, new_pool})
        conn
    end
  end

  defp return_connection_to_pool(conn) do
    pool = :ets.lookup(:mongoex_pool, :mongoex_pool)[:mongoex_pool]
    new_pool = [conn|pool]
    :ets.insert(:mongoex_pool, {:mongoex_pool, new_pool})
  end

  defp default_options do
    [ address: 'localhost',
      port: 27017,
      database: :mongoex_test,
      username: nil,
      password: nil,
      pool: 1
    ]
  end
end
