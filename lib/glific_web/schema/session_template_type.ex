defmodule GlificWeb.Schema.SessionTemplateTypes do
  @moduledoc """
  GraphQL Representation of Glific's Session Template DataType
  """

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Glific.Repo
  alias GlificWeb.Resolvers

  object :session_template_result do
    field :session_template, :session_template
    field :errors, list_of(:input_error)
  end

  object :session_template do
    field :id, :id
    field :label, :string
    field :body, :string
    field :type, :message_type_enum
    field :shortcode, :string
    field :is_hsm, :boolean
    field :number_parameters, :integer
    field :is_reserved, :boolean
    field :is_active, :boolean
    field :is_source, :boolean

    field :language, :language do
      resolve(dataloader(Repo))
    end

    field :message_media, :message_media do
      resolve(dataloader(Repo))
    end

    field :parent, :session_template do
      resolve(dataloader(Repo))
    end
  end

  @desc "Filtering options for session_templates"
  input_object :session_template_filter do
    @desc "Match term with label, body or shortcode of template"
    field :term, :string

    @desc "Match the label"
    field :label, :string

    @desc "Match the body of template"
    field :body, :string

    @desc "Match the shortcode of template"
    field :shortcode, :string

    @desc "Match the hsm template message"
    field :is_hsm, :boolean

    @desc "Match the parent"
    field :parent, :string

    @desc "Match the parent"
    field :parent_id, :integer

    @desc "Match a language"
    field :language, :string

    @desc "Match a language id"
    field :language_id, :integer

    @desc "Match the active flag"
    field :is_active, :boolean

    @desc "Match the reserved flag"
    field :is_reserved, :boolean
  end

  input_object :session_template_input do
    field :label, :string
    field :body, :string
    field :type, :message_type_enum
    field :shortcode, :string
    field :is_hsm, :boolean
    field :number_parameters, :integer
    field :is_active, :boolean
    field :is_source, :boolean
    field :language_id, :id
  end

  input_object :message_to_template_input do
    field :label, :string
    field :shortcode, :string
    field :language_id, :id
  end

  object :session_template_queries do
    @desc "get the details of one session_template"
    field :session_template, :session_template_result do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Templates.session_template/3)
    end

    @desc "Get a list of all session_templates filtered by various criteria"
    field :session_templates, list_of(:session_template) do
      arg(:filter, :session_template_filter)
      arg(:opts, :opts)
      resolve(&Resolvers.Templates.session_templates/3)
    end

    @desc "Get a count of all session_templates filtered by various criteria"
    field :count_session_templates, :integer do
      arg(:filter, :session_template_filter)
      resolve(&Resolvers.Templates.count_session_templates/3)
    end
  end

  object :session_template_mutations do
    field :create_session_template, :session_template_result do
      arg(:input, non_null(:session_template_input))
      resolve(&Resolvers.Templates.create_session_template/3)
    end

    field :update_session_template, :session_template_result do
      arg(:id, non_null(:id))
      arg(:input, :session_template_input)
      resolve(&Resolvers.Templates.update_session_template/3)
    end

    field :delete_session_template, :session_template_result do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Templates.delete_session_template/3)
    end

    field :send_session_message, :session_template_result do
      arg(:id, non_null(:id))
      arg(:receiver_id, non_null(:id))
      resolve(&Resolvers.Templates.send_session_message/3)
    end

    field :create_template_form_message, :session_template_result do
      arg(:message_id, non_null(:id))
      arg(:input, :message_to_template_input)
      resolve(&Resolvers.Templates.create_template_from_message/3)
    end
  end
end
