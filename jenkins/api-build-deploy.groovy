node {
    git credentialsId: 'github_deploy_api', url: 'git@github.com:terragon-social-club/api.git'
    
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
        withCredentials([
            string(credentialsId: 'npm_token', variable: 'N_TOKEN')
        ]) {    
            stage name: 'NPM Install', concurrency: 1
            sh 'npm install'
        
            stage name: 'NPM Build', concurrency: 1
            sh 'npm run build-ts'
            
            stage name: 'Publish', concurrency: 1
            sh 'git add . && git commit -m "Jolly good."'
            sh 'npm version patch --no-git-tag-version'
            sh "echo //registry.npmjs.org/:_authToken=$N_TOKEN > .npmrc"
            sh 'npm publish'
            sh 'rm .npmrc'
            sh 'git add . && git commit -m "Jolly good."'
            sh 'GIT_SSH_COMMAND="ssh -i ~/id_rsa_deploy_api" git push -v origin master'
            
            cleanWs()
        }
        
    }

}
