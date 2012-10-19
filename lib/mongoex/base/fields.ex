defmodule Mongoex.Base.Fields do
  defmacro fields(values // []) do
    Record.deffunctions(Keyword.merge(values, [_id: nil]), __CALLER__)
  end
end
