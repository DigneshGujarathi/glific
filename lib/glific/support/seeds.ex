defmodule Glific.Seeds do
  @moduledoc """
  Script for populating the database. We can call this from tests and/or /priv/repo
  """
  alias Glific.{
    Contacts.Contact,
    Partners.BSP,
    Partners.Organization,
    Repo,
    Settings.Language,
    Tags.Tag
  }

  @doc """
  Smaller functions to seed various tables. This allows the test functions to call specific seeder functions.
  In the next phase we will also add unseeder functions as we learn more of the test capabilities
  """
  @spec seed_language() :: {Language.t(), Language.t()}
  def seed_language do
    en_us =
      Repo.insert!(%Language{
        label: "English (United States)",
        locale: "en_US"
      })

    hi_in =
      Repo.insert!(%Language{
        label: "Hindi (India)",
        locale: "hi_IN"
      })

    {en_us, hi_in}
  end

  @doc """
  Function to populate some basic data that we need for the system to operate. We will
  split this function up into multiple different ones for test, dev and production
  """
  @spec seed :: nil
  def seed do
    {en_us, hi_in} = seed_language()

    message_tags_en = Repo.insert!(%Tag{label: "Messages", language: en_us})
    message_tags_hi = Repo.insert!(%Tag{label: "Messages", language: hi_in})

    Repo.insert!(%Tag{label: "Welcome", language: en_us, parent_id: message_tags_en.id})
    Repo.insert!(%Tag{label: "Greeting", language: en_us, parent_id: message_tags_en.id})
    Repo.insert!(%Tag{label: "Thank You", language: en_us, parent_id: message_tags_en.id})
    Repo.insert!(%Tag{label: "Welcome", language: hi_in, parent_id: message_tags_hi.id})
    Repo.insert!(%Tag{label: "Greeting", language: hi_in, parent_id: message_tags_hi.id})
    Repo.insert!(%Tag{label: "Thank You", language: hi_in, parent_id: message_tags_hi.id})

    Repo.insert!(%Contact{phone: "917834811114", name: "Default Contact"})

    Repo.insert!(%Contact{
      name: "Adelle Cavin",
      phone: Integer.to_string(Enum.random(123_456_789..9_876_543_210))
    })

    Repo.insert!(%Contact{
      name: "Margarita Quinteros",
      phone: Integer.to_string(Enum.random(123_456_789..9_876_543_210))
    })

    Repo.insert!(%Contact{
      name: "Chrissy Cron",
      phone: Integer.to_string(Enum.random(123_456_789..9_876_543_210))
    })

    Repo.insert!(%Contact{
      name: "Hailey Wardlaw",
      phone: Integer.to_string(Enum.random(123_456_789..9_876_543_210))
    })

    Repo.insert!(%BSP{
      name: "gupshup",
      url: "test_url",
      api_end_point: "test"
    })

    Repo.insert!(%Organization{
      name: "Slam Out Loud",
      contact_name: "Jigyasa and Gaurav",
      email: "jigyasa@glific.org",
      bsp_id: 1,
      bsp_key: "random",
      wa_number: Integer.to_string(Enum.random(123_456_789..9_876_543_210))
    })
  end
end