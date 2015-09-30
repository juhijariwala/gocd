module ApiV1
  module Config
    module Materials
      class ScmMaterialRepresenter < ApiV1::BaseRepresenter
        alias_method :material_config, :represented

        property :url, getter: lambda { |options|
                       self.getUrlArgument().forCommandline() if self.getUrlArgument()
                     },
                 setter:       lambda { |value, options|
                   self.setUrl(value)
                 }
        property :folder, as: :destination
        property :filter,
                 decorator: ApiV1::Config::Materials::FilterRepresenter,
                 class:     com.thoughtworks.go.config.materials.Filter
        property :name,case_insensitive_string: true
        property :auto_update

      end
    end
  end
end