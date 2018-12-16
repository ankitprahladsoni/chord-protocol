defmodule Project3 do
  # [numNodes, numRequest, nodesToKill] = System.argv()
  # {numNodes, _} = numNodes |> :string.to_integer()
  # {numRequest, _} = numRequest |> :string.to_integer()
  # {nodesToKill, _} = nodesToKill |> :string.to_integer()
  # Proj3.main(numNodes, numRequest, nodesToKill)

  case System.argv() do
    [numNodes, numRequest, nodesToKill] ->

      Proj3.main(
        String.to_integer(numNodes),
        String.to_integer(numRequest),
        String.to_integer(nodesToKill)
      )

    [numNodes, numRequest] ->
      Proj3.main(String.to_integer(numNodes), String.to_integer(numRequest))
  end
end
