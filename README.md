# Azure Arc Enabled Windows 2012 ESU
This is a repository that hosts a sample run through of the Resource Manager API (provided by management.azure.com) to perform the following operations:
+ Creating an ESU license (deactivated)
+ Updating an ESU license (activated)
+ Link ESU license to a Machine
+ Delete linked ESU license from a Machine
+ Deactivate an ESU license
+ Delete an ESU license

# Tested On:
PowerShell 7.3.7 with PowerShell Az Module 10.4.1, PowerShell Az.ConnectedMachine 0.5.0

# Please note:
This information is being provided as-is with the terms of the MIT license, with no warranty/guarantee or support.  It is free to use - and for demonstration purposes only.  The process of hardening this into your needs is a task I leave to you.

# Additional note:
This shows a mechanism to use the Resource Manager API to accomplish this task.  This will likely be simpler when PowerShell updates to the official Az module and when the CLI updates the same.  Resource Manager APIs are available now.
