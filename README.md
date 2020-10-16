# Open Raven Helmfiles

## Testing your changes
More info to come on getting your dev flow setup e2e.

Big block of text for your edification for now:

From MD:

Run the pipeline pointed at your S3 bucket, something
like: https://gitlab.com/openraven/open/helm-charts/helmfiles/-/pipelines/new?ref=add-policy-service&var[HELM_S3_BUCKET]=openraven-deploy-YOURNAME
to make them available to cluster-upgrade (which presumably is pointed at your bucket,
or can be via kubectl set env deploy/cluster-upgrade OPENRAVEN_UPGRADES_NAME=openraven-deploy-YOURNAME) is the short answer
regrettably, chatops /gitlab helmfiles run publish-em openraven-deploy-YOURNAME only works on master, AFAIK :-(
I believe we have a small degree of influence over that, by having publish-em: accept a 2nd arg of the git ref, but the gitlab-ci would always be the one from master

the long answer is have a live kubeconfig and run

`cd helmfile.d && env GROUP_ID=... HELM_S3_BUCKET=openraven-deploy-YOURNAME OPENRAVEN_INGRESS_HOSTNAME=o00aeothutaoehute.org.openraven.net helmfile -f policy.yaml apply`

(the even longer version is that it's possible to build and index the charts using only your local directory, and then serve them with python3 -m http.server 9090 and set HELM_S3_URL=http://localhost:9090 to skip the S3 bucket process)
