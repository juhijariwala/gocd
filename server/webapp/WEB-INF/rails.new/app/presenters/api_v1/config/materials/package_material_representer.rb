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
            class PackageMaterialRepresenter < ApiV1::BaseRepresenter
                alias_method :material_config, :represented
        
                property :package_id, as: :ref, exec_context: :decorator
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
        
                def package_id
                    material_config.getPackageId
                  end
        
                def package_id=(value)
                    material_config.setPackageId(value)
                  end
              end
          end
      end
  end