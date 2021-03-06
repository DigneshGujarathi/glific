defmodule GlificWeb.Schema.SearchTypes do
  @moduledoc """
  GraphQL Representation of Glific's Search DataType
  """

  use Absinthe.Schema.Notation

  alias GlificWeb.Resolvers

  object :saved_search_result do
    field :saved_search, :saved_search
    field :errors, list_of(:input_error)
  end

  object :saved_search do
    field :id, :id
    field :label, :string
    field :shortcode, :string
    field :args, :json

    # the number of contacts this saved search matches
    # this is an expensive operation
    field :count, :integer do
      resolve(fn saved_search, resolution, context ->
        Resolvers.Searches.saved_search_count(resolution, %{id: saved_search.id}, context)
      end)
    end
  end

  input_object :saved_search_filter do
    field :label, :string
    field :shortcode, :string
  end

  input_object :saved_search_input do
    field :label, :string
    field :shortcode, :string
    field :args, :json
  end

  @desc "Filtering options for search"
  input_object :search_filter do
    @desc "Include conversations with these tags"
    field :include_tags, list_of(:gid)

    @desc "Exclude conversations with these tags"
    field :exclude_tags, list_of(:gid)
  end

  object :search_queries do
    @desc "Search for conversations"
    field :search, list_of(:conversation) do
      arg(:save_search, :boolean, default_value: false)

      @desc "A label and shortcode for saved search object"
      arg(:save_search_label, :string)
      arg(:save_search_shortcode, :string)

      arg(:term, non_null(:string))
      arg(:filter, :search_filter)
      arg(:message_opts, non_null(:opts))
      arg(:contact_opts, non_null(:opts))
      resolve(&Resolvers.Searches.search/3)
    end

    @desc "get the details of one saved search"
    field :saved_search, :saved_search_result do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Searches.saved_search/3)
    end

    @desc "Get a list of all searches"
    field :saved_searches, list_of(:saved_search) do
      arg(:filter, :saved_search_filter)
      arg(:opts, :opts)
      resolve(&Resolvers.Searches.saved_searches/3)
    end

    field :saved_search_count, :integer do
      # the id of the saved search
      arg(:id, non_null(:id))

      # if we want to add a search term
      arg(:term, :string)

      resolve(&Resolvers.Searches.saved_search_count/3)
    end

    @desc "Convenience function to run a search for a specific saved search id"
    field :saved_search_execute, list_of(:conversation) do
      # the id of the saved search
      arg(:id, non_null(:id))

      # if we want to add a search term
      arg(:term, :string)

      resolve(&Resolvers.Searches.saved_search_execute/3)
    end
  end

  object :search_mutations do
    field :create_saved_search, :saved_search_result do
      arg(:input, non_null(:saved_search_input))
      resolve(&Resolvers.Searches.create_saved_search/3)
    end

    field :update_saved_search, :saved_search_result do
      arg(:id, non_null(:id))
      arg(:input, :saved_search_input)
      resolve(&Resolvers.Searches.update_saved_search/3)
    end

    field :delete_saved_search, :saved_search_result do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Searches.delete_saved_search/3)
    end
  end
end
