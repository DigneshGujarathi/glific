defmodule Glific.Taggers.TaggerHelper do
  @moduledoc """
  Helper functions for tagging incoming messages
  """

  alias Glific.{
    Messages.Message,
    Repo,
    Tags,
    Tags.Tag
  }

  @doc """
  Helper function to update tags of inbound message
  """
  @spec tag_inbound_message({:ok, Message.t()}) :: {:ok, Message.t()}
  def tag_inbound_message({:ok, message}) do
    message
    |> add_unread_tag()
    |> add_not_replied_tag()
    |> remove_not_responded_tag()

    {:ok, message}
  end

  @doc """
  Helper function to update tags of outbound message
  """
  @spec tag_outbound_message(map()) :: {:ok, Message.t()}
  def tag_outbound_message(message) do
    message = Glific.Messages.get_message!(message["id"])

    message
    |> add_not_responded_tag()

    {:ok, message}
  end

  @spec add_tag(Message.t(), String.t()) :: Message.t()
  defp add_tag(message, tag_label) do
    {:ok, tag} = Repo.fetch_by(Tag, %{label: tag_label})

    {:ok, _} =
      Tags.create_message_tag(%{
        message_id: message.id,
        tag_id: tag.id
      })

    message
  end

  @spec add_unread_tag(Message.t()) :: Message.t()
  defp add_unread_tag(message) do
    add_tag(message, "Unread")
  end

  @spec add_not_replied_tag(Message.t()) :: Message.t()
  defp add_not_replied_tag(message) do
    Tags.remove_tag_from_all_message(message.contact_id, "Not replied")
    add_tag(message, "Not replied")
  end

  @spec remove_not_responded_tag(Message.t()) :: Message.t()
  defp remove_not_responded_tag(message) do
    Tags.remove_tag_from_all_message(message.contact_id, "Not Responded")
    message
  end

  @spec add_not_responded_tag(Message.t()) :: Message.t()
  defp add_not_responded_tag(message) do
    Tags.remove_tag_from_all_message(message.contact_id, "Not Responded")
    add_tag(message, "Not Responded")
  end
end
