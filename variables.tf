
variable "location" {
  type        = string
  description = "Azure region to deploy resources."
  default     = "East US"
}

variable "vm_size" {
  type        = string
  description = "Windows VM size."
  default     = "Standard_B2s"
}

variable "admin_username" {
  type        = string
  description = "Local admin username for the VM."
  default     = "azureuser"
}

variable "admin_password" {
  type        = string
  description = "Local admin password for the VM (use Key Vault or pipelines in real projects)."
  sensitive   = true
  default     = "P@ssword123456789!"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources."
  default = {
    project = "patch-mgmt"
    owner   = "assignment2"
  }
}

# -------- Update schedule controls --------
variable "update_schedule_description" {
  type    = string
  default = "Weekly Windows/Linux patching"
}
variable "update_schedule_frequency" {
  type        = string
  description = "One of: OneTime, Day, Hour, Week, Month"
  default     = "Week"
}
variable "update_schedule_interval" {
  type        = number
  description = "Interval for repeating schedule (1 = every run unit)."
  default     = 1
}
variable "update_schedule_start_time_utc" {
  type        = string
  description = "ISO8601 UTC start time (e.g., 2025-08-17T03:00:00Z). Determines the weekday for weekly schedules."
  default     = "2025-08-17T03:00:00Z"
}
variable "update_schedule_time_zone" {
  type        = string
  description = "IANA/Windows timezone, e.g. UTC or Asia/Kolkata."
  default     = "UTC"
}
variable "update_duration" {
  type        = string
  description = "Maintenance window duration as ISO 8601, e.g., PT2H for 2 hours."
  default     = "PT2H"
}

# Windows & Linux patching knobs
variable "windows_classifications" {
  type    = list(string)
  default = ["Critical", "Security", "UpdateRollup", "Updates"]
}
variable "linux_classifications" {
  type    = list(string)
  default = ["Critical", "Security", "Other"]
}
variable "reboot_setting_windows" {
  type        = string
  description = "IfRequired, Always, Never"
  default     = "IfRequired"
}
variable "reboot_setting_linux" {
  type        = string
  description = "IfRequired, Always, Never"
  default     = "IfRequired"
}
