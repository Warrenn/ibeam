aws ecr-public get-login-password --region us-east-1 --profile busyweb-admin-role | docker login --username AWS --password-stdin public.ecr.aws/x9x1s8n0
docker build -t busyweb/ibeam:latest .
docker tag busyweb/ibeam:latest public.ecr.aws/x9x1s8n0/busyweb/ibeam:latest
#docker push public.ecr.aws/x9x1s8n0/busyweb/ibeam:latest