class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :ensure_tab_session, if: :authenticated?

  private
    def ensure_tab_session
      session[:open_tabs] ||= []

      unless session[:open_tabs].any? { |t| t["id"] == "overview" }
        session[:open_tabs].unshift({ "id" => "overview", "label" => "개요", "url" => "/" })
      end

      session[:active_tab] ||= "overview"
    end
end
