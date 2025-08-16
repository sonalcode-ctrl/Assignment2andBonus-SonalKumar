
variable "name" { type = string }
variable "automation_account_id" { type = string }
variable "duration" { type = string }

variable "schedule_description" { type = string }
variable "schedule_frequency" { type = string }
variable "schedule_interval" { type = number }
variable "schedule_start_time_utc" { type = string }
variable "schedule_time_zone" { type = string }

variable "target_scope_id" { type = string }
variable "target_location" { type = string }

variable "windows_classifications" { type = list(string) }
variable "linux_classifications" { type = list(string) }
variable "reboot_setting_windows" { type = string }
variable "reboot_setting_linux" { type = string }
