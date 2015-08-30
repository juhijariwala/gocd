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
  class Config::StageAuthorizationRepresenter < ApiV1::BaseRepresenter
    alias_method :authorization, :represented

    collection :roles, embedded: false, exec_context: :decorator, decorator: ApiV1::Config::CaseInsensitiveStringRepresenter, class: String, skip_nil: true, render_empty: false
    collection :users, embedded: false, exec_context: :decorator, decorator: ApiV1::Config::CaseInsensitiveStringRepresenter, class: String, skip_nil: true, render_empty: false

    def roles
      authorization.getRoles().map { |role| role.getName().to_s }
    end

    def roles= value
      value.each { |role| authorization.add(AdminRole.new(CaseInsensitiveString.new(role))) }
    end

    def users
      authorization.getUsers().map { |role| role.getName().to_s }
    end

    def users=(value)
      value.each { |user| authorization.add(AdminUser.new(CaseInsensitiveString.new(user))) }
    end
  end
end