@Library("pipeline_library") _

pipeline {
    agent { label 'nft' }
    stages {
        stage('Run') {
            steps {
                script {
                    TestPipeline([
                        SERVICE_NAME: 'sandbox',
                        VARIABLES: ['ORG', 'TOKEN']
                    ])
                }
            }
        }
    }
}