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

        stage('Configure Server with Ansible') {
            steps {
                script {
                    writeFile file: 'inventory.ini', text: "[medicure_servers]\n${env.EC2_IP} ansible_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/jjk.pem"
                }
                sh 'ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini setup-medicure.yml'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    scp -i /var/lib/jenkins/jjk.pem -o StrictHostKeyChecking=no k8s/*.yaml ubuntu@${EC2_IP}:/home/ubuntu/
                    ssh -i /var/lib/jenkins/jjk.pem -o StrictHostKeyChecking=no ubuntu@${EC2_IP} 'kubectl apply -f deployment.yaml && kubectl apply -f service.yaml'
                """
            }
        }

        stage('Wait for App') {
            steps {
                sh 'sleep 30'
            }
        }

        stage('Test with Selenium') {
            steps {
                withEnv(["APP_URL=http://${EC2_IP}:30081"]) {
                    sh 'python3 selenium_test.py'
                }
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
