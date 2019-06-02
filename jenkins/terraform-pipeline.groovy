node {
    stage 'Checkout'
    git credentialsId: 'mkeen', url: 'https://github.com/terragon-social-club/infrastructure'
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
        // Mark the code build 'plan'....
        withCredentials([string(credentialsId: 'digitalocean_api_secret', variable: 'DO_API')]) {
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
            sh "cd terraform; TF_VAR_digitalocean_api_token=$DO_API terraform refresh"
            sh "cd terraform; set +e; TF_VAR_digitalocean_api_token=$DO_API terraform plan -out=/tmp/plan.out -detailed-exitcode; echo \$? > status"
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
                    def planDraft = readFile('/tmp/plan.out').trim()
                    input message: "Apply Plan? $planDraft", ok: 'Apply'
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
                
                sh "cd terraform; set +e; terraform apply ../plan.out; echo \$? > status.apply"
                def applyExitCode = readFile('terraform/status.apply').trim()
                if (applyExitCode == "0") {
                    withCredentials([usernamePassword(credentialsId: 'mkeen', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                        sh('cd terraform; git commit -a -m "A pleasure, sir. -- Jenkins"; git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/terragon-social-club/infrastructure')
                    }
                    
                } else {
                    currentBuild.result = 'FAILURE'
                }
                
            }
            
        }
        
    }
    
}
