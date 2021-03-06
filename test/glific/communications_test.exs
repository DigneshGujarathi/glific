defmodule Glific.CommunicationsTest do
  use Glific.DataCase, async: true
  use Oban.Testing, repo: Glific.Repo

  alias Faker.Phone

  alias Glific.{
    Communications,
    Contacts,
    Fixtures,
    Messages,
    Providers.Gupshup,
    Providers.Gupshup.Worker,
    Repo,
    Seeds.SeedsDev,
    Tags,
    Tags.Tag
  }

  setup do
    default_provider = SeedsDev.seed_providers()
    SeedsDev.seed_organizations(default_provider)
    :ok
  end

  describe "communications" do
    test "fetch provider from config" do
      Application.put_env(:glific, :provider, Gupshup.Message)
      assert Gupshup.Message == Communications.provider()
    end
  end

  describe "gupshup_messages" do
    setup do
      Tesla.Mock.mock(fn
        %{method: :post} ->
          %Tesla.Env{
            status: 200,
            body:
              Jason.encode!(%{
                "status" => "submitted",
                "messageId" => Faker.String.base64(36)
              })
          }
      end)

      :ok
    end

    @sender_attrs %{
      name: "some sender",
      optin_time: ~U[2010-04-17 14:00:00Z],
      phone: "12345671",
      last_message_at: DateTime.utc_now()
    }

    @receiver_attrs %{
      name: "some receiver",
      optin_time: ~U[2010-04-17 14:00:00Z],
      phone: "101013131",
      last_message_at: DateTime.utc_now()
    }

    @valid_attrs %{
      body: "some body",
      flow: :outbound,
      type: :text
    }

    @valid_media_attrs %{
      caption: "some caption",
      source_url: "some source_url",
      thumbnail: "some thumbnail",
      url: "some url",
      provider_media_id: "some provider_media_id"
    }

    defp foreign_key_constraint do
      {:ok, sender} = Contacts.create_contact(@sender_attrs)
      {:ok, receiver} = Contacts.create_contact(@receiver_attrs)
      %{sender_id: sender.id, receiver_id: receiver.id}
    end

    defp message_fixture(attrs \\ %{}) do
      valid_attrs = Map.merge(foreign_key_constraint(), @valid_attrs)

      {:ok, message} =
        valid_attrs
        |> Map.merge(attrs)
        |> Messages.create_message()

      message
      |> Repo.preload([:receiver, :sender, :media])
    end

    defp message_media_fixture(attrs \\ %{}) do
      {:ok, message_media} =
        attrs
        |> Enum.into(@valid_media_attrs)
        |> Messages.create_message_media()

      message_media
    end

    test "send message should update the provider message id" do
      message = message_fixture()
      Communications.Message.send_message(message)
      assert_enqueued(worker: Worker)
      Oban.drain_queue(queue: :gupshup)
      message = Messages.get_message!(message.id)
      assert message.provider_message_id != nil
      assert message.sent_at != nil
      assert message.provider_status == :enqueued
      assert message.flow == :outbound
    end

    test "send message will remove the Not replied tag from messages" do
      message_1 = Fixtures.message_fixture(%{flow: :inbound})

      message_2 =
        Fixtures.message_fixture(%{
          flow: :outbound,
          sender_id: message_1.sender_id,
          receiver_id: message_1.contact_id
        })

      assert message_2.contact_id == message_1.contact_id

      {:ok, tag} = Repo.fetch_by(Tag, %{label: "Not replied"})
      {:ok, unread_tag} = Repo.fetch_by(Tag, %{label: "Unread"})

      message1_tag = Fixtures.message_tag_fixture(%{message_id: message_1.id, tag_id: tag.id})

      message_unread_tag =
        Fixtures.message_tag_fixture(%{message_id: message_1.id, tag_id: unread_tag.id})

      Communications.Message.send_message(message_2)
      assert_enqueued(worker: Worker)
      Oban.drain_queue(queue: :gupshup)

      assert_raise Ecto.NoResultsError, fn -> Tags.get_message_tag!(message1_tag.id) end

      assert_raise Ecto.NoResultsError, fn ->
        Tags.get_message_tag!(message_unread_tag.id)
      end
    end

    test "if response status code is not 200 handle the error response " do
      Tesla.Mock.mock(fn
        %{method: :post} ->
          %Tesla.Env{
            status: 400,
            body: "Error"
          }
      end)

      message = message_fixture()
      Communications.Message.send_message(message)
      assert_enqueued(worker: Worker)
      Oban.drain_queue(queue: :gupshup)
      message = Messages.get_message!(message.id)
      assert message.provider_message_id == nil
      assert message.provider_status == :error
      assert message.flow == :outbound
      assert message.sent_at == nil
    end

    test "send media message should update the provider message id" do
      message_media = message_media_fixture()

      # image message
      message = message_fixture(%{type: :image, media_id: message_media.id})
      Communications.Message.send_message(message)
      assert_enqueued(worker: Worker)
      Oban.drain_queue(queue: :gupshup)
      message = Messages.get_message!(message.id)
      assert message.provider_message_id != nil
      assert message.provider_status == :enqueued
      assert message.flow == :outbound
      assert message.sent_at != nil

      # audio message
      {:ok, message} =
        Messages.update_message(message, %{type: :audio, media_id: message_media.id})

      message = Repo.preload(message, [:receiver, :sender, :media])
      Communications.Message.send_message(message)
      assert_enqueued(worker: Worker)
      Oban.drain_queue(queue: :gupshup)
      message = Messages.get_message!(message.id)
      assert message.provider_message_id != nil
      assert message.provider_status == :enqueued
      assert message.flow == :outbound

      # video message
      {:ok, message} =
        Messages.update_message(message, %{type: :video, media_id: message_media.id})

      message = Repo.preload(message, [:receiver, :sender, :media])
      Communications.Message.send_message(message)
      assert_enqueued(worker: Worker)
      Oban.drain_queue(queue: :gupshup)
      message = Messages.get_message!(message.id)
      assert message.provider_message_id != nil
      assert message.provider_status == :enqueued
      assert message.flow == :outbound

      # document message
      {:ok, message} =
        Messages.update_message(message, %{type: :document, media_id: message_media.id})

      message = Repo.preload(message, [:receiver, :sender, :media])
      Communications.Message.send_message(message)
      assert_enqueued(worker: Worker)
      Oban.drain_queue(queue: :gupshup)
      message = Messages.get_message!(message.id)
      assert message.provider_message_id != nil
      assert message.provider_status == :enqueued
      assert message.flow == :outbound
    end

    test "sending message to optout contact will return error" do
      {:ok, receiver} =
        @receiver_attrs
        |> Map.merge(%{status: :invalid, phone: Phone.EnUs.phone()})
        |> Contacts.create_contact()

      message = message_fixture(%{receiver_id: receiver.id})
      assert {:error, _msg} = Communications.Message.send_message(message)

      message = Messages.get_message!(message.id)
      assert message.status == :contact_opt_out
      assert message.provider_status == nil
    end

    test "sending message to contact having invalid provider status will return error" do
      {:ok, receiver} =
        @receiver_attrs
        |> Map.merge(%{provider_status: :invalid, phone: Phone.EnUs.phone()})
        |> Contacts.create_contact()

      message = message_fixture(%{receiver_id: receiver.id})
      assert {:error, _msg} = Communications.Message.send_message(message)
    end

    test "sending message if last received message is more then 24 hours returns error" do
      {:ok, receiver} =
        @receiver_attrs
        |> Map.merge(%{
          phone: Phone.EnUs.phone(),
          last_message_at: Timex.shift(DateTime.utc_now(), days: -2)
        })
        |> Contacts.create_contact()

      message = message_fixture(%{receiver_id: receiver.id})
      assert {:error, _msg} = Communications.Message.send_message(message)
    end

    test "update_provider_status/2 will update the message status based on provider message ID" do
      message =
        message_fixture(%{
          provider_message_id: Faker.String.base64(36),
          provider_status: :enqueued
        })

      Communications.Message.update_provider_status(message.provider_message_id, :read)
      message = Messages.get_message!(message.id)
      assert message.provider_status == :read
    end

    test "send message at a specific time should not send it immediately" do
      scheduled_time = Timex.shift(DateTime.utc_now(), hours: 2)

      message =
        %{send_at: scheduled_time}
        |> message_fixture()

      Communications.Message.send_message(message)

      assert_enqueued(worker: Worker)
      Oban.drain_queue(queue: :gupshup)
      message = Messages.get_message!(message.id)

      assert message.status == :enqueued
      assert message.provider_message_id == nil
      assert message.sent_at == nil
      assert message.provider_status == nil
      assert message.flow == :outbound

      # Verify job scheduled
      assert_enqueued(worker: Worker, scheduled_at: {scheduled_time, delta: 10})
    end
  end
end
