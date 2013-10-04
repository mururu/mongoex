defmodule Mongoex.Base do
  defmacro __using__(_) do
    quote do
      import Mongoex.Base.Fields

      def new_record?(record) do
        !record._id
      end

      def persisted?(record) do
        !new_record?(record)
      end

      def save(record) do
        if record.persisted? do
          replace(record)
        else
          insert(record)
        end
      end

      def insert(record) do
        {:ok, _id} = Mongoex.Server.insert(table_name,record_to_tuple(record))
        record._id(_id)
      end

      def replace(record) do
        selector = {:_id, record._id}
        Mongoex.Server.replace(table_name, selector, record_to_tuple(record))
        record
      end

      def delete(record) do
        selector = {:_id, record._id}
        Mongoex.Server.delete_all(table_name, selector)
      end

      def delete_all(selector // []) do
        Mongoex.Server.delete_all(table_name, selector)
      end

      def destroy(record) do
        delete(record)
      end

      def destroy_all(selector // []) do
        delete_all(selector)
      end

      def find(selector) do
        {:ok, res} = Mongoex.Server.find(table_name, selector)
        case res do
          {}       -> nil
          {result} -> result_to_record(result)
        end
      end

      def find_all(selector, options // []) do
        {:ok, res} = Mongoex.Server.find_all(table_name, selector, options)
        case :mongo_cursor.rest(res) do
          [] ->
            []
          list when is_list(list) ->
            Enum.map list, fn(x) -> result_to_record(x) end
        end
      end

      def count(selector // []) do
        {:ok, res} = Mongoex.Server.count(table_name, selector)
        res
      end

      defp table_name do
        binary_to_atom(String.downcase(List.last(String.split inspect(__MODULE__), ".", global: true)))
      end

      defp record_to_tuple(record) do
        keywords = record.to_keywords
        if record.new_record? do
          keywords = Keyword.delete keywords, :_id
        end
        list_to_tuple List.flatten Enum.map keywords, fn(x) -> tuple_to_list(x) end
      end

      defp result_to_record(result) do
        if size_is_even?(result) do
          list = tuple_to_keyvalue(result)
          new(list)
        end
      end

      defp size_is_even?(tuple) do
        rem(tuple_size(tuple), 2) == 0
      end

      defp tuple_to_keyvalue(tuple) do
        list = tuple_to_list(tuple)
        even_odd = Enum.map :lists.seq(0, length(list)-1), fn(x) -> rem(x,2) end
        list_zipped_even_odd = Enum.zip list, even_odd
        {even,odds} = List.foldl list_zipped_even_odd, {[],[]}, fn({v,i}, {even,odds}) -> if i==0, do: {Enum.concat(even,[v]),odds}, else: {even,Enum.concat(odds,[v])} end
        Enum.zip even, odds
      end
    end
  end
end
