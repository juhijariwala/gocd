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
  class Config::StageRepresenter < ApiV1::BaseRepresenter
    include JavaImports
    alias_method :stage, :represented

    property :name, exec_context: :decorator
    property :fetch_materials, exec_context: :decorator
    property :clean_working_directory, exec_context: :decorator
    property :never_cleanup_artifacts, exec_context: :decorator
    property :approval, decorator: ApiV1::Config::ApprovalRepresenter, class: com.thoughtworks.go.config.Approval
    collection :environment_variables, exec_context: :decorator, embedded: false, decorator: ApiV1::Config::EnvironmentVariableRepresenter, class: com.thoughtworks.go.config.EnvironmentVariableConfig, skip_nil: true, render_empty: false
    collection :jobs, exec_context: :decorator, embedded: false, decorator: ApiV1::Config::JobRepresenter, class: com.thoughtworks.go.config.JobConfig
    property :errors, exec_context: :decorator,decorator: ApiV1::Config::ErrorRepresenter, skip_parse: true, skip_render: lambda { |object, options| object.empty? }


    def fetch_materials
      stage.isFetchMaterials()
    end

    def fetch_materials=(value)
      stage.setFetchMaterials(value)
    end

    def clean_working_directory
      stage.isCleanWorkingDir
    end

    def clean_working_directory=(value)
      stage.setCleanWorkingDir(value)
    end

    def never_cleanup_artifacts
      stage.isArtifactCleanupProhibited()
    end

    def never_cleanup_artifacts=(value)
      stage.setArtifactCleanupProhibited(value)
    end

    def jobs
      stage.getJobs()
    end

    def jobs=(value)
      stage.setJobs(JobConfigs.new(value.to_java(JobConfig)))
    end

    def name
      stage.name().to_s
    end

    def name=(value)
      stage.setName(value)
    end

    def environment_variables
      stage.getVariables()
    end

    def environment_variables=(array_of_variables)
      stage.setVariables(EnvironmentVariablesConfig.new(array_of_variables))
    end

    def errors
      stage.errors.addAll(jobs.errors)
      stage.errors.addAll(environment_variables.errors)
      stage.errors
    end

  end
end
