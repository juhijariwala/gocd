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

import com.thoughtworks.go.config.materials.MaterialConfigs;
import com.thoughtworks.go.config.remote.ConfigReposConfig;
import com.thoughtworks.go.util.Node;
import org.apache.commons.lang.NotImplementedException;

import java.util.Hashtable;

public class PipelineConfigSaveValidationContext implements ValidationContext {
    private final Validatable immediateParent;
    private boolean isWithinPipelines;
    private final PipelineConfigSaveValidationContext parentContext;
    private PipelineConfig pipeline;
    private StageConfig stage;
    private JobConfig job;

    private PipelineConfigSaveValidationContext(Validatable immediateParent) {
        this.immediateParent = immediateParent;
        this.parentContext = null;
    }

    private PipelineConfigSaveValidationContext(Validatable immediateParent, PipelineConfigSaveValidationContext parentContext) {
        this.immediateParent = immediateParent;
        this.parentContext = parentContext;
        if (immediateParent instanceof PipelineConfig) {
            this.pipeline = (PipelineConfig) immediateParent;
        } else if (parentContext.pipeline != null) {
            this.pipeline = parentContext.pipeline;
        }
        if (this.pipeline != null) {
            this.isWithinPipelines = !pipeline.hasTemplate();
        }
        if (immediateParent instanceof JobConfig) {
            this.job = (JobConfig) immediateParent;
        } else if (parentContext.getJob() != null) {
            this.job = parentContext.job;
        }
        if (immediateParent instanceof StageConfig) {
            this.stage = (StageConfig) immediateParent;
        } else if (parentContext.stage != null) {
            this.stage = parentContext.stage;
        }
    }

    public static PipelineConfigSaveValidationContext forChain(Validatable... validatables) {
        PipelineConfigSaveValidationContext tail = new PipelineConfigSaveValidationContext(null);
        for (Validatable validatable : validatables) {
            tail = tail.withParent(validatable);
        }
        return tail;
    }

    public PipelineConfigSaveValidationContext withParent(Validatable current) {
        return new PipelineConfigSaveValidationContext(current, this);
    }

    @Override
    public ConfigReposConfig getConfigRepos() {
        throw new NotImplementedException();
    }

    public JobConfig getJob() {
        return this.job;
    }

    public StageConfig getStage() {
        return this.stage;
    }

    public PipelineConfig getPipeline() {
        return this.pipeline;
    }

    public PipelineTemplateConfig getTemplate() {
        throw new NotImplementedException();
    }

    public String getParentDisplayName() {
        return getParent().getClass().getAnnotation(ConfigTag.class).value();
    }

    public Validatable getParent() {
        return immediateParent;
    }

    public boolean isWithinTemplates() {
        return !isWithinPipelines;
    }

    public boolean isWithinPipelines() {
        return isWithinPipelines;
    }

    @Override
    public boolean isWithinPipeline() {
        return getPipeline() != null;
    }

    public PipelineConfigs getPipelineGroup() {
        return PipelineConfigurationCache.getInstance().getPipelineGroup(pipeline.name().toString());
    }

    public Node getDependencyMaterialsFor(CaseInsensitiveString pipelineName) {
        return PipelineConfigurationCache.getInstance().getDependencyMaterialsFor(pipelineName);
    }

    @Override
    public String toString() {
        return "ValidationContext{" +
                "immediateParent=" + immediateParent +
                ", parentContext=" + parentContext +
                '}';
    }

    public MaterialConfigs getAllMaterialsByFingerPrint(String fingerprint) {
        return PipelineConfigurationCache.getInstance().getMatchingMaterialsFromConfig(fingerprint);
    }

    public PipelineConfig getPipelineConfigByName(CaseInsensitiveString pipelineName) {
        return PipelineConfigurationCache.getInstance().getPipelineConfig(pipelineName.toString());
    }

    @Override
    public boolean shouldCheckConfigRepo() {
        return false;
    }

    @Override
    public SecurityConfig getServerSecurityConfig() {
        return PipelineConfigurationCache.getInstance().getServerSecurityConfig();
    }

    public boolean doesTemplateExist(CaseInsensitiveString template) {
        return PipelineConfigurationCache.getInstance().doesTemplateExist(template);
    }
}
