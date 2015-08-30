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
      
            class TfsMaterialRepresenter < ScmMaterialRepresenter
                alias_method :material_config, :represented
        
                property :domain
                property :user_name, as: :username
                property :password, skip_nil: true, exec_context: :decorator
                property :encrypted_password, skip_nil: true, exec_context: :decorator
        
                property :project_path
        
                def password
                end
        
                def password=(value)
                    material_config.setPassword(value)
                  end
        
                def encrypted_password
                    material_config.getEncryptedPassword()
                end
        
                def encrypted_password=(value)
                    material_config.setEncryptedPassword(value)
                end
        
              end
          end
      end
  end