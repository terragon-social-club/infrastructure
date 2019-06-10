node {
    stage 'Checkout'
    git credentialsId: 'github_deploy_terraform', url: 'git@github.com:terragon-social-club/infrastructure.git'
    
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
        // Mark the code build 'plan'....
        withCredentials([
            string(credentialsId: 'digitalocean_api_secret', variable: 'DO_API'),
            string(credentialsId: 'digitalocean_spaces_secret_key', variable: 'DO_SPACES_SECRET'),
            string(credentialsId: 'digitalocean_spaces_access_id', variable: 'DO_SPACES_ACCESS')
        ]) {
            stage name: 'Plan', concurrency: 1
            // Output Terraform version
            sh "cd terraform; terraform --version"
            if (fileExists("terraform/status")) {
                sh "cd terraform; rm status"
            }
            
            sh 'git config --global user.email "jenkins@terragon.us"'
            sh 'git config --global user.name "Jenkins"'
            sh "cd terraform; terraform init"
            sh "cd terraform; terraform get"
            sh "cd terraform; TF_VAR_digitalocean_api_token=$DO_API TF_VAR_spaces_access_id=$DO_SPACES_ACCESS TF_VAR_spaces_secret_key=$DO_SPACES_SECRET terraform refresh"
            sh "cd terraform; set +e; TF_VAR_digitalocean_api_token=$DO_API TF_VAR_spaces_access_id=$DO_SPACES_ACCESS TF_VAR_spaces_secret_key=$DO_SPACES_SECRET terraform plan -out=/tmp/plan.out -detailed-exitcode; echo \$? > status"
            
            def exitCode = readFile('terraform/status').trim()
            def apply = false
            echo "Terraform Plan Exit Code: ${exitCode}"
            if (exitCode == "0") {
                currentBuild.result = 'SUCCESS'
            }
            
            if (exitCode == "1") {
                currentBuild.result = 'FAILURE'
            }
            
            if (exitCode == "2") {
                stash name: "plan", includes: "plan.out"
                try {
                    input message: "Apply Plan?", ok: 'Apply'
                    apply = true
                } catch (err) {
                    apply = false
                    currentBuild.result = 'UNSTABLE'
                }
            }
            
            if (apply) {
                stage name: 'Apply', concurrency: 1
                unstash 'plan'
                if (fileExists("terraform/status.apply")) {
                    sh "cd terraform; rm status.apply"
                }
                
                sh "cd terraform; set +e; TF_VAR_digitalocean_api_token=$DO_API TF_VAR_spaces_access_id=$DO_SPACES_ACCESS TF_VAR_spaces_secret_key=$DO_SPACES_SECRET terraform apply /tmp/plan.out; echo \$? > status.apply"
                def applyExitCode = readFile('terraform/status.apply').trim()
                if (applyExitCode == "0") {
                    sh 'cd terraform; rm status.apply; rm /tmp/plan.out'
                    sh 'cd terraform; git add . && git -m "A pleasure, sir. -- Jenkins"; git push origin master'
                    
                } else {
                    sh 'cd terraform; rm status.apply; rm /tmp/plan.out'
                    sh 'cd terraform; git add . && git -m "Something went wrong. -- Jenkins"; git push origin master'
                    
                    currentBuild.result = 'FAILURE'
                }
                
            }
            
        }
        
    }
    
}
