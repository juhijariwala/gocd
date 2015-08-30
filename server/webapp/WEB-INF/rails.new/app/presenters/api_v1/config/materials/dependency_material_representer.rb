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
      class DependencyMaterialRepresenter < ApiV1::BaseRepresenter
        alias_method :material_config, :represented

        property :pipeline_name, as: :pipeline, decorator: ApiV1::Config::CaseInsensitiveStringRepresenter, class: String
        property :stage_name, as: :stage, decorator: ApiV1::Config::CaseInsensitiveStringRepresenter, class: String
        property :name, exec_context: :decorator, decorator: ApiV1::Config::CaseInsensitiveStringRepresenter, class: String
        property :auto_update, exec_context: :decorator


        def name
          material_config.getName
        end

        def name=(value)
          @represented.setName(value) unless (material_config.instance_of?(PackageMaterialConfig) || material_config.instance_of?(PluggableSCMMaterialConfig))
        end

        def auto_update
          material_config.autoUpdate
        end

        def auto_update=(value)
          @represented.setAutoUpdate(value) unless (material_config.instance_of?(PackageMaterialConfig) || material_config.instance_of?(PluggableSCMMaterialConfig))
        end
      end
    end
  end
end