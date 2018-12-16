defmodule NodeActor do
  import ActorUtils
  import MathUtils

  def start_link(node_id, m, existingNodes) do
    GenServer.start_link(__MODULE__, [node_id, m, existingNodes], name: via_tuple(node_id))
  end

  def init([node_id, m, existingNodes]) do
    fingerTable = randomNode(node_id, existingNodes) |> List.duplicate(m)

    state = %{
      id: node_id,
      predecessor: nil,
      finger_table: fingerTable,
      next: 0,
      m: m
    }

    IO.puts("after init: #{inspect(state)}")
    {:ok, state}
  end

  def handle_call(request, _from, state) do
    case request do
      :state ->
        {:reply, state, state}

      {:findSuccessor, origin, node_id, hopsCount} ->
        {:reply, findSuccessor(origin, node_id, hopsCount, state), state}
    end
  end

  def handle_cast(request, state) do
    state =
      case request do
        {:notify, node_id} -> notify(node_id, state)
        {:lookup, origin, key, hopsCount} -> lookup(origin, key, hopsCount, state)
        :stabilize -> Stabilizer.start(state)
      end

    {:noreply, state}
  end

  def predecessorFailed(state), do: state.predecessor != nil && notAlive?(state.predecessor)

  def findSuccessor(origin, node_id, hopsCount, state) do
    successor = getSuccessorFromState(state)

    if isInRange(state.id, node_id, successor + 1, state.m),
      do: [successor, hopsCount],
      else:
        closestTo(node_id, state)
        |> getSuccessorOfClosest(state.id, node_id, hopsCount + 1, origin)
  end

  defp lookupSuccessor(origin, node_id, hopsCount, state) do
    successor = getSuccessorFromState(state)

    if isInRange(state.id, node_id, successor + 1, state.m),
      do: sendCompletion(origin, hopsCount, node_id, successor),
      else:
        closestTo(node_id, state)
        |> lookupOfClosest(state.id, node_id, hopsCount + 1, origin)
  end

  defp lookupOfClosest(closest, id, node_id, hopsCount, origin) do
    if closest == id || notAlive?(closest) || origin == closest,
      do: sendCompletion(origin, hopsCount, node_id, closest),
      else: closest |> getPid() |> GenServer.cast({:lookup, origin, node_id, hopsCount})
  end

  defp getSuccessorOfClosest(closest, id, node_id, hopsCount, origin) do
    if closest == id || notAlive?(closest) || origin == closest,
      do: [id, hopsCount],
      else: closest |> getPid() |> GenServer.call({:findSuccessor, origin, node_id, hopsCount})
  end

  defp notify(node_id, state) do
    if state.predecessor == nil || isInRange(state.predecessor, node_id, state.id, state.m) do
      :ets.insert(:tbl, {state.id, node_id})
      %{state | predecessor: node_id}
    else
      state
    end
  end

  defp lookup(origin, key, hopsCount, state) do
    if key == state.id,
      do: sendCompletion(origin, hopsCount, key, key),
      else: lookupSuccessor(origin, key, hopsCount, state)

    # sendCompletion(state.id, hopsCount, key, succ)

    state
  end

  defp sendCompletion(id, hopsCount, key, succ) do
    :global.whereis_name(:requestCompletedTask)
    |> send({:completed, id, hopsCount, key, succ})
  end

  defp closestTo(node_id, state) do
    range = (state.m - 1)..0

    Enum.map(range, fn i -> Enum.at(state.finger_table, i) end)
    |> Enum.find(fn ft_entry -> isInRange(state.id, ft_entry, node_id, state.m) end)
    |> default(state.id)
  end
end
