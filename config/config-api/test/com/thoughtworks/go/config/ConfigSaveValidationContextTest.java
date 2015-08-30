/*************************GO-LICENSE-START*********************************
 * Copyright 2014 ThoughtWorks, Inc.
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
import com.thoughtworks.go.config.materials.mercurial.HgMaterialConfig;
import com.thoughtworks.go.domain.PipelineGroups;
import com.thoughtworks.go.helper.GoConfigMother;
import com.thoughtworks.go.helper.PipelineConfigMother;
import org.junit.Before;
import org.junit.Test;

import static org.hamcrest.core.Is.is;
import static org.hamcrest.core.IsNull.nullValue;
import static org.junit.Assert.assertThat;

public class ConfigSaveValidationContextTest {

    @Before
    public void setUp() throws Exception {
    }

    @Test
    public void testShouldReturnTrueIfTemplatesIsAnAncestor() {
        ValidationContext context = ConfigSaveValidationContext.forChain(new BasicCruiseConfig(), new TemplatesConfig(), new PipelineTemplateConfig());
        assertThat(context.isWithinTemplates(), is(true));
    }

    @Test
    public void testShouldReturnFalseIfTemplatesIsNotAnAncestor() {
        ValidationContext context = ConfigSaveValidationContext.forChain(new BasicCruiseConfig(), new PipelineGroups(), new BasicPipelineConfigs(), new PipelineConfig());
        assertThat(context.isWithinTemplates(), is(false));
    }
    
    @Test
    public void shouldReturnAllMaterialsMatchingTheFingerprint() {
        CruiseConfig cruiseConfig = new BasicCruiseConfig();
        HgMaterialConfig hg = new HgMaterialConfig("url", null);
        for (int i=0; i<10; i++) {
            PipelineConfig pipelineConfig = PipelineConfigMother.pipelineConfig("pipeline" + i, new MaterialConfigs(hg));
            cruiseConfig.addPipeline("defaultGroup", pipelineConfig);
        }
        ValidationContext context = ConfigSaveValidationContext.forChain(cruiseConfig);

        assertThat(context.getAllMaterialsByFingerPrint(hg.getFingerprint()).size(), is(10));
    }

    @Test
    public void shouldReturnEmptyListWhenNoMaterialsMatch() {
        CruiseConfig cruiseConfig = new BasicCruiseConfig();
        ValidationContext context = ConfigSaveValidationContext.forChain(cruiseConfig);
        assertThat(context.getAllMaterialsByFingerPrint("something").isEmpty(), is(true));
    }

    @Test
    public void shouldGetPipelineConfigByName(){
        BasicCruiseConfig cruiseConfig = GoConfigMother.configWithPipelines("p1");
        ValidationContext context = ConfigSaveValidationContext.forChain(cruiseConfig);
        assertThat(context.getPipelineConfigByName(new CaseInsensitiveString("p1")), is(cruiseConfig.allPipelines().get(0)));
        assertThat(context.getPipelineConfigByName(new CaseInsensitiveString("does_not_exist")), is(nullValue()));
    }

    @Test
    public void shouldGetServerSecurityConfig(){
        BasicCruiseConfig cruiseConfig = GoConfigMother.configWithPipelines("p1");
        GoConfigMother.enableSecurityWithPasswordFile(cruiseConfig);
        ValidationContext context = ConfigSaveValidationContext.forChain(cruiseConfig);
        assertThat(context.getServerSecurityConfig(), is(cruiseConfig.server().security()));
    }
}