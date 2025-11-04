pipeline {
  agent any

  environment {
    IMAGE_NAME   = "skillforge"
    IMAGE_TAG    = "latest"
    TF_DIR       = "terraform"
    SONAR_PROJECT_KEY = "skillforge"
    SONARQUBE_ENV     = "sonarqube-server"
    AWS_REGION   = "ap-south-1"
  }

  stages {

    stage('Checkout') {
      steps {
        echo "Cloning repository..."
        git branch: 'main', url: 'https://github.com/sujatrodas96/SkillForge.git'
      }
    }


    stage('SonarQube Analysis') {
        agent {
            docker { image 'sonarsource/sonar-scanner-cli:latest' }
        }
        steps {
            withSonarQubeEnv("${SONARQUBE_ENV}") {
            withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]) {
                sh '''
                sonar-scanner \
                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                    -Dsonar.sources=. \
                    -Dsonar.host.url=$SONAR_HOST_URL \
                    -Dsonar.login=$SONAR_TOKEN
                '''
            }
            }
        }
    }


    stage('Quality Gate') {
      steps {
        timeout(time: 2, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        echo "Building Docker image..."
        sh '''
          cat > Dockerfile <<'DOCKERFILE'
          FROM ubuntu:22.04
          ENV DEBIAN_FRONTEND=noninteractive
          RUN apt update && apt install -y nginx && apt clean
          WORKDIR /var/www/html
          COPY . /var/www/html
          EXPOSE 80
          CMD ["nginx", "-g", "daemon off;"]
          DOCKERFILE
        '''
        sh '''
          docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
        '''
      }
    }

    stage('Push to DockerHub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-cred', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker tag ${IMAGE_NAME}:${IMAGE_TAG} "$DOCKER_USER/${IMAGE_NAME}:${IMAGE_TAG}"
            docker push "$DOCKER_USER/${IMAGE_NAME}:${IMAGE_TAG}"
            docker logout
          '''
        }
      }
    }

    stage('Terraform Apply (Provision EC2)') {
      steps {
        dir("${TF_DIR}") {
          withCredentials([
            string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY'),
            string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_KEY'),
            string(credentialsId: 'AWS_KEY_NAME', variable: 'AWS_KEY_NAME')
          ]) {
            sh '''
              export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY}"
              export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_KEY}"

              terraform init -input=false
              terraform apply -auto-approve \
                -var "aws_access_key=${AWS_ACCESS_KEY}" \
                -var "aws_secret_key=${AWS_SECRET_KEY}" \
                -var "key_name=${AWS_KEY_NAME}" \
                -var "aws_region=${AWS_REGION}"
            '''
          }
        }
      }
    }

    stage('Deploy Container to EC2') {
      steps {
        withCredentials([
          sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
          usernamePassword(credentialsId: 'dockerhub-cred', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')
        ]) {
          sh '''
            EC2_HOST=$(cd terraform && terraform output -raw public_ip)
            echo "Deploying container to EC2 host: $EC2_HOST"
            chmod 600 "$SSH_KEY"

            ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$SSH_USER"@"${EC2_HOST}" "
              sudo systemctl start docker
              echo '$DOCKER_PASS' | docker login -u '$DOCKER_USER' --password-stdin
              docker stop skillforge 2>/dev/null || true
              docker rm skillforge 2>/dev/null || true
              docker pull '$DOCKER_USER/${IMAGE_NAME}:${IMAGE_TAG}'
              docker run -d -p 80:80 --name skillforge --restart unless-stopped '$DOCKER_USER/${IMAGE_NAME}:${IMAGE_TAG}'
              docker logout
            "
          '''
        }
      }
    }
  }

  post {
    always {
      echo 'Cleaning up temporary Docker sessions...'
      sh 'docker logout 2>/dev/null || true'
    }
    success {
      echo 'Deployment successful! App is live on EC2.'
    }
    failure {
      echo 'Pipeline failed. Check the logs above for details.'
    }
  }
}
