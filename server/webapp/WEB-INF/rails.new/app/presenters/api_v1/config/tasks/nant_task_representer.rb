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
      class NantTaskRepresenter < ApiV1::Config::Tasks::BaseTaskRepresenter
        alias_method :nant_task, :represented

        property :working_dir,exec_context: :decorator
        property :build_file
        property :target
        property :nant_path

        def working_dir
          nant_task.workingDirectory()
        end

        def working_dir=(value)
          nant_task.setWorkingDirectory(value)
        end
      end
    end
  end
end