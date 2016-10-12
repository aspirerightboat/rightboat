class ConvertImportParamToHash < ActiveRecord::Migration
  def change
    Import.where('param LIKE ?', '%ActionController%').each do |i|
      i.update_column(:param, i.param.permit!.to_h)
    end
  end
end
