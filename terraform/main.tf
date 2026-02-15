data "github_repository" "repo" {
  name = local.repo_name
}

# Collaborator
resource "github_repository_collaborator" "softserve" {
  repository = local.repo_name
  username   = local.user_name
  permission = "push"
}

# develop branch
resource "github_branch" "develop" {
  repository = local.repo_name
  branch     = "develop"
}

# default branch
resource "github_branch_default" "default" {
  repository = local.repo_name
  branch     = github_branch.develop.branch
}

# Branch protection — develop (2 approvals)
resource "github_branch_protection_v3" "develop" {
  repository = local.repo_name
  branch     = "develop"

  required_pull_request_reviews {
    required_approving_review_count = 2
  }

  enforce_admins = true

  depends_on = [github_branch.develop]
}

# Branch protection — main (owner approval)
resource "github_branch_protection_v3" "main" {
  repository = local.repo_name
  branch     = "main"

  required_pull_request_reviews {
    required_approving_review_count = 0
    require_code_owner_reviews      = true
  }
}

# CODEOWNERS
resource "github_repository_file" "codeowners" {
  repository          = local.repo_name
  branch              = "main"
  file                = ".github/CODEOWNERS"
  content             = "* @softservedata"
  commit_message      = "Add CODEOWNERS"
  overwrite_on_create = true
}

# PR template
resource "github_repository_file" "main_pr_template" {
  repository          = local.repo_name
  branch              = "main"
  file                = ".github/pull_request_template.md"
  content             = local.pr_template
  overwrite_on_create = true
}
resource "github_repository_file" "develop_pr_template" {
  repository          = local.repo_name
  branch              = "develop"
  file                = ".github/pull_request_template.md"
  content             = local.pr_template
  overwrite_on_create = true
  depends_on          = [github_branch.develop]
}

# Deploy key
resource "github_repository_deploy_key" "deploy" {
  title      = "DEPLOY_KEY"
  repository = local.repo_name
  key        = var.deploy_key
  read_only  = false
}

# PAT secret
resource "github_actions_secret" "pat" {
  repository      = local.repo_name
  secret_name     = "PAT"
  plaintext_value = var.github_token
}

# Discord webhook (PR created)
resource "github_repository_webhook" "discord" {
  repository = local.repo_name

  configuration {
    url          = var.discord_webhook
    content_type = "json"
  }

  events = ["pull_request"]
}