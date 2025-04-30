pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'
        IMAGE_NAME = 'ramachandrampm/medicure-app'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "${DOCKERHUB_CREDENTIALS}") {
                        sh """
                            docker build -t ${IMAGE_NAME}:latest .
                            docker push ${IMAGE_NAME}:latest
                        """
                    }
                }
            }
        }

        stage('Provision Infrastructure with Terraform') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        cd terraform
                        terraform init
                        terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Get Terraform Output (EC2 IP)') {
            steps {
                script {
                    env.EC2_IP = sh(script: "cd terraform && terraform output -raw ec2_public_ip", returnStdout: true).trim()
                }
            }
        }

        stage('Initialize Kubernetes with Ansible') {
            steps {
                script {
                    writeFile file: 'inventory.ini', text: "[medicure_servers]\n${env.EC2_IP} ansible_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/jjk.pem"
                }
                sh '''
                    echo "⏳ Waiting for EC2 SSH to be ready..."
                    sleep 40
                    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini setup-medicure.yml
                '''
            }
        }
        
        stage('Deploy Application to Kubernetes') {
            steps {
                sh """
                echo "📦 Copying Kubernetes manifests to EC2 instance..."
                scp -i /var/lib/jenkins/jjk.pem -o StrictHostKeyChecking=no k8s/deployment.yaml k8s/service.yaml ubuntu@${EC2_IP}:/home/ubuntu/
        
                echo "⏳ Waiting for Kubernetes API server to become ready..."
                ssh -i /var/lib/jenkins/jjk.pem -o StrictHostKeyChecking=no ubuntu@${EC2_IP} '
                  export KUBECONFIG=\$HOME/.kube/config
                  for i in {1..30}; do
                    kubectl get nodes && break || sleep 10
                  done
                  kubectl apply --validate=false -f deployment.yaml
                  kubectl apply --validate=false -f service.yaml
                '
                """
            }
        }

        stage('Wait for App to Start') {
            steps {
                sh 'sleep 30'
            }
        }



    }

    post {
        success {
            echo '✅ Medicure pipeline complete!'
        }
        failure {
            echo '❌ Something went wrong!'
        }
    }
}
