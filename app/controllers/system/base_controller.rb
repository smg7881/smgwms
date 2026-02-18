class System::BaseController < ApplicationController
  before_action :require_admin!
end
