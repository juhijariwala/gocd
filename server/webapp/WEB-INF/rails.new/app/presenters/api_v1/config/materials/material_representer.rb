##########################################################################
# Copyright 2015 ThoughtWorks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

module ApiV1
  module Config
    module Materials
      class MaterialRepresenter < ApiV1::BaseRepresenter
        MATERIAL_TYPE_MAP = [GitMaterialConfig,
                             SvnMaterialConfig,
                             HgMaterialConfig,
                             P4MaterialConfig,
                             TfsMaterialConfig,
                             DependencyMaterialConfig,
                             PackageMaterialConfig,
                             PluggableSCMMaterialConfig
        ].inject({}) do |memo, material_type|
          memo[material_type.const_get(:TYPE)] = material_type
          memo
        end

        MATERIAL_TYPE_TO_REPRESENTER_MAP= {
          'com.thoughtworks.go.config.materials.git.GitMaterialConfig'               => GitMaterialRepresenter,
          'com.thoughtworks.go.config.materials.svn.SvnMaterialConfig'               => SvnMaterialRepresenter,
          'com.thoughtworks.go.config.materials.mercurial.HgMaterialConfig'          => HgMaterialRepresenter,
          'com.thoughtworks.go.config.materials.perforce.P4MaterialConfig'           => PerforceMaterialRepresenter,
          'com.thoughtworks.go.config.materials.tfs.TfsMaterialConfig'               => TfsMaterialRepresenter,
          'com.thoughtworks.go.config.materials.dependency.DependencyMaterialConfig' => DependencyMaterialRepresenter,
          'com.thoughtworks.go.config.materials.PackageMaterialConfig'               => PackageMaterialRepresenter,
          'com.thoughtworks.go.config.materials.PluggableSCMMaterialConfig'          => PluggableScmMaterialRepresenter
        }
        alias_method :material_config, :represented

        property :getType, as: :type, skip_parse: true
        nested :attributes,
               decorator: lambda { |material_config, *|
                 MATERIAL_TYPE_TO_REPRESENTER_MAP[material_config.getClass.getName]
               }
        property :errors, decorator: ApiV1::Config::ErrorRepresenter, skip_parse: true, skip_render: lambda { |object, options| object.empty? }

        class << self
          def get_material_type(type)
            if klass = MATERIAL_TYPE_MAP[type]
              klass
            else
              raise UnprocessableEntity, "Invalid material type '#{type}'. It has to be one of '#{MATERIAL_TYPE_MAP.keys.join(' ')}'"
            end
          end
        end

      end
    end
  end
end