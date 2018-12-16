defmodule MathUtils do
  use Bitwise
  def isInRange(from, key, to, m) do
    to = if to > powInt(2, m) + 1, do: 1, else: to

    cond do
      from < to -> from < key && key < to
      from == to -> key != from
      from > to -> (key > 0 && key < to) || (key > from && key <= powInt(2, m))
    end
  end

  def getValidNextId(next, state) do
    numNodes = powInt(2, state.m)
    nextId = state.id + powInt(2, next)

    if nextId > numNodes, do: nextId - numNodes, else: nextId
  end

  def powInt(n, k) do
    :math.pow(n, k) |> trunc()
  end

  def log2Ceil(numNodes) do
    :math.log2(numNodes) |> :math.ceil() |> trunc()
  end

  def getRandomKey(m) do
    Enum.random(1..powInt(2, m))
  end

  def getHash(n) do
    {hash, _} = :crypto.hash(:sha256, "node"<> to_string(n)) |> Base.encode16 |>Integer.parse(16)
    hash &&& log2Ceil(n)
  end
end
