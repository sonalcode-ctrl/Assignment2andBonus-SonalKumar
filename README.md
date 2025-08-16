
# Assignment 2 & Bonus

This repo contains **working, validated HCL** for:
- A **Log Analytics Workspace** (LAW)
- An **Automation Account** linked to the LAW
- A **Windows VM** (with the **Microsoft Monitoring Agent** extension)
- A **Software Update Configuration (SUC)** that runs **weekly**



## Usage

#bash
terraform init
terraform fmt -recursive
terraform validate
terraform apply -auto-approve
```

## Inputs

See `variables.tf` in the root for defaults. Update these for your region, schedule, and VM size.

'terraform.tfvars'  use .tfvars asper the 

## Notes on Agents (MMA vs AMA)

- **MMA (Microsoft Monitoring Agent)** is **deprecated**, but classic *Automation Update Management* still relies on it.
- For new builds, prefer **Azure Monitor Agent (AMA)** + **Data Collection Rule (DCR)** + **Azure Update Manager**.
- We used MMA here to satisfy the assignment and keep the SUC target working.

### Reference docs

- `azurerm_virtual_machine_extension` (for MMA): see Terraform Registry.  
- LAW resource exposes `primary_shared_key` and `workspace_id` attributes.

```
Provider: AzureRM v4.40.0
```

