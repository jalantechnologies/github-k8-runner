variable "gh_app_id" {
  description = "GitHub app id installed for the runner"
  type        = string
}

variable "gh_app_private_key_path" {
  description = "Path to the private key for GitHub app"
  type        = string
}

variable "gh_app_installation_sites" {
  description = "Installation sites for which runner needs to be configured"
  type        = map(object({
    type            = string
    name            = string
    installation_id = string
  }))
}

resource "kubernetes_namespace" "actions_runner_namespaces" {
  for_each = var.gh_app_installation_sites

  metadata {
    name = "actions-runner-${each.key}"
  }
}

resource "kubernetes_secret" "actions_runner_secrets" {
  type     = "generic"
  for_each = var.gh_app_installation_sites

  data = {
    github_app_id              = var.gh_app_id
    github_app_installation_id = each.value.installation_id
    github_app_private_key     = file(var.gh_app_private_key_path)
  }

  metadata {
    name      = "controller-manager"
    namespace = "actions-runner-${each.key}"
  }
}

resource "helm_release" "actions_runner_controllers" {
  for_each   = var.gh_app_installation_sites
  depends_on = [helm_release.cert_manager, kubernetes_secret.actions_runner_secrets]

  repository       = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart            = "actions-runner-controller"
  create_namespace = false
  wait             = true

  name      = "actions-runner-${each.key}-controller"
  namespace = "actions-runner-${each.key}"

  set {
    name  = "scope.singleNamespace"
    value = true
  }

  set {
    name  = "scope.watchNamespace"
    value = "actions-runner-${each.key}"
  }
}

resource "kubernetes_manifest" "action_runner_deployments" {
  for_each = var.gh_app_installation_sites

  manifest = {
    "apiVersion" = "actions.summerwind.dev/v1alpha1"
    "kind"       = "RunnerDeployment"
    "metadata"   = {
      "name"      = "${each.key}-runner-deployment"
      "namespace" = "actions-runner-${each.key}"
    }
    "spec" = {
      "template" = {
        "spec" = {
          "organization" = each.value.type == "org" ? each.value.name : null
          "repository"   = each.value.type == "repo" ? each.value.name : null
        }
      }
    }
  }
}

resource "kubernetes_manifest" "action_runner_autoscaling" {
  for_each = var.gh_app_installation_sites

  manifest = {
    "apiVersion" = "actions.summerwind.dev/v1alpha1"
    "kind"       = "HorizontalRunnerAutoscaler"
    "metadata"   = {
      "name"      = "${each.key}-runner-deployment-autoscaler"
      "namespace" = "actions-runner-${each.key}"
    }
    "spec" = {
      "scaleDownDelaySecondsAfterScaleOut" = 300
      "scaleTargetRef"                     = {
        "name" = "${each.key}-runner-deployment"
      }
      "minReplicas" = 1
      "maxReplicas" = 5
      "metrics"     = [
        {
          "type"               = "PercentageRunnersBusy"
          "scaleUpThreshold"   = "0.75"
          "scaleDownThreshold" = "0.25"
          "scaleUpFactor"      = "2"
          "scaleDownFactor"    = "0.5"
        }
      ]
    }
  }
}
