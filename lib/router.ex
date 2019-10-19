defmodule KV.Router do
    @doc """
    Dispatch the given `mod`, `fun`, `args` request to the appropriate node based on the bucket.
    """
    def route(bucket, mod, fun, args) do
        # Get the first byte of the binary
        first = :binary.first(bucket)

        # Try to find the entry in the table
        entry = Enum.find(table(), fn {enum, _node} -> first in enum end) || no_entry_error(bucket)

        # if the entry node is the current node
        if elem(entry, 1) == node() do
            apply(mod, fun, args)
        else
            {KV.RouterTasks, elem(entry, 1)}
            |> Task.Supervisor.async(KV.Router, :route, [bucket, mod, fun, args])
            |> Task.await()
        end
    end

    defp no_entry_error(bucket) do
        raise "could not find entry for #{inspect bucket} in table #{inspect table()}"
    end

    @doc """
    The routing table
    """
    def table do
        [
            {?a..?m, :"foo@DESKTOP-RAKOE0T"},
            {?n..?z, :"bar@DESKTOP-RAKOE0T"}
        ]
    end
end