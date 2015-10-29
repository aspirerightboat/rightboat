class RunImportJob
  def initialize(import_id)
    @import_id = import_id
  end

  def perform
    import = Import.find(@import_id)
    if import.active? && !import.running?(false)
      import.source_class.new(import).run
    end
  end
end