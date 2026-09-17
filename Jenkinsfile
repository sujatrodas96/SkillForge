pipeline {

    agent any

    environment {

        // Change this
        DOCKER_IMAGE = 'sujatro123/skillforge'

        // Jenkins automatically provides BUILD_NUMBER
        IMAGE_TAG = "${BUILD_NUMBER}"

        K8S_NAMESPACE = 'skillforge'
        K8S_DEPLOYMENT = 'skillforge'
        K8S_CONTAINER = 'skillforge'
    }

    stages {

        /*
         * 1. CHECKOUT
         */
        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub...'

                checkout scm
            }
        }


        /*
         * 2. VALIDATE PROJECT
         */
        stage('Validate Project') {
            steps {
                sh '''
                    echo "======================================"
                    echo "Checking project structure"
                    echo "======================================"

                    pwd

                    echo ""
                    echo "Files in workspace:"
                    ls -la

                    echo ""
                    echo "Checking Dockerfile..."
                    test -f Dockerfile

                    echo ""
                    echo "Checking index.html..."
                    test -f index.html

                    echo ""
                    echo "Project validation successful."
                '''
            }
        }


        /*
         * 3. DOCKER BUILD
         */
        stage('Docker Build') {
            steps {

                echo "Building Docker image..."

                sh '''
                    docker build \
                    -t ${DOCKER_IMAGE}:${IMAGE_TAG} \
                    -t ${DOCKER_IMAGE}:latest \
                    .
                '''

                echo "Docker image created:"
                echo "${DOCKER_IMAGE}:${IMAGE_TAG}"
            }
        }


        /*
         * 4. DOCKER LOGIN + PUSH
         */
        stage('Docker Push') {
            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {

                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login \
                            -u "$DOCKER_USERNAME" \
                            --password-stdin

                        docker push ${DOCKER_IMAGE}:${IMAGE_TAG}

                        docker push ${DOCKER_IMAGE}:latest

                        docker logout
                    '''
                }
            }
        }


        /*
         * 5. CREATE KUBERNETES NAMESPACE
         */
        stage('Kubernetes Namespace') {
            steps {

                sh '''
                    kubectl create namespace ${K8S_NAMESPACE} \
                    --dry-run=client \
                    -o yaml | kubectl apply -f -
                '''
            }
        }


        /*
         * 6. DEPLOY TO KUBERNETES
         */
        stage('Deploy to Kubernetes') {
            steps {

                echo "Deploying application to Kubernetes..."

                sh '''
                    kubectl apply \
                        -f k8s/deployment.yaml \
                        -n ${K8S_NAMESPACE}

                    kubectl apply \
                        -f k8s/service.yaml \
                        -n ${K8S_NAMESPACE}
                '''
            }
        }


        /*
         * 7. UPDATE IMAGE
         */
        stage('Update Kubernetes Image') {
            steps {

                sh '''
                    kubectl set image deployment/${K8S_DEPLOYMENT} \
                        ${K8S_CONTAINER}=${DOCKER_IMAGE}:${IMAGE_TAG} \
                        -n ${K8S_NAMESPACE}
                '''
            }
        }


        /*
         * 8. WAIT FOR ROLLOUT
         */
        stage('Wait for Deployment') {
            steps {

                sh '''
                    kubectl rollout status \
                        deployment/${K8S_DEPLOYMENT} \
                        -n ${K8S_NAMESPACE} \
                        --timeout=180s
                '''
            }
        }


        /*
         * 9. VERIFY
         */
        stage('Verify Deployment') {
            steps {

                sh '''
                    echo "=============================="
                    echo "DEPLOYMENT"
                    echo "=============================="

                    kubectl get deployment \
                        ${K8S_DEPLOYMENT} \
                        -n ${K8S_NAMESPACE}

                    echo ""
                    echo "=============================="
                    echo "PODS"
                    echo "=============================="

                    kubectl get pods \
                        -n ${K8S_NAMESPACE} \
                        -o wide

                    echo ""
                    echo "=============================="
                    echo "SERVICE"
                    echo "=============================="

                    kubectl get service \
                        skillforge-service \
                        -n ${K8S_NAMESPACE}

                    echo ""
                    echo "=============================="
                    echo "IMAGE"
                    echo "=============================="

                    kubectl get deployment \
                        ${K8S_DEPLOYMENT} \
                        -n ${K8S_NAMESPACE} \
                        -o jsonpath='{.spec.template.spec.containers[0].image}'

                    echo ""
                '''
            }
        }
    }


    /*
     * POST ACTIONS
     */
    post {

        success {
            echo '''
            ==========================================
              CI/CD PIPELINE SUCCESSFUL
            ==========================================
            Docker image built and pushed.
            Kubernetes deployment completed.
            Application is running.
            ==========================================
            '''
        }

        failure {
            echo '''
            ==========================================
              CI/CD PIPELINE FAILED
            ==========================================
            Check the failed stage and Jenkins logs.
            ==========================================
            '''
        }

        always {
            sh '''
                docker image prune -f || true
            '''
        }
    }
}