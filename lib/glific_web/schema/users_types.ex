defmodule GlificWeb.Schema.UserTypes do
  @moduledoc """
  GraphQL Representation of Glific's User DataType
  """
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Glific.Repo
  alias GlificWeb.Resolvers

  object :user_result do
    field :user, :user
    field :errors, list_of(:input_error)
  end

  object :user do
    field :id, :id
    field :name, :string
    field :phone, :string
    field :roles, list_of(:string)

    field :groups, list_of(:group) do
      resolve(dataloader(Repo))
    end
  end

  @desc "Filtering options for users"
  input_object :user_filter do
    @desc "Match the name"
    field :name, :string

    @desc "Match the phone"
    field :phone, :string
  end

  input_object :user_input do
    field :name, :string
    field :roles, list_of(:string)
    field :password, :string
    field :otp, :string
  end

  object :user_queries do
    @desc "get the details of one user"
    field :user, :user_result do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Users.user/3)
    end

    @desc "Get a list of all users filtered by various criteria"
    field :users, list_of(:user) do
      arg(:filter, :user_filter)
      arg(:opts, :opts)
      resolve(&Resolvers.Users.users/3)
    end

    @desc "Get a count of all users filtered by various criteria"
    field :count_users, :integer do
      arg(:filter, :user_filter)
      resolve(&Resolvers.Users.count_users/3)
    end
  end

  object :user_mutations do
    field :update_user, :user_result do
      arg(:id, non_null(:id))
      arg(:input, :user_input)
      resolve(&Resolvers.Users.update_user/3)
    end

    field :delete_user, :user_result do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Users.delete_user/3)
    end
  end
end
