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
    class PipelineConfigRepresenter < ApiV1::BaseRepresenter
      alias_method :pipeline, :represented
      java_import com.thoughtworks.go.config.materials.ScmMaterialConfig unless defined? ScmMaterialConfig
      java_import com.thoughtworks.go.config.materials.PackageMaterialConfig unless defined? PackageMaterialConfig
      java_import com.thoughtworks.go.config.materials.PluggableSCMMaterialConfig unless defined? PluggableSCMMaterialConfig
      java_import com.thoughtworks.go.config.materials.svn.SvnMaterialConfig unless defined? SvnMaterialConfig
      java_import com.thoughtworks.go.config.materials.mercurial.HgMaterialConfig unless defined? HgMaterialConfig
      java_import com.thoughtworks.go.config.materials.perforce.P4MaterialConfig unless defined? P4MaterialConfig
      java_import com.thoughtworks.go.config.materials.git.GitMaterialConfig unless defined? GitMaterialConfig
      java_import com.thoughtworks.go.config.materials.tfs.TfsMaterialConfig unless defined? TfsMaterialConfig

      link :self do |opts|
        opts[:url_builder].apiv1_admin_pipeline_url(pipeline.name)
      end

      link :doc do |opts|
        'http://api.go.cd/#pipeline_config'
      end

      link :find do |opts|
        opts[:url_builder].apiv1_admin_pipeline_url(':name')
      end

      def name
        pipeline.name().to_s
      end

      def name=(name)
        pipeline.setName(name)
      end

      def params
        pipeline.getParams()
      end

      def params=(value)
        pipeline.setParams(ParamsConfig.new(value.to_java(ParamConfig)))
      end

      def environment_variables
        pipeline.getVariables()
      end

      def environment_variables=(array_of_variables)
        pipeline.setVariables(EnvironmentVariablesConfig.new(array_of_variables))
      end

      def materials
        pipeline.materialConfigs()
      end

      def materials=(value)
        pipeline.materialConfigs().clear
        value.each { |material| pipeline.materialConfigs().add(material) }
      end

      def stages
        pipeline.getStages() if !pipeline.getStages().isEmpty
      end

      def stages=(value)
        pipeline.getStages().clear()
        value.each { |stage| pipeline.addStageWithoutValidityAssertion(stage) }
      end

      def tracking_tool
            if pipeline.getTrackingTool()
              pipeline.getTrackingTool()
            elsif pipeline.getMingleConfig().isDefined()
              pipeline.getMingleConfig()
            end

      end

      def tracking_tool=(value)
        if value.instance_of? com.thoughtworks.go.config.MingleConfig
          pipeline.setMingleConfig(value)
        elsif value.instance_of? com.thoughtworks.go.config.TrackingTool
          pipeline.setTrackingTool(value)
        end
      end

      def enable_pipeline_locking
        pipeline.isLock
      end

      def enable_pipeline_locking=(value)
        pipeline.lockExplicitly if value
        pipeline.unlockExplicitly unless value
      end

      def template
        pipeline.getTemplateName().to_s if pipeline.getTemplateName()
      end

      def template=(value)
        pipeline.setTemplateName(CaseInsensitiveString.new(value)) if value
      end

      property :label_template
      property :enable_pipeline_locking, exec_context: :decorator
      property :name, exec_context: :decorator
      property :template, exec_context: :decorator

      collection :params, exec_context: :decorator, decorator: ApiV1::Config::ParamRepresenter, class: com.thoughtworks.go.config.ParamConfig
      collection :environment_variables, exec_context: :decorator, embedded: false, decorator: ApiV1::Config::EnvironmentVariableRepresenter, class: com.thoughtworks.go.config.EnvironmentVariableConfig
      collection :materials, exec_context: :decorator, decorator: ApiV1::Config::Materials::MaterialRepresenter,
                 skip_parse:           lambda { |fragment, options|
                   !fragment.respond_to?(:has_key?) || fragment.empty?
                 },
                 class:                    lambda { |object, *|
                   case object['type'] || object[:type]
                     when GitMaterialConfig::TYPE
                       GitMaterialConfig
                     when SvnMaterialConfig::TYPE
                       SvnMaterialConfig
                     when HgMaterialConfig::TYPE
                       HgMaterialConfig
                     when P4MaterialConfig::TYPE
                       P4MaterialConfig
                     when TfsMaterialConfig::TYPE
                       TfsMaterialConfig
                     when DependencyMaterialConfig::TYPE
                       DependencyMaterialConfig
                     when PackageMaterialConfig::TYPE
                       PackageMaterialConfig
                     when PluggableSCMMaterialConfig::TYPE
                       PluggableSCMMaterialConfig
                     else
                       raise UnprocessableEntity, "Invalid Material type :#{object['type']||object[:type]}. It can be one of '{DependencyMaterial, SvnMaterial, HgMaterial, P4Material, GitMaterial, TfsMaterial, PackageMaterial, PluggableSCMMaterial}"
                   end
                 }
      collection :stages, embedded: false, exec_context: :decorator, decorator: ApiV1::Config::StageRepresenter, class: com.thoughtworks.go.config.StageConfig

      property :tracking_tool,
               exec_context: :decorator,
               decorator:    ApiV1::Config::TrackingTool::TrackingToolRepresenter,
               skip_parse:           lambda { |fragment, options|
                 !fragment.respond_to?(:has_key?) || fragment.empty?
               },
               class: lambda { |object, *|
                 case object['type']
                   when 'external'
                     com.thoughtworks.go.config.TrackingTool
                   when 'mingle'
                     com.thoughtworks.go.config.MingleConfig
                   else
                     raise UnprocessableEntity, "Invalid Tracking Tool type. It can be one of '{mingle, external}"
                 end
               }

      property :timer, decorator: ApiV1::Config::TimerRepresenter, class: com.thoughtworks.go.config.TimerConfig
      property :errors, exec_context: :decorator, decorator: ApiV1::Config::ErrorRepresenter, skip_parse: true, skip_render: lambda { |object, options| object.empty? }

      def errors
        pipeline.errors.addAll(pipeline.materialConfigs.errors)
        pipeline.errors
      end
    end
  end
end
