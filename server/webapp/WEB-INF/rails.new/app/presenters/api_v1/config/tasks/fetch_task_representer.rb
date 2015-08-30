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
    module Tasks
      class FetchTaskRepresenter < ApiV1::Config::Tasks::BaseTaskRepresenter
        alias_method :fetch_task, :represented

        property :pipeline_name, as: :pipeline, decorator: ApiV1::Config::CaseInsensitiveStringRepresenter, class: String
        property :stage, decorator: ApiV1::Config::CaseInsensitiveStringRepresenter, class: String
        property :job, decorator: ApiV1::Config::CaseInsensitiveStringRepresenter, class: String
        property :is_source_a_file, exec_context: :decorator
        property :source, exec_context: :decorator
        property :dest, as: :destination

        def is_source_a_file
          fetch_task.isSourceAFile
        end

        def is_source_a_file=(value)
          @is_source_a_file = value
        end

        def source
          return fetch_task.getRawSrcfile if fetch_task.isSourceAFile
          fetch_task.getRawSrcdir
        end

        def source=(value)
          if @is_source_a_file
            fetch_task.setSrcfile(value)
          else
            fetch_task.setSrcdir(value)
          end
        end
      end
    end
  end
end