# frozen_string_literal: true

require_dependency 'court_data_adaptor'

class LaaReferencesController < ApplicationController
  before_action :load_and_authorize_defendant_search,
                :set_defendant_uuid_if_required,
                :set_defendant_if_required,
                :set_prosecution_case_reference_if_required,
                :set_link_attempt

  add_breadcrumb :search_filter_breadcrumb_name, :new_search_filter_path
  add_breadcrumb :search_breadcrumb_name, :search_breadcrumb_path
  add_breadcrumb (proc { |v| v.prosecution_case_name(v.controller.prosecution_case_reference) }),
                 (proc { |v| v.prosecution_case_path(v.controller.prosecution_case_reference) })
  add_breadcrumb (proc { |v| v.controller.defendant.name }),
                 (proc { |v| v.defendant_path(v.controller.defendant.id) })

  rescue_from CourtDataAdaptor::Errors::BadRequest, with: :adaptor_error_handler

  def new; end

  def create
    authorize! :create, :link_maat_reference, message: I18n.t('unauthorized.default')

    link_laa_reference_and_redirect && return if @link_attempt.valid?
    render 'new'
  end

  def defendant_uuid
    @defendant_uuid ||= laa_reference_params[:id] || link_attempt_params[:defendant_id]
  end

  def defendant
    @defendant ||= @defendant_search.call
  end

  def prosecution_case_reference
    @prosecution_case_reference ||= laa_reference_params[:urn]
  end

  private

  def set_defendant_uuid_if_required
    defendant_uuid
  end

  def set_defendant_if_required
    defendant
  end

  def set_prosecution_case_reference_if_required
    prosecution_case_reference
  end

  def load_and_authorize_defendant_search
    @defendant_search = CourtDataAdaptor::Query::Defendant::ByUuid.new(defendant_uuid)
    authorize! :show, @defendant_search
  end

  def link_laa_reference_and_redirect
    laa_reference = resource.new(**resource_params)
    laa_reference.save

    redirect_to edit_defendant_path(defendant.id, urn: prosecution_case_reference)
    flash[:notice] = I18n.t('laa_reference.link.success')
  end

  def laa_reference_params
    params.permit(:id,
                  :urn,
                  link_attempt: %i[maat_reference defendant_id])
  end

  def link_attempt_params
    return unless laa_reference_params[:link_attempt]

    laa_reference_params[:link_attempt].merge(no_maat_id: no_maat_id?,
                                              username: current_user.username)
  end

  def resource
    CourtDataAdaptor::Resource::LaaReference
  end

  def resource_params
    @resource_params ||= @link_attempt.to_link_attributes
  end

  def no_maat_id?
    params[:commit] == 'Create link without MAAT ID'
  end

  def error_messages
    @errors.map { |k, v| "#{k.humanize} #{v.join(', ')}" }.join("\n")
  end

  def set_link_attempt
    @link_attempt = if link_attempt_params
                      LinkAttempt.new(link_attempt_params)
                    else
                      LinkAttempt.new
                    end
  end

  def adaptor_error_handler(exception)
    @errors = exception.errors
    flash.now[:alert] = I18n.t('laa_reference.link.failure', error_messages: error_messages)
    render 'new'
  end
end
