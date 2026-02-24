class Om::PreOrderFileUploadForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :upload_file

  def persisted?
    false
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, "q")
  end
end
