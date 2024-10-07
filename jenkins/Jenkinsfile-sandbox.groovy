//def label = "worker-${UUID.randomUUID().toString()}"

podTemplate(
    inheritFrom: 'default',
    //label: label,
    containers: [
        containerTemplate(name: 'gradle', image: 'gradle:latest', command: 'cat', ttyEnabled: true)
    ]
) {
    node(POD_LABEL) {
        // def myRepo = checkout scm
        // def gitCommit = myRepo.GIT_COMMIT
        // def gitBranch = myRepo.GIT_BRANCH
        // def shortGitCommit = "${gitCommit[0..10]}"
        // def previousGitCommit = sh(script: "git rev-parse ${gitCommit}~", returnStdout: true)

        stage('Install Build Tools') {
        withKubeConfig([
            credentialsId: 'minikube-jenkins-robot-secret',
            namespace: "default",
            contextName: 'minikube',
            clusterName: 'minikube'
            ]) {
                //sh 'ls /var/run/secrets/kubernetes.io/serviceaccount'
                //sh 'cat /var/run/secrets/kubernetes.io/serviceaccount/token'
                //sh 'env | grep KUBE'
                //sh 'which curl'
                //sh 'curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.29.2/bin/linux/amd64/kubectl"'
                sh 'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"'
                // https://github.com/helm/helm/releases
                sh 'curl -LO "https://get.helm.sh/helm-v3.16.1-linux-amd64.tar.gz"'
                sh 'tar -xvzf helm-v3.16.1-linux-amd64.tar.gz'
                sh 'chmod 700 linux-amd64/helm kubectl'
                sh '''
                    #K8S=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT
                    #TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
                    #CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
                    NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
                    #curl -H "Authorization: Bearer $TOKEN" --cacert $CACERT $K8S/healthz
                    #curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" --cacert $CACERT $K8S/api/v1/namespaces/$NAMESPACE/services/kubernetes
                    #./kubectl version --client --output=yaml
                    ./kubectl config set-context --current --namespace=$NAMESPACE
                    ./kubectl get pods
                    ls -la linux-amd64/helm
                    #./linux-amd64/helm version'
                '''
            }
        }
        stage('Checkout') {
                withKubeConfig([
            credentialsId: 'minikube-jenkins-robot-secret',
            namespace: "default",
            contextName: 'minikube',
            clusterName: 'minikube'
            ]) {
                git branch: 'dora-poc', url: 'https://github.com/andrebrowne/spring-petclinic.git'
            }
        }
        stage('Build') {
                withKubeConfig([
                    credentialsId: 'minikube-jenkins-robot-secret',
                    namespace: "default",
                    contextName: 'minikube',
                    clusterName: 'minikube'
                ]) {
                    container('gradle') {
                        sh 'gradle build -x test'
                    }
            }
        }
        stage('Deployment Trigger') {
            input "Trigger deployment?"
        }
        stage('Deploy') {
            echo 'Deploying'
        }
    }
    // post {
    //     always {
    //         junit '**/build/test-results/test/*.xml'
    //         // Configure Jacoco for code coverage
    //         jacoco execPattern: '**/build/jacoco/*.exec'

    //         // Clean up workspace
    //         cleanWs
    //     }
    //     success {
    //         archiveArtifacts artifacts:'**/build/libs/*.jar', onlyIfSuccessful: true
    //         // Notify on success
    //         echo 'Build successful!'
    //     }
    //     unstable {
    //         // Notify on unstable build
    //         echo 'Build unstable.'
    //     }
    //     failure {
    //         // Notify on failure
    //         echo 'Build failed!'
    //     }
    // }
}
