pipeline {
    agent any

    environment {
        IMAGE_NAME       = "skillforge"
        IMAGE_TAG        = "latest"
        TF_DIR           = "terraform"
        AWS_REGION       = "us-east-1"
        PROMETHEUS_HOST  = "34.236.171.40"
        APP_EC2_KEY      = "ec2-ssh-key"
        DOCKER_CRED_ID   = "dockerhub-cred"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/sujatrodas96/SkillForge.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                  cat > Dockerfile <<EOF
                  FROM ubuntu:22.04
                  ENV DEBIAN_FRONTEND=noninteractive
                  RUN apt update && apt install -y nginx && apt clean
                  WORKDIR /var/www/html
                  RUN rm -rf /var/www/html/*
                  COPY . /var/www/html
                  EXPOSE 80
                  CMD ["nginx", "-g", "daemon off;"]
                  EOF

                  docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CRED_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
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
                        string(credentialsId: 'AWS_KEY_NAME', variable: 'AWS_KEY_NAME'),
                        usernamePassword(credentialsId: "${DOCKER_CRED_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')
                    ]) {
                        sh '''
                          export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY}"
                          export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_KEY}"

                          terraform init -input=false
                          terraform apply -auto-approve \
                            -var "aws_access_key=${AWS_ACCESS_KEY}" \
                            -var "aws_secret_key=${AWS_SECRET_KEY}" \
                            -var "key_pair_name=${AWS_KEY_NAME}" \
                            -var "aws_region=${AWS_REGION}" \
                            -var "docker_image=${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                        '''
                    }
                }
            }
        }

        stage('Deploy Docker Container to App EC2') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: "${APP_EC2_KEY}", keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
                    usernamePassword(credentialsId: "${DOCKER_CRED_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')
                ]) {
                    sh '''
                        APP_EC2=$(cd terraform && terraform output -raw public_ip)
                        chmod 600 "$SSH_KEY"

                        ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$SSH_USER@$APP_EC2" "
                          sudo systemctl start docker || true
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

        stage('Install Node Exporter on App EC2') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: "${APP_EC2_KEY}", keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                        APP_EC2=$(cd terraform && terraform output -raw public_ip)
                        chmod 600 "$SSH_KEY"

                        ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$SSH_USER@$APP_EC2" "
                          wget https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz -O node_exporter.tar.gz
                          tar xvf node_exporter.tar.gz
                          sudo mv node_exporter-1.10.2.linux-amd64/node_exporter /usr/local/bin/
                          
                          sudo bash -c 'cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=$SSH_USER
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EOF'

                          sudo systemctl daemon-reload
                          sudo systemctl enable node_exporter
                          sudo systemctl start node_exporter
                        "
                    '''
                }
            }
        }

        stage('Configure Prometheus Scrape Target') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: "${APP_EC2_KEY}", keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                        PROM_HOST=${PROMETHEUS_HOST}
                        chmod 600 "$SSH_KEY"

                        ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$SSH_USER@$PROM_HOST" "
                          sudo sed -i '/scrape_configs:/a \\  - job_name: \"app_ec2\"\\n    static_configs:\\n      - targets: [\\\"'$(cd terraform && terraform output -raw public_ip)':9100\\\"]' /etc/prometheus/prometheus.yml
                          sudo systemctl restart prometheus
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
            echo 'Deployment and monitoring setup successful! Grafana can now visualize metrics.'
        }
        failure {
            echo 'Pipeline failed. Check the logs above for details.'
        }
    }
}
