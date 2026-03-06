# Deployment through GitHub Actions workflows

> This guide is maintained for the `aztfmodnew/caf-terraform-landingzones-platform-starter` fork.

## Create a bootstrap token

The bootstrap token is only used during the initial steps to set up your Azure environment. Set an expiration date that is long enough to support bootstrap activities (recommended: 7 days to 1 month).

From your **GitHub profile**, go to **Settings** and select **Developer settings** at the bottom.

![gh profile](./github/gh_profile.png)
![gh developer settings](./github/gh_developersettings.png)

Select **Personal access tokens** and click **Generate new token**.

![gh new pat](./github/gh_bootstrap_token.png)

Set the expiration date to your desired value.

Select the following scopes:
- repo
- workflow

Scroll down and click **Generate token**.

Copy the value of the PAT token.

Go to your repository settings and, under **Secrets and variables**, select **Actions**.

Select **New repository secret**

Name the secret **BOOTSTRAP_TOKEN** and paste the value.

## Deployment from GitHub Codespaces

### Create a PAT token

From your **GitHub profile**, go to **Settings** and select **Developer settings** at the bottom.

![gh profile](./github/gh_profile.png)
![gh developer settings](./github/gh_developersettings.png)

Select **Personal access tokens** and click **Generate new token**.

![gh new pat](./github/gh_new_pat.png)

Set the expiration date to your desired value.

Select the following scopes:
- repo
- workflow
- read:public_key
- read:org

![gh scopes](./github/gh_scopes.png)

Scroll down and click **Generate token**.

Copy the value of the PAT token.

Go to your repository settings and, under **Secrets and variables**, select **Codespaces**.

Select **New repository secret**

Name the secret **GH_TOKEN** and paste the value.

![gh scopes](./github/gh_pat_repo.png)

If Codespaces was already started when you added `GH_TOKEN`, restart Codespaces so the secret is injected into the environment.

### Deploy from Codespaces

Once Codespaces has launched, log in to Azure.

```
rover login -t <tenant_name> -s <subscription_id>

```

The following command assumes you have Global Admin rights in the tenant and Owner privileges on the management subscription `<guid for management>`.

```
org_name=contoso

cd /tf/caf && rover -bootstrap \
	-aad-app-name ${org_name}-platform-landing-zones \
	-env ${org_name} \
	-gitops-pipelines github \
	-gitops-number-runners 5 \
	-bootstrap-script '/tf/caf/landingzones/templates/platform/deploy_platform.sh' \
	-playbook '/tf/caf/landingzones/templates/platform/caf_platform_prod_nonprod.yaml' \
	-subscription-deployment-mode multi_subscriptions \
	-sub-management <guid for management> \
	-sub-connectivity <guid for connectivity> \
	-sub-identity <guid for identity> \
	-sub-security <guid for security>

```

### Notes

- You can use either classic PATs or fine-grained PATs as long as required repository/workflow permissions are granted.
- Keep tokens short-lived and rotate them after bootstrap.
