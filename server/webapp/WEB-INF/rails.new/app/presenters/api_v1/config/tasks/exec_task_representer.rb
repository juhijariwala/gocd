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
      class ExecTaskRepresenter < ApiV1::Config::Tasks::BaseTaskRepresenter
        alias_method :exec_task, :represented

        property :command
        collection :arguments, skip_nil: true, exec_context: :decorator
        property :args, skip_nil: true, exec_context: :decorator
        property :working_dir, exec_context: :decorator

        def working_dir
          exec_task.workingDirectory
        end

        def working_dir=(value)
          exec_task.setWorkingDirectory(value)
        end

        def arguments
          return nil if exec_task.getArgList().isEmpty()
          exec_task.getArgList().map { |arg| arg.getValue() }
        end

        def arguments=(value)
          exec_task.setArgsList(value)
        end

        def args
          return nil if com.thoughtworks.go.util.StringUtil.isBlank(exec_task.getArgs)
          exec_task.getArgs
        end

        def args=(value)
          exec_task.setArgs(value)
        end
      end
    end
  end
end