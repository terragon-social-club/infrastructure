node {
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
        git credentialsId: 'github_deploy_api', url: 'git@github.com:terragon-social-club/infrastructure.git'
        
        stage('Checkout') {
            cleanWs()
            git url: 'https://github.com/terragon-social-club/api'     
        }

        stage('NPM Install') {
            sh 'npm install'
        }
        
        stage('NPM Build') {
            sh 'npm run build-ts'
        }
        
        stage('Publish') {
            withCredentials([
                string(credentialsId: 'npm_token', variable: 'N_TOKEN')
            ]) {
                sh 'git add . && git commit -m "Jolly good."'
                sh "npm version patch"
                sh "NPM_TOKEN=$N_TOKEN npm publish"
                sh 'git push origin master'
                cleanWs()
            }
            
        }
        
    }

}
