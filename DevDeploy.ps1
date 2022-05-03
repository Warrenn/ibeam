param (
    [String]
    $EnvName = "dev",
    [String]
    $AwsProfile = "busyweb-admin-role",
    [String]
    $Region = "af-south-1"
)

$ECR_REGISTRY = "public.ecr.aws/x9x1s8n0"
$ECR_REPO = "busyweb/ibeam"
$IBEAM_INPUTS_DIR = "/srv/inputs"
$IBEAM_OUTPUTS_DIR = "/srv/outputs"
$IBEAM_RESULTS_DIR = "/srv/results"
$IBEAM_RESULTS_FILENAME = "results.json"

$IBEAM_ACCOUNT=$(ConvertFrom-Json([string]::Join("", $(aws ssm get-parameter --name /$EnvName/auto-invest/ibeam_account --with-decryption --region $Region --profile $AwsProfile)))).Parameter.Value
$IBEAM_PASSWORD=$(ConvertFrom-Json([string]::Join("", $(aws ssm get-parameter --name /$EnvName/auto-invest/ibeam_password --with-decryption --region $Region --profile $AwsProfile)))).Parameter.Value

$RootFolder = "/" + $PSScriptRoot.Replace(":", "").Replace("\", "/").ToLower()

#$images=$(docker ps);$imageid=$images[1].Split(' ')[0];docker kill $imageid
aws ecr-public get-login-password --region $Region --profile $AwsProfile | docker login --username AWS --password-stdin public.ecr.aws/x9x1s8n0
docker pull "${ECR_REGISTRY}/${ECR_REPO}:latest"
docker run `
    --env IBEAM_ACCOUNT="${IBEAM_ACCOUNT}" `
    --env IBEAM_PASSWORD="${IBEAM_PASSWORD}" `
    --env IBEAM_OUTPUTS_DIR="${IBEAM_OUTPUTS_DIR}" `
    --env IBEAM_INPUTS_DIR="${IBEAM_INPUTS_DIR}" `
    --env IBEAM_RESULTS_PATH="${IBEAM_RESULTS_DIR}\${IBEAM_RESULTS_FILENAME}" `
    -v "${RootFolder}/outputs:${IBEAM_OUTPUTS_DIR}" `
    -v "${RootFolder}/copy_cache/root:${IBEAM_INPUTS_DIR}" `
    -v "${RootFolder}/results:${IBEAM_RESULTS_DIR}" `
    -p 5000:5000 "${ECR_REGISTRY}/${ECR_REPO}:latest"
