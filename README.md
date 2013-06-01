# Mongoex

Mongoex is an ODM-like module for MongoDb in Elixir.

This is still under development.

## Usage

```elixir
defmodule User do
  use Mongoex.Base
  fields name: nil, sex: nil, age: 20
end

iex> Mongoex.Server.setup(address: 'example.com', port: 27017, database: :your_app)
iex> Mongoex.Server.start

iex> user = User.new(name: "mururu", sex: :male, age: 22)
User[_id: nil, name: "mururu", sex: :male, age: 22]

iex> user.save
:ok

iex> mururu = User.find({:name, "mururu"})
User[_id: {<<80,130,218,110,117,35,125,79,90,0,0,1>>}, name: "mururu", sex: :male, age: 22]

iex> mururu.destroy
:ok
```

## Options

You can authenticate by passing username and password options in the setup.

Mongoex can maintain a pool of connections that are created on server start. By default only one connction is created but you can change this by passing a pool option. If all connections are in use then a DB function will return

```elixir
{:error, :no_available_connections}
```
