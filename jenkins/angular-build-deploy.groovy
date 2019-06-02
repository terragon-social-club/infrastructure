node {
    stage 'Checkout'
    git credentialsId: 'mkeen', url: 'https://github.com/terragon-social-club/terragon'
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
        stage name: 'NPM Install', concurrency: 1
        def exitCodeInstall = sh 'npm install', returnStatus: true
        if(exitCodeInstall != '0') {
            currentBuild.result = 'FAILURE'
        } else {
            stage name: 'NPM Build', concurrency: 1
            def exitCodeBuild = sh 'npm build', returnStatus: true

            if(exitCodeBuild != '0') {
                currentBuild.result = 'FAILURE'
            } else {
                withCredentials([
                    string(credentialsId: 'digitalocean_spaces_secret_key', variable: 'DO_SP_SC'),
                    string(credentialsId: 'digitalocean_spaces_access_id', variable: 'DO_SP_ID')
                ]) {
                    def exitCodeSpacesUpload = sh "aws s3 sync dist s3://www-terragon-us/", returnStatus: true
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
