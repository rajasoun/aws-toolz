variable "default_tags" {
  description = "Default Tags"
  type        = map(string)
  default = {
    project     = "cloud_practioner_training"
    environment = "lab"
    owner       = "rajasoun@icloud.com"
    teardown    = "enabled"
    automation  = "terraform"
  }
}
