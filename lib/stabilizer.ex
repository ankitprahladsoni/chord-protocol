defmodule Stabilizer do
  import ActorUtils
  import MathUtils
  import NodeActor

  def start(state) do
    state =
      stabilize(state)
      |> fixFingers(state.id)
      |> checkPredecessor()

    startOnOtherNodes(state.id + 1, state.m)
    state
  end

  defp stabilize(state) do
    successor = getSuccessorFromState(state)

    predecessor = if state.id == successor, do: state.predecessor, else: getPredecessor(successor)

    successor =
      if predecessor != nil && isInRange(state.id, predecessor, successor, state.m),
        do: predecessor,
        else: successor

    notifySuccessorToUpdatePredecessor(successor, state.id)

    updateSuccessor(successor, state)
  end

  defp notifySuccessorToUpdatePredecessor(successor, newPredecessor) do
    successor |> getPid() |> GenServer.cast({:notify, newPredecessor})
  end

  defp fixFingers(state, origin) do
    nextId = getValidNextId(state.next, state)

    [successor, _hopsCount] = findSuccessor(origin, nextId, 0, state)

    state = updateSuccessor(successor, state, state.next)
    %{state | next: rem(state.next + 1, state.m)}
  end

  defp checkPredecessor(state) do
    if predecessorFailed(state), do: %{state | predecessor: nil}, else: state
  end

  defp startOnOtherNodes(id, m) do
    pid = nextPid(id, m)

    if pid == nil,
      do: startOnOtherNodes(id + 1, m),
      else: GenServer.cast(pid, :stabilize)
  end

  defp nextPid(id, m) do
    if id > powInt(2, m), do: getPid(1), else: getPid(id)
  end

  defp updateSuccessor(successor, state, index \\ 0) do
    ft = List.replace_at(state.finger_table, index, successor)
    %{state | finger_table: ft}
  end
end
