defmodule Proj3 do
  import ActorUtils
  import MathUtils

  def main(numNodes, numRequest, nodesToKill \\ 0) do
    Registry.start_link(keys: :unique, name: :registry)
    :ets.new(:tbl, [:named_table, :public])
    :ets.new(:averageHops, [:named_table, :public])

    m = log2Ceil(numNodes)

    createChord([], Enum.to_list(1..powInt(2, m)), m, numNodes)
    |> listenForCompletion(numNodes, numRequest, m, nodesToKill)
  end

  def createChord(nodesInChord, _, _m, numNodes) when numNodes <= 0 do
    IO.puts("Chord creation complete final #{inspect(nodesInChord)}")
    nodesInChord
  end

  def createChord(nodesInChord, remainingNodes, m, numNodes) when numNodes > 0 do
    addNodeToChord(remainingNodes, nodesInChord, m)
    |> createChord(remainingNodes, m, numNodes - 1)
  end

  def addNodeToChord(remainingNodes, nodesInChord, m) do
    hashVal = (remainingNodes -- nodesInChord) |> Enum.random()

    spawn(fn -> NodeActor.start_link(hashVal, m, nodesInChord) end)
    |> Process.monitor()

    [hashVal | nodesInChord]
  end

  def listenNodeTaskCompletion(numNodes) when numNodes <= 0 do
    IO.puts("All Nodes have finished their task")
  end

  def listenNodeTaskCompletion(numNodes) when numNodes > 0 do
    receive do
      {:completed, pid, hopsCount, key, succ} ->
        storeNumberOfHops(hopsCount)
        IO.puts("#{inspect(pid)} found key #{key} with Node: #{succ} in  hops #{hopsCount}")
        listenNodeTaskCompletion(numNodes - 1)
    after
      15_000 ->
        IO.puts("Deadlock occured, please try again")
        Process.exit(self(), :killed)
    end
  end

  def startMessageOnAllNodes(nodesInChord, numRequest, m) do
    for _ <- 1..numRequest do
      Process.sleep(1000)
      key = getRandomKey(m)
      Enum.each(nodesInChord, fn n -> getPid(n) |> GenServer.cast({:lookup, n, key, 0}) end)
    end
  end

  def listenForCompletion(nodesInChord, numNodes, numRequest, m, nodesToKill) do

    killProcesses(nodesInChord, nodesToKill)
    Process.sleep(2000)

    startStabilize(nodesInChord)

    requestCompleted =
      Task.async(fn -> listenNodeTaskCompletion((numNodes - nodesToKill) * numRequest) end)

    :global.register_name(:requestCompletedTask, requestCompleted.pid)

    Process.sleep(2000)
    startMessageOnAllNodes(nodesInChord, numRequest, m)
    Task.await(requestCompleted, :infinity)

    Enum.filter(nodesInChord, fn x -> alive?(x) end)
    |> Enum.each(fn x -> getPid(x) |> GenServer.call(:state) |> IO.inspect() end)

    printAverageHops((numNodes - nodesToKill) * numRequest)
  end

  defp startStabilize(nodesInChord) do
    pid =
      Enum.random(nodesInChord)
      |> getPid()

    if pid == nil, do: startStabilize(nodesInChord), else: GenServer.cast(pid, :stabilize)
  end

  defp killProcesses(nodesInChord, nodesToKill) do
    if(nodesToKill > 0) do
      killed = Enum.random(nodesInChord)
      killed |> getPid() |> Process.exit(:kill)
      IO.puts("Node: #{killed} has been stopped")
      killProcesses(nodesInChord -- [killed], nodesToKill - 1)
    end
  end

  defp storeNumberOfHops(hopsCount) do
    case :ets.lookup(:averageHops, 1) do
      [{_, hops}] -> :ets.insert(:averageHops, {1, hopsCount + hops})
      [] -> :ets.insert(:averageHops, {1, hopsCount})
    end
  end

  defp printAverageHops(numNodes) do
    case :ets.first(:averageHops) do
      "$end_of_table" ->
        nil

      key ->
        case :ets.lookup(:averageHops, key) do
          [] ->
            nil

          [{_, value}] ->
            IO.puts("Average hops for a message: #{value / numNodes}")
            :ets.delete(:averageHops, key)
            printAverageHops(numNodes)
        end
    end
  end
end
