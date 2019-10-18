defmodule KV.Registry do
  use GenServer

  @doc """
  Starts the registry
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  def start_link!(opts) do
    case start_link(opts) do
      {:ok, pid} -> pid
      {:error, e} -> raise "Encountered error starting process #{__MODULE__}: #{inspect e}"
    end
  end
  
  @doc """
  Looks up the bucket pid `name` stored in `server`.

  Returns `{:ok, pid}` if bucket exists, otherwise `:error`
  """
  def lookup(server, name) do
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  @doc """
  Ensures there is a bucket associated with a given `name` in the `server`.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  ## Defining server callbacks

  def init(table) do
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs = %{}
    {:ok, {names, refs}}
  end

  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, pid} ->
        {:reply, pid, {names, refs}}
      :error ->
        {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        {:reply, pid, {names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
