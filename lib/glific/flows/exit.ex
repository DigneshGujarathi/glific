defmodule Glific.Flows.Exit do
  @moduledoc """
  The Exit object which encapsulates one exit in a given node.
  """
  alias __MODULE__

  use Ecto.Schema

  alias Glific.{
    Flows,
    Flows.FlowContext,
    Flows.Node
  }

  @required_fields [:uuid, :destination_uuid]

  @type t() :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          node_uuid: Ecto.UUID.t() | nil,
          node: Node.t() | nil,
          destination_node_uuid: Ecto.UUID.t() | nil,
          destination_node: Node.t() | nil
        }

  embedded_schema do
    field :uuid, Ecto.UUID

    field :node_uuid, Ecto.UUID
    embeds_one :node, Node

    field :destination_node_uuid, Ecto.UUID
    embeds_one :destination_node, Node
  end

  @doc """
  Process a json structure from floweditor to the Glific data types
  """
  @spec process(map(), map(), Node.t()) :: {Exit.t(), map()}
  def process(json, uuid_map, node) do
    Flows.check_required_fields(json, @required_fields)

    exit = %Exit{
      uuid: json["uuid"],
      node_uuid: node.uuid,
      destination_node_uuid: json["destination_uuid"]
    }

    {exit, Map.put(uuid_map, exit.uuid, {:exit, exit})}
  end

  @doc """
  Execute a exit, given a message stream.
  """
  @spec execute(Exit.t(), FlowContext.t(), [String.t()]) ::
          {:ok, FlowContext.t() | nil, [String.t()]} | {:error, String.t()}
  def execute(exit, context, message_stream) do
    if is_nil(exit.destination_node_uuid) do
      FlowContext.reset_context(context)
      {:ok, nil, []}
    else
      {:ok, {:node, node}} = Map.fetch(context.uuid_map, exit.destination_node_uuid)

      Node.execute(
        node,
        FlowContext.set_node(context, node),
        message_stream
      )
    end
  end
end
