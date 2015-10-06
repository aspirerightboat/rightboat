module BoatOwner
  extend ActiveSupport::Concern

  included do

    has_many :boats, inverse_of: self.name.underscore, dependent: :restrict_with_error

    before_destroy :ensure_boats

    private

      def ensure_boats
        unless status = Boat.where("#{self.class.name.underscore}_id = ?", id).empty?
          errors.add :base, 'Cannot delete with boats'
        end
        status
      end
  end
end