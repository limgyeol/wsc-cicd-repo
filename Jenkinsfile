pipeline {
  agent any
  environment {
    AWS_REGION = 'ap-northeast-2'
    ACCOUNT_ID = '637423625226'
    ECR_REPO   = 'wsc-cicd-ecr'
    REGISTRY   = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    CLUSTER    = 'wsc-cicd-ecs-cluster'
    SERVICE    = 'wsc-cicd-ecs-svc'
    TASKDEF    = 'wsc-cicd-ecs-taskdef'
    CONTAINER  = 'wsc-cicd-ecs-cnt'
  }
  stages {
    stage('Next Tag') {
      steps {
        script {
          def last = sh(returnStdout: true, script: """
            aws ecr describe-images --repository-name ${ECR_REPO} --region ${AWS_REGION} \
              --query 'imageDetails[].imageTags[]' --output text 2>/dev/null \
            | tr '\\t' '\\n' | grep -E '^v[0-9]+\\.[0-9]+\\.[0-9]+\$' | sort -V | tail -1
          """).trim()
          if (!last) {
            env.IMAGE_TAG = 'v1.0.0'
          } else {
            def p = last.replace('v','').tokenize('.')
            env.IMAGE_TAG = "v${p[0]}.${p[1]}.${(p[2] as int) + 1}"
          }
          echo "Next tag: ${env.IMAGE_TAG}"
        }
      }
    }
    stage('Build & Push') {
      steps {
        sh """
          aws ecr get-login-password --region ${AWS_REGION} \
            | docker login --username AWS --password-stdin ${REGISTRY}
          docker build -t ${REGISTRY}/${ECR_REPO}:${IMAGE_TAG} .
          docker push ${REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
        """
      }
    }
    stage('Deploy ECS') {
      steps {
        sh """
          aws ecs describe-task-definition --task-definition ${TASKDEF} --region ${AWS_REGION} \
            --query 'taskDefinition' > td.json
          jq --arg IMG "${REGISTRY}/${ECR_REPO}:${IMAGE_TAG}" --arg CN "${CONTAINER}" '
            .containerDefinitions |= map(if .name == \$CN then .image = \$IMG else . end)
            | del(.taskDefinitionArn, .revision, .status, .requiresAttributes,
                  .compatibilities, .registeredAt, .registeredBy)
          ' td.json > new-td.json
          NEW_TD=\$(aws ecs register-task-definition --region ${AWS_REGION} \
            --cli-input-json file://new-td.json \
            --query 'taskDefinition.taskDefinitionArn' --output text)
          aws ecs update-service --region ${AWS_REGION} \
            --cluster ${CLUSTER} --service ${SERVICE} --task-definition \$NEW_TD
        """
      }
    }
  }
  post {
    always { sh 'docker image prune -f || true' }
  }
}
