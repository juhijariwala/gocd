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
        alias_method :material_config, :represented

        property :getType, as: :type, skip_parse: true
        nested :attributes,
                 decorator: lambda { |material_config, *|
                   case material_config.getClass.getName
                     when 'com.thoughtworks.go.config.materials.git.GitMaterialConfig'
                       GitMaterialRepresenter
                     when 'com.thoughtworks.go.config.materials.svn.SvnMaterialConfig'
                       SvnMaterialRepresenter
                     when 'com.thoughtworks.go.config.materials.mercurial.HgMaterialConfig'
                       HgMaterialRepresenter
                     when 'com.thoughtworks.go.config.materials.perforce.P4MaterialConfig'
                       PerforceMaterialRepresenter
                     when 'com.thoughtworks.go.config.materials.tfs.TfsMaterialConfig'
                       TfsMaterialRepresenter
                     when 'com.thoughtworks.go.config.materials.dependency.DependencyMaterialConfig'
                       DependencyMaterialRepresenter
                     when 'com.thoughtworks.go.config.materials.PackageMaterialConfig'
                       PackageMaterialRepresenter
                     when 'com.thoughtworks.go.config.materials.PluggableSCMMaterialConfig'
                       PluggableScmMaterialRepresenter
                     else
                       raise "Not implemented"
                   end
                 }
        property :errors, decorator: ApiV1::Config::ErrorRepresenter, skip_parse: true, skip_render: lambda { |object, options| object.empty? }

      end
    end
  end
end