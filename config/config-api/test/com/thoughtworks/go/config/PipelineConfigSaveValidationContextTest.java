package com.thoughtworks.go.config;

import com.thoughtworks.go.config.materials.MaterialConfigs;
import com.thoughtworks.go.domain.materials.MaterialConfig;
import com.thoughtworks.go.helper.GoConfigMother;
import com.thoughtworks.go.helper.MaterialConfigsMother;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.Is.is;
import static org.hamcrest.core.IsNull.nullValue;
import static org.junit.Assert.*;
import static org.mockito.Mockito.mock;

public class PipelineConfigSaveValidationContextTest {

    private PipelineConfig pipelineConfig;
    private PipelineConfigSaveValidationContext pipelineContext;

    @Before
    public void setUp() throws Exception {
        pipelineConfig = mock(PipelineConfig.class);
        pipelineContext = PipelineConfigSaveValidationContext.forChain(pipelineConfig);
    }

    @Test
    public void shouldCreatePipelineValidationContext() {
        assertThat(pipelineContext.getPipeline(), is(pipelineConfig));
        assertThat(pipelineContext.getStage(), is(nullValue()));
        assertThat(pipelineContext.getJob(), is(nullValue()));
    }

    @Test
    public void shouldCreateStageValidationContextBasedOnParent() {
        StageConfig stageConfig = mock(StageConfig.class);
        PipelineConfigSaveValidationContext stageContext = PipelineConfigSaveValidationContext.forChain(pipelineConfig, stageConfig);

        assertThat(stageContext.getPipeline(), is(pipelineConfig));
        assertThat(stageContext.getStage(), is(stageConfig));
        assertThat(stageContext.getJob(), is(nullValue()));
    }

    @Test
    public void shouldCreateJobValidationContextBasedOnParent() {
        StageConfig stageConfig = mock(StageConfig.class);
        JobConfig jobConfig = mock(JobConfig.class);
        PipelineConfigSaveValidationContext jobContext = PipelineConfigSaveValidationContext.forChain(pipelineConfig, stageConfig, jobConfig);
        assertThat(jobContext.getPipeline(), is(pipelineConfig));
        assertThat(jobContext.getStage(), is(stageConfig));
        assertThat(jobContext.getJob(), is(jobConfig));
    }

    @Test
    public void shouldGetAllMaterialsByFingerPrint() throws Exception {
        CruiseConfig cruiseConfig = new GoConfigMother().cruiseConfigWithPipelineUsingTwoMaterials();
        PipelineConfigurationCache.getInstance().onConfigChange(cruiseConfig);
        MaterialConfig expectedMaterial = MaterialConfigsMother.multipleMaterialConfigs().get(1);
        MaterialConfigs allMaterialsByFingerPrint = pipelineContext.getAllMaterialsByFingerPrint(expectedMaterial.getFingerprint());
        assertThat(allMaterialsByFingerPrint.size(), is(1));
        assertThat(allMaterialsByFingerPrint.first(), is(expectedMaterial));
    }

    @Test
    public void shouldGetParentDisplayName(){
        assertThat(PipelineConfigSaveValidationContext.forChain(new PipelineConfig()).getParentDisplayName(), is("pipeline"));
        assertThat(PipelineConfigSaveValidationContext.forChain(new PipelineConfig(), new StageConfig()).getParentDisplayName(), is("stage"));
        assertThat(PipelineConfigSaveValidationContext.forChain(new PipelineConfig(), new StageConfig(), new JobConfig()).getParentDisplayName(), is("job"));
    }

    @Test
    public void shouldFindPipelineByName(){
        BasicCruiseConfig cruiseConfig = GoConfigMother.configWithPipelines("p1");
        PipelineConfigurationCache.getInstance().onConfigChange(cruiseConfig);
        PipelineConfigSaveValidationContext context = PipelineConfigSaveValidationContext.forChain(new PipelineConfig());
        assertThat(context.getPipelineConfigByName(new CaseInsensitiveString("p1")), is(cruiseConfig.allPipelines().get(0)));
        assertThat(context.getPipelineConfigByName(new CaseInsensitiveString("does_not_exist")), is(nullValue()));
    }

    @Test
    public void shouldGetPipelineGroupForPipelineInContext(){
        String pipelineName = "p1";
        BasicCruiseConfig cruiseConfig = GoConfigMother.configWithPipelines(pipelineName);
        PipelineConfigurationCache.getInstance().onConfigChange(cruiseConfig);
        PipelineConfig p1 = cruiseConfig.pipelineConfigByName(new CaseInsensitiveString(pipelineName));
        PipelineConfigSaveValidationContext context = PipelineConfigSaveValidationContext.forChain(p1);
        assertThat(context.getPipelineGroup(), is(cruiseConfig.findGroupOfPipeline(p1)));
    }

    @Test
    public void shouldGetServerSecurityContext() {
        BasicCruiseConfig cruiseConfig = new BasicCruiseConfig();
        SecurityConfig securityConfig = new SecurityConfig();
        securityConfig.addRole(new Role(new CaseInsensitiveString("admin")));
        securityConfig.adminsConfig().add(new AdminUser(new CaseInsensitiveString("super-admin")));
        cruiseConfig.server().useSecurity(securityConfig);
        PipelineConfigurationCache.getInstance().onConfigChange(cruiseConfig);
        PipelineConfigSaveValidationContext context = PipelineConfigSaveValidationContext.forChain(new PipelineConfig());
        Assert.assertThat(context.getServerSecurityConfig(), is(securityConfig));
    }
}