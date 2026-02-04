locals {
  image_tag_by_env = {
    dev = "latest-dev"
    prd = "latest-prd"
  }
}

resource "aws_batch_job_definition" "fargate_batch_job_definition" {

    for_each = {for fargate_batch_job_definition in var.fargate_jobs:  fargate_batch_job_definition.index => fargate_batch_job_definition}
    name = "${each.value.environment}-${var.pipeline_name}-${each.value.pipeline_script}-${replace(each.value.vcpu, ".", "")}-${each.value.memory}"

    tags = {
        Terraform   = true
        Owner       = var.owner
        Environment = each.value.environment
        Name        = "${var.pipeline_name}-${each.value.pipeline_script}"
    } 

    type = "container"

    platform_capabilities = [
        "FARGATE",
    ]

    container_properties = jsonencode({
        command = []

        environment = [
          {
            name  = "PIPELINE_SCRIPT"
            value = each.value.pipeline_script
          }
        ]

        image   = "${var.account_id}.dkr.ecr.eu-west-1.amazonaws.com/veb-data-pipelines-${var.pipeline_name}:${local.image_tag_by_env[each.value.environment]}" // we add veb-data-pipelines for legacy compatibility

        fargatePlatformConfiguration = {
            platformVersion = "LATEST"
        }

        networkConfiguration = {
            assignPublicIp = "DISABLED"
        }

        resourceRequirements = [
            {
                type  = "VCPU"
                value = each.value.vcpu
            },
            {
                type  = "MEMORY"
                value = each.value.memory
            }
        ]
        jobRoleArn = var.job_role_arn
        executionRoleArn = var.execution_role_arn 
        }
    )
}
