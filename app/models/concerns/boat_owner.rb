module BoatOwner
  extend ActiveSupport::Concern

  included do
    has_many :boats, inverse_of: self.name.underscore, dependent: :restrict_with_error

    before_destroy :ensure_no_boat_dependencies
  end

  private

  def ensure_no_boat_dependencies
    if Boat.where("#{self.class.name.underscore}_id = ?", id).exists?
      errors.add :base, 'Cannot delete with boats'
      throw :abort
    end
  end

end
