# Deployment through GitHub Actions workflows

> This guide is maintained for the `aztfmodnew/caf-terraform-landingzones-platform-starter` fork.

## Authentication mode: OIDC (recommended) vs legacy_secret

CAF landing zones support three authentication modes for GitHub Actions CI/CD pipelines, configured via `auth_mode` in `ignite.yaml`:

| Mode | How it works | Secrets required in GitHub |
|------|-------------|---------------------------|
| `oidc` | Workload identity federation — no client secrets | `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, subscription secrets |
| `legacy_secret` | SP client secret stored in Azure Key Vault | Same + secret written to Key Vault at bootstrap |
| `hybrid` | OIDC login with optional Key Vault SP fallback | Same as `oidc`; uses Key Vault if bootstrap credentials exist |

**OIDC is the recommended approach** — it eliminates long-lived credentials and aligns with Azure and GitHub security best practices.

### Setting up OIDC (Workload Identity Federation)

After bootstrap creates the Azure AD application for your platform landing zone, add a federated credential to it:

1. Go to **Azure Portal → Entra ID → App registrations → `<org_name>-platform-landing-zones`**
2. Select **Certificates & secrets → Federated credentials → Add credential**
3. Choose **GitHub Actions deploying Azure resources**
4. Fill in:
   - **Organisation**: your GitHub org (e.g. `aztfmodnew`)
   - **Repository**: your platform-starter fork
   - **Entity type**: `Branch`
   - **Branch**: `bootstrap`
   - **Name**: `github-bootstrap`
5. Repeat for branch `end2end` (entity type `Branch`, name `github-end2end`)
6. Repeat for branch `main` with any level runners you configure

Then set the GitHub Actions **variable** (not a secret) at the repository level:

```
CAF_AUTH_MODE = oidc
```

Repository secrets expected by the reusable workflows:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_MANAGEMENT_SUBSCRIPTION_ID` for the launchpad/bootstrap subscription
- `AZURE_TARGET_SUBSCRIPTION_ID` for the subscription where the landing zone is deployed
- In multi-subscription setups, also add `AZURE_CONNECTIVITY_SUBSCRIPTION_ID`, `AZURE_IDENTITY_SUBSCRIPTION_ID`, and `AZURE_SECURITY_SUBSCRIPTION_ID`

And set `auth_mode: oidc` in your `ignite.yaml` (this is the default in this fork).

> **Note:** With OIDC, `ARM_CLIENT_SECRET` is never stored anywhere. The GitHub Actions runner exchanges its OIDC token for an Azure access token automatically via `azure/login@v2`. The reusable workflows also accept `AZURE_LAUNCHPAD_SUBSCRIPTION_ID` as a compatibility alias for the launchpad subscription.

---

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
