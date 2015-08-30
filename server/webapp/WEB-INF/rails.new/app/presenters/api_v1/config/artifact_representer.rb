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
  class Config::ArtifactRepresenter < ApiV1::BaseRepresenter
    alias_method :artifact, :represented

    property :src, as: :source
    property :dest, as: :destination
    property :type, exec_context: :decorator, skip_parse: true
    property :errors, exec_context: :decorator, decorator: ApiV1::Config::ErrorRepresenter, skip_parse: true, skip_render: lambda { |object, options| object.empty? }


    def type
      case artifact.getArtifactType
        when ArtifactType::unit
          "test"
        else
          "build"
      end
    end

    def errors
      mapped_errors = {}
      artifact.errors.each do |key, value|
        mapped_errors[matching_error_key(key)] = value
      end
      mapped_errors
    end

    private
    def error_keys
      {"src" => "source", "dest" => "destination"}
    end

    def matching_error_key key
      return error_keys[key] if error_keys[key]
      key
    end
  end
end