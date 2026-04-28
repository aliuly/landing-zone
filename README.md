# landing-zone

T Cloud Public demo landing zone

# Configuring cloud credentials

Providers are declared using

```hcl
provider "opentelekomcloud" {}
```

This means that credentials should be configured via environment
variables.

## Configuring using username and password

```bash
export OS_USERNAME="your-username"
export OS_PASSWORD="your-password-key"
export OS_PROJECT_NAME="eu-de_project" # or "eu-de" for non-project scoped credentials
export OS_DOMAIN_NAME="OTC-EU-DE-000000000xxxxx"
```
The `tf` script will automatically guess the `OS_AUTH_URL` and
`OS_REGION_NAME` from the `OS_PROJECT_NAME` if they are not specified.

## Configuring using AK/SK credentials
```bash
export OS_ACCESS_KEY="your-access-key"
export OS_SECRET_KEY="your-secret-key"
export OS_PROJECT_NAME="eu-de_project" # or "eu-de" for non-project scoped credentials
```
The `tf` script will automatically guess the `OS_AUTH_URL` and
`OS_REGION_NAME` from the `OS_PROJECT_NAME` if they are not specified.

If you are using temporary AK/SK credentials you also need to specify
the security token:

```bash
export OS_SECURITY_TOKEN="your-security-token"
```

## Configuring using token

```bash
export OS_AUTH_TOKEN="yourtoken"
export OS_PROJECT_NAME="eu-de_project" # or "eu-de" for non-project scoped credentials
export OS_DOMAIN_NAME="OTC-EU-DE-000000000xxxxx"

```
The `tf` script will automatically guess the `OS_AUTH_URL` and
`OS_REGION_NAME` from the `OS_PROJECT_NAME` if they are not specified.

