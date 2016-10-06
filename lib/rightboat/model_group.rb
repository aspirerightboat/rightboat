module Rightboat
  class ModelGroup

    def self.make_group_name(model_name)
      model_name = model_name.strip
      if model_name =~ /\A\d/
        model_name.match(/\A([^ ]+)/)[1]
      else
        model_name.match(/\A([^ ]+(?: \D[^ ]*)*)/)[1]
      end
    end

    def self.group_model_infos(model_infos)
      last_model_group = nil

      model_infos.each_with_object([]) do |model_info, arr|
        model_name = model_info[2]
        model_group = make_group_name(model_name)
        if last_model_group && model_group.casecmp(last_model_group) == 0
          arr.last << model_info
        else
          arr << [model_info]
        end
        last_model_group = model_group
      end
    end

  end
end
