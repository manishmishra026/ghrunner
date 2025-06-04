$RESOURCE_GROUP="mmrg"
$LOCATION="centralindia"
$ENVIRONMENT="managedEnvironment-mmrg-90af"
$JOB_NAME="github-actions-runner-job-v2"


$GITHUB_PAT=""
$REPO_OWNER="manishmishra026"
$REPO_NAME="DotNetCoreSqlDb"

$CONTAINER_IMAGE_NAME="github-actions-runner:2.0"
$CONTAINER_REGISTRY_NAME="mmazacr0001"

az acr build `
    --registry "$CONTAINER_REGISTRY_NAME" `
    --image "$CONTAINER_IMAGE_NAME" `
    --file "Dockerfile.github" `
    "./github-actions-runner"


$IDENTITY="mmuai0001"

az identity create `
    --name $IDENTITY `
    --resource-group $RESOURCE_GROUP

$IDENTITY_ID=$(az identity show `
    --name $IDENTITY `
    --resource-group $RESOURCE_GROUP `
    --query id `
    --output tsv)

az containerapp job create --name "$JOB_NAME" --resource-group "$RESOURCE_GROUP" --environment "$ENVIRONMENT" --trigger-type Event --replica-timeout 1800 --replica-retry-limit 0 --replica-completion-count 1 --parallelism 1 --image "$CONTAINER_REGISTRY_NAME.azurecr.io/$CONTAINER_IMAGE_NAME" --min-executions 0 --max-executions 10 --polling-interval 30 --scale-rule-name "github-runner-v2" --scale-rule-type "github-runner" --scale-rule-metadata "githubAPIURL=https://api.github.com" "owner=$REPO_OWNER" "runnerScope=repo" "repos=$REPO_NAME" "targetWorkflowQueueLength=1" --scale-rule-auth "personalAccessToken=personal-access-token" --cpu "2.0" --memory "4Gi" --secrets "personal-access-token=$GITHUB_PAT" --env-vars "GITHUB_PAT=secretref:personal-access-token" "GH_URL=https://github.com/$REPO_OWNER/$REPO_NAME" "REGISTRATION_TOKEN_API_URL=https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runners/registration-token" --registry-server "$CONTAINER_REGISTRY_NAME.azurecr.io" --mi-user-assigned "$IDENTITY_ID" --registry-identity "$IDENTITY_ID"