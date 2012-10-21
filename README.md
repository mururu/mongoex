# Mongoex

Mongoex is an ODM-like module for MongoDb in Elixir.

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
