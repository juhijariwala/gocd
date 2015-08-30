/*************************GO-LICENSE-START*********************************
 * Copyright 2015 ThoughtWorks, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *************************GO-LICENSE-END***********************************/

package com.thoughtworks.go.config;

import java.util.HashMap;

import com.thoughtworks.go.config.materials.MaterialConfigs;
import com.thoughtworks.go.config.remote.ConfigReposConfig;
import com.thoughtworks.go.domain.materials.MaterialConfig;

/**
 * @understands providing right state required to validate a given config element
 */
public interface ValidationContext {
    ConfigReposConfig getConfigRepos();

    boolean isWithinPipelines();

    PipelineConfig getPipeline();

    MaterialConfigs getAllMaterialsByFingerPrint(String fingerprint);

    StageConfig getStage();

    boolean isWithinTemplates();

    String getParentDisplayName();

    Validatable getParent();

    JobConfig getJob();

    PipelineConfigs getPipelineGroup();

    PipelineTemplateConfig getTemplate();

    PipelineConfig getPipelineConfigByName(CaseInsensitiveString pipelineName);

    boolean shouldCheckConfigRepo();
    SecurityConfig getServerSecurityConfig();
}

