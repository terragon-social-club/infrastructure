node {
    stage('Checkout') {
        git credentialsId: 'mkeen', url: 'https://github.com/terragon-social-club/terragon'
        wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
            stage('NPM Install') {
                def exitCodeInstall = sh script: 'npm install', returnStatus: true
                if(exitCodeInstall != '0') {
                    currentBuild.result = 'FAILURE'
                }
                
            }

             stage('NPM Build') {
                def exitCodeBuild = sh script: 'npm run build', returnStatus: true
                
                if(exitCodeBuild != '0') {
                    currentBuild.result = 'FAILURE'
                } 
                
            }

            stage('Publish') {
                withCredentials([
                    string(credentialsId: 'digitalocean_spaces_secret_key', variable: 'DO_SP_SC'),
                    string(credentialsId: 'digitalocean_spaces_access_id', variable: 'DO_SP_ID')
                ]) {
                    def exitCodeSpacesUpload = sh script: "AWS_DEFAULT_REGION=NYC3 AWS_ACCESS_KEY_ID=${DO_SP_ID} AWS_SECRET_ACCESS_KEY=${DO_SP_SC} aws s3 sync dist/terragon s3://www-terragon-us/ --endpoint-url https://nyc3.digitaloceanspaces.com", returnStatus: true
                    if(exitCodeSpacesUpload != '0') {
                        // Need to roll back
                        currentBuild.result = 'FAILURE'
                    } else {
                        currentBuild.result = 'SUCCESS'
                    }
                    
                }
                
            }
            
        }
        
    }

}
