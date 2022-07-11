variable "do_cluster_name" {
  description = "Kubernetes cluster name on DigitalOcean"
  default     = "platform-github-runner-cluster"
}

variable "do_token" {
  description = "Access token for managing resources on DigitalOcean with write access"
}

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
