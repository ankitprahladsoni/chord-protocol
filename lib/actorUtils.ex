defmodule ActorUtils do
  def via_tuple(node_id), do: {:via, Registry, {:registry, node_id}}

  def getPid(node_id) do
    case Registry.lookup(:registry, node_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def getSuccessorFromState(state) do
    s = Enum.at(state.finger_table, 0)
    if alive?(s), do: s, else: state.id
  end

  def alive?(id) do
    getPid(id) != nil
  end

  def notAlive?(id) do
    if(getPid(id) == nil) do
      # IO.puts("checking not alive for #{id}")
    end

    getPid(id) == nil
  end

  def getPredecessor(id) do
    case :ets.lookup(:tbl, id) do
      [{_, p}] -> p
      [] -> nil
    end
  end

  def randomNode(node_id, []), do: node_id

  def randomNode(_node_id, existingNodes), do: Enum.random(existingNodes)

  def default(key, defaultValue) do
    if(key == nil) do
      defaultValue
    else
      if(alive?(key)) do
        key
      else
        defaultValue
      end
    end
  end

  # def default(nil, defaultValue), do: defaultValue

  # def default(key, _defaultValue), do: key
end
