terraform {
  #  cloud {
  #    workspaces {
  #      name = "boilerplate-mern-production"
  #    }
  #  }
}

module "digital_ocean" {
  source          = "./modules/digital-ocean"
  do_cluster_name = var.do_cluster_name
  do_token        = var.do_token
}

module "kubernetes" {
  source                            = "./modules/kubernetes"
  kubernetes_client_certificate     = module.digital_ocean.do_cluster_client_certificate
  kubernetes_client_key             = module.digital_ocean.do_cluster_client_key
  kubernetes_cluster_ca_certificate = module.digital_ocean.do_cluster_ca_certificate
  kubernetes_host                   = module.digital_ocean.do_cluster_host
  kubernetes_token                  = module.digital_ocean.do_cluster_token
  gh_app_id                         = var.gh_app_id
  gh_app_private_key_path           = var.gh_app_private_key_path
  gh_app_installation_sites         = var.gh_app_installation_sites
}
