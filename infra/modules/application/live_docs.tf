locals {
  default_live_doc_source_registry = {
    version = 1
    sources = [
      {
        source_id              = "kubernetes"
        display_name           = "Kubernetes Documentation"
        product                = "kubernetes"
        version                = "current"
        enabled                = true
        hostnames              = ["kubernetes.io"]
        path_prefixes          = ["/docs/"]
        max_pages_per_query    = 3
        request_timeout        = 5
        max_response_bytes     = 2000000
        freshness_days         = 30
        include_patterns       = []
        exclude_patterns       = []
        search_path            = "/docs/"
        sitemap_url            = "https://kubernetes.io/sitemap.xml"
        documentation_version  = "current"
        documentation_strategy = "current"
        catalogue = [
          {
            title    = "Pods"
            url      = "https://kubernetes.io/docs/concepts/workloads/pods/"
            keywords = ["pod", "pods", "workload", "container", "sidecar"]
          },
          {
            title    = "Services"
            url      = "https://kubernetes.io/docs/concepts/services-networking/service/"
            keywords = ["service", "services", "networking", "clusterip", "nodeport", "loadbalancer"]
          },
          {
            title    = "Persistent Volumes"
            url      = "https://kubernetes.io/docs/concepts/storage/persistent-volumes/"
            keywords = ["persistentvolume", "persistent volume", "pvc", "storage"]
          }
        ]
      },
      {
        source_id              = "github_actions"
        display_name           = "GitHub Actions Documentation"
        product                = "github-actions"
        version                = "current"
        enabled                = true
        hostnames              = ["docs.github.com"]
        path_prefixes          = ["/en/actions/"]
        max_pages_per_query    = 3
        request_timeout        = 5
        max_response_bytes     = 2000000
        freshness_days         = 30
        include_patterns       = []
        exclude_patterns       = []
        search_path            = "/en/actions/"
        sitemap_url            = "https://docs.github.com/sitemap.xml"
        documentation_version  = "current"
        documentation_strategy = "current"
        catalogue = [
          {
            title    = "Workflow syntax for GitHub Actions"
            url      = "https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions"
            keywords = ["workflow", "syntax", "jobs", "steps", "permissions", "yaml"]
          },
          {
            title    = "OpenID Connect in AWS"
            url      = "https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws"
            keywords = ["oidc", "aws", "role", "trust policy", "sts"]
          },
          {
            title    = "Contexts"
            url      = "https://docs.github.com/en/actions/learn-github-actions/contexts"
            keywords = ["contexts", "github", "env", "vars", "secrets"]
          }
        ]
      },
      {
        source_id              = "terraform"
        display_name           = "Terraform Documentation"
        product                = "terraform"
        version                = "current"
        enabled                = true
        hostnames              = ["developer.hashicorp.com"]
        path_prefixes          = ["/terraform/"]
        max_pages_per_query    = 3
        request_timeout        = 5
        max_response_bytes     = 2000000
        freshness_days         = 30
        include_patterns       = []
        exclude_patterns       = []
        search_path            = "/terraform/"
        sitemap_url            = "https://developer.hashicorp.com/sitemap.xml"
        documentation_version  = "current"
        documentation_strategy = "current"
        catalogue = [
          {
            title    = "S3 backend"
            url      = "https://developer.hashicorp.com/terraform/language/backend/s3"
            keywords = ["backend", "s3", "state", "locking", "lockfile"]
          },
          {
            title    = "Input variables"
            url      = "https://developer.hashicorp.com/terraform/language/values/variables"
            keywords = ["variables", "tfvars", "input", "validation"]
          },
          {
            title    = "Terraform CLI plan"
            url      = "https://developer.hashicorp.com/terraform/cli/commands/plan"
            keywords = ["plan", "terraform plan", "detailed exitcode"]
          }
        ]
      }
    ]
  }
}

resource "aws_ssm_parameter" "live_doc_sources" {
  name  = "/${var.project_name}/${var.environment}/live-docs/source-registry"
  type  = "SecureString"
  value = var.live_doc_source_registry_json == "" ? jsonencode(local.default_live_doc_source_registry) : var.live_doc_source_registry_json
  tags  = local.default_tags
}
