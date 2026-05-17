// ─────────────────────────────────────────────────────────────
//  Jenkinsfile  — Terraform VPC deployment pipeline
//
//  Stages:
//    1. Checkout        — pull repo
//    2. Terraform Init  — configure S3 backend
//    3. Format Check    — fail fast on unformatted code
//    4. Validate        — syntax check
//    5. Plan            — generate + archive plan file
//    6. Approval        — manual gate (prod only)
//    7. Apply           — deploy from saved plan
//    8. Notify          — Slack / email on success or failure
// ─────────────────────────────────────────────────────────────

pipeline {

    agent any


    // ── Pipeline-wide parameters ───────────────────────────
    parameters {
        choice(
            name:         'ENVIRONMENT',
            choices:      ['prod', 'staging', 'dev'],
            description:  'Target environment'
        )
        booleanParam(
            name:         'DESTROY',
            defaultValue: false,
            description:  'Check to run terraform destroy instead of apply'
        )
    }

    // ── Environment / credentials ──────────────────────────
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_IN_AUTOMATION   = 'true'        // suppresses interactive prompts
        TF_VAR_FILE        = "environments/${params.ENVIRONMENT}/terraform.tfvars"
        PLAN_FILE          = "tfplan-${params.ENVIRONMENT}-${env.BUILD_NUMBER}"

        // Credentials stored in Jenkins credential store
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    }

    options {
                      // colourised terraform output
        timestamps()
        timeout(time: 60, unit: 'MINUTES')
        disableConcurrentBuilds()       // prevent parallel state mutations
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        // ── 1. Checkout ────────────────────────────────────
        stage('Checkout') {
            steps {
                checkout scm
                sh 'terraform --version'
                sh 'aws --version'
                echo "Deploying to: ${params.ENVIRONMENT} | Build: ${env.BUILD_NUMBER}"
            }
        }

        // ── 2. Terraform Init ──────────────────────────────
        stage('Terraform Init') {
            steps {
                sh '''
                    terraform init \
                      -reconfigure \
                      -backend-config="key=${ENVIRONMENT}/vpc/terraform.tfstate" \
                      -input=false
                '''
            }
        }

        // ── 3. Format Check ────────────────────────────────
        stage('Format Check') {
            steps {
                sh 'terraform fmt -check -recursive'
            }
        }

        // ── 4. Validate ────────────────────────────────────
        stage('Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        // ── 5. Plan ────────────────────────────────────────
        stage('Plan') {
            steps {
                script {
                    def planCmd = params.DESTROY
                        ? "terraform plan -destroy -var-file=${TF_VAR_FILE} -out=${PLAN_FILE} -input=false"
                        : "terraform plan -var-file=${TF_VAR_FILE} -out=${PLAN_FILE} -input=false"

                    sh planCmd

                    // Save human-readable plan as an artifact
                    sh "terraform show -no-color ${PLAN_FILE} > plan-${PLAN_FILE}.txt"
                    archiveArtifacts artifacts: "plan-${PLAN_FILE}.txt"
                }
            }
            post {
                always {
                    // Stash plan file so the apply stage can pick it up even
                    // after a Jenkins node restart during the approval window
                    stash name: 'tfplan', includes: "${PLAN_FILE}"
                }
            }
        }

        // ── 6. Manual Approval ─────────────────────────────
        stage('Approval') {
            // Only require manual approval for prod; staging/dev auto-proceed
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            steps {
                script {
                    def action = params.DESTROY ? 'DESTROY' : 'APPLY'
                    def msg    = """
Terraform ${action} is waiting for approval.
Environment : ${params.ENVIRONMENT}
Branch      : ${env.GIT_BRANCH}
Build       : ${env.BUILD_URL}
Review plan : ${env.BUILD_URL}artifact/plan-${PLAN_FILE}.txt
                    """.trim()

                    // Post to Slack before the human gate
                    echo "Approval needed: ${msg}"

                    timeout(time: 30, unit: 'MINUTES') {
                        input(
                            message: "Apply Terraform ${action} to PROD?",
                            submitter: 'devops-team,infra-lead',   // Jenkins user IDs
                            ok: "Yes, ${action}!"
                        )
                    }
                }
            }
        }

        // ── 7. Apply ───────────────────────────────────────
        stage('Apply') {
            steps {
                unstash 'tfplan'
                sh "terraform apply -input=false -auto-approve ${PLAN_FILE}"
            }
            post {
                success {
                    sh 'terraform output -json > tf-outputs.json'
                    archiveArtifacts artifacts: 'tf-outputs.json'
                }
            }
        }
    }

// ── Post-pipeline notifications ────────────────────────
    post {
        success {
            echo "✅ Pipeline succeeded for environment: ${params.ENVIRONMENT}"
        }
        failure {
            echo "❌ Pipeline failed for environment: ${params.ENVIRONMENT}"
        }
        always {
            echo "Pipeline finished - Build #${env.BUILD_NUMBER}"
        }
    }
}
