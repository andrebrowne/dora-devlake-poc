podTemplate(
        inheritFrom: 'default',
        containers: [
                containerTemplate(name: 'docker', image: 'docker', command: 'cat', ttyEnabled: true),
                containerTemplate(name: 'gradle', image: 'gradle:latest', command: 'cat', ttyEnabled: true)
        ],
        volumes: [
                hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
        ]
) {
    node(POD_LABEL) {
        stage('Install Build Tools') {
            withKubeConfig([credentialsId: 'minikube-jenkins-robot-secret']) {
                // See https://github.com/helm/helm/releases for latest release
                sh 'curl -sLO "https://get.helm.sh/helm-v3.16.1-linux-amd64.tar.gz"'
                sh 'curl -sLO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"'
                sh 'tar -xvzf helm-v3.16.1-linux-amd64.tar.gz'
                sh 'chmod 700 linux-amd64/helm kubectl'
                sh '''
                    ./kubectl config set-context --current --namespace=default
                    ./kubectl get pods
                    ./linux-amd64/helm version'
                   '''
            }
        }
        stage('Checkout') {
            git branch: 'dora-poc', url: 'https://github.com/andrebrowne/spring-petclinic.git'
        }
        stage('Build') {
            container('gradle') {
                sh 'gradle build -x test'
            }
        }
        stage('Create Docker Image') {
            container('docker') {
                sh 'docker -version'
            }
        }
        // stage('Deployment Trigger') {
        //     input "Trigger deployment?"
        // }
        stage('Deploy') {
            echo 'Deploying'
            withKubeConfig([credentialsId: 'minikube-jenkins-robot-secret']) {
                sh '''
                    ./kubectl config set-context --current --namespace=default
                   ./linux-amd64/helm upgrade --debug --install --force dora-poc-app dora-poc-app
                   '''
            }
        }
    }
}
