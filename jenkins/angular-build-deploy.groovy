node {
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
        stage('Checkout') {
            git url: 'https://github.com/terragon-social-club/infrastructure'     
        }

        stage('NPM Install') {
            sh 'npm install'
        }
        
        stage('NPM Build') {
            sh 'npm run build'
        }
        
        stage('Publish') {
            withCredentials([
                string(credentialsId: 'digitalocean_spaces_secret_key', variable: 'DO_SP_SC'),
                string(credentialsId: 'digitalocean_spaces_access_id', variable: 'DO_SP_ID')
            ]) {
                sh "AWS_DEFAULT_REGION=NYC3 AWS_ACCESS_KEY_ID=${DO_SP_ID} AWS_SECRET_ACCESS_KEY=${DO_SP_SC} aws s3 sync dist/terragon s3://www-terragon-us/ --endpoint-url https://nyc3.digitaloceanspaces.com --acl public-read"

                cleanWs()
            }
            
        }
        
    }

}
