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
  class MaterialConfigRepresenter < ApiV1::BaseRepresenter
    alias_method :material_config, :represented

    property :description, exec_context: :decorator, decorator: lambda { |thing, *|

                           case thing.getClass.getName
                             when 'com.thoughtworks.go.config.materials.git.GitMaterialConfig'
                               GitMaterialRepresenter
                             when 'com.thoughtworks.go.config.materials.mercurial.HgMaterialConfig'
                               HgMaterialRepresenter
                             when 'com.thoughtworks.go.config.materials.svn.SvnMaterialConfig'
                               SvnMaterialRepresenter
                             when 'com.thoughtworks.go.config.materials.perforce.P4MaterialConfig'
                               PerforceMaterialRepresenter
                             when 'com.thoughtworks.go.config.materials.tfs.TfsMaterialConfig'
                               TFSMaterialRepresenter
                             when 'com.thoughtworks.go.config.materials.dependency.DependencyMaterialConfig'
                               PipelineMaterialRepresenter
                             else

                           end
                         }
    property :getFingerprint, as: :fingerprint
    property :getTypeForDisplay, as: :type

    def description
      material_config
    end

    class GitMaterialRepresenter < ApiV1::BaseRepresenter
      alias_method :material_config, :represented
      property :getUrl, as: :url
      property :getBranch, as: :branch

    end

    class HgMaterialRepresenter < ApiV1::BaseRepresenter
      alias_method :material_config, :represented

      property :getUrl, as: :url
    end

    class SvnMaterialRepresenter < ApiV1::BaseRepresenter
      alias_method :material_config, :represented

      property :getUserName, as: :username
      property :isCheckExternals, as: :check_externals
      property :getUrl, as: :url

    end

    class PerforceMaterialRepresenter < ApiV1::BaseRepresenter
      alias_method :material_config, :represented
      property :getUserName, as: :username
      property :getUseTickets, as: :use_tickets
      property :getView, as: :view
      property :getUrl, as: :url
    end

    class TFSMaterialRepresenter < ApiV1::BaseRepresenter
      alias_method :material_config, :represented
      property :getUserName, as: :username
      property :getProjectPath, as: :project_path
      property :getDomain, as: :domain
      property :getUrl, as: :url
    end

    class PipelineMaterialRepresenter < ApiV1::BaseRepresenter
      alias_method :material_config, :represented

      property :getPipelineStageName, as: :pipelinestage
    end

  end
end
