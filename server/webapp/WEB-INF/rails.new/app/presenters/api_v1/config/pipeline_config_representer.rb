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

      property :label_template
      property :enable_pipeline_locking,
               getter: lambda { |options| self.isLock },
               setter: lambda { |val, options| val ? self.lockExplicitly : self.unlockExplicitly }

      property :name, case_insensitive_string: true
      property :template_name, as: :template, case_insensitive_string: true

      collection :params, exec_context: :decorator, decorator: ApiV1::Config::ParamRepresenter,
                 expect_hash:           true,
                 class:                 com.thoughtworks.go.config.ParamConfig

      collection :environment_variables,
                 exec_context: :decorator,
                 decorator:    ApiV1::Config::EnvironmentVariableRepresenter,
                 expect_hash:  true,
                 class:        com.thoughtworks.go.config.EnvironmentVariableConfig

      collection :materials,
                 exec_context: :decorator,
                 decorator:    ApiV1::Config::Materials::MaterialRepresenter,
                 expect_hash:  true,
                 class:        lambda { |fragment, *|
                   ApiV1::Config::Materials::MaterialRepresenter.get_material_type(fragment[:type]||fragment['type'])
                 }
      collection :stages,
                 exec_context: :decorator,
                 decorator:    ApiV1::Config::StageRepresenter,
                 expect_hash:  true,
                 class:        com.thoughtworks.go.config.StageConfig

      property :tracking_tool,
               exec_context: :decorator,
               decorator:    ApiV1::Config::TrackingTool::TrackingToolRepresenter,
               expect_hash:  true,
               class:        lambda { |object, *|
                 ApiV1::Config::TrackingTool::TrackingToolRepresenter.get_class(object[:type]||object['type'])
               }

      property :timer,
               decorator: ApiV1::Config::TimerRepresenter,
               class:     com.thoughtworks.go.config.TimerConfig
      property :errors,
               exec_context: :decorator,
               decorator:    ApiV1::Config::ErrorRepresenter,
               skip_parse:   true,
               skip_render:  lambda { |object, options| object.empty? }


      delegate :name, :name=, to: :pipeline
      delegate :params, :params=, to: :pipeline

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

      def errors
        pipeline.errors.addAll(pipeline.materialConfigs.errors)
        pipeline.errors
      end

    end
  end
end
