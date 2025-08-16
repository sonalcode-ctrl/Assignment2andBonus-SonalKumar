
resource "azurerm_automation_software_update_configuration" "this" {
  name                  = var.name
  automation_account_id = var.automation_account_id
  duration              = var.duration

  schedule {
    description = var.schedule_description
    frequency   = var.schedule_frequency
    interval    = var.schedule_interval
    start_time  = var.schedule_start_time_utc
    time_zone   = var.schedule_time_zone
  }

  target {
    azure_query {
      scope     = [var.target_scope_id]
      locations = [var.target_location]
    }
  }

  windows {
    classifications_included = var.windows_classifications
    reboot                   = var.reboot_setting_windows
  }

  linux {
    classifications_included = var.linux_classifications
    reboot                   = var.reboot_setting_linux
  }
}
