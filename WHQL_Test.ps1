#This Scripts could not used to run NDIS job current currently,it is still under developing
#Tested passed in following scenario :
#1.install all the guest platforms 
#2.same version driver sumbit to HCK Manager at different time
#3.same driver w/ Different version use the same devicefamily 
#todo list:
#1.NDIS test support
#2.Exception handle
#3.make the scripts into function
# Author: Mike Cao <bcao@redhat.com>

$ObjectModel = [Reflection.Assembly]::LoadFrom($env:WTTSTDIO + "microsoft.windows.Kits.Hardware.objectmodel.dll")
$ObjectModel = [Reflection.Assembly]::LoadFrom($env:WTTSTDIO + "microsoft.windows.Kits.Hardware.objectmodel.dbconnection.dll")

Clear-Host
Write-Host "Usage: %SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe -file WHQLTest.ps1 <<ControllerMachineName>> <<Driver_name>> <<Driver version>> "

$ControllerName = $args[0]
$Driver = $args[1]
$Driver_version = $args[2]
$projectname = "virtio-win-prewhql-"+$Driver_version+"-"+$Driver

if ($Driver -eq $null -OR $Driver  -eq "")
{
    write-host "Pls supply which driver you want to be tested viostor, netkvm, vioscsi, balloon, vioser "
    return
}

if ($Driver_version  -eq $null -OR $Driver_version  -eq "")
{
    write-host "Need to supply the driver version for whql"
    return
}

if ($ControllerName -eq $null -OR $ControllerName -eq "")
{
    write-host "Need to supply the controller Name as a parameter to this script"
    return
}
else
{
    write-host connecting to the controller $ControllerName
}

# create a device family via the param provided by user

switch($Driver)
{
{$Driver -eq "viostor"}{Write-host "viostor";[string[]]$HardwareIds = "PCI\VEN_1AF4&DEV_1001&SUBSYS_00021AF4";break}
{$Driver -eq "netkvm"} {Write-host "netkvm";[. netkvm ;break}
{$Driver -eq "vioscsi"}{Write-host "vioscsi";[string[]]$HardwareIds = "PCI\VEN_1AF4&DEV_1004&SUBSYS_00081AF4";break}
{$Driver -eq "vioser"} {Write-host "vioser";[string[]]$HardwareIds = "PCI\VEN_1AF4&DEV_1003&SUBSYS_00031AF4";break}
{$Driver -eq "balloon"}{Write-host "balloon";[string[]]$HardwareIds = "PCI\VEN_1AF4&DEV_1002&SUBSYS_00051AF4";break}
default {Write-host Invalid driver name ,pls check whehter you type viostor netkvm vioscsi vioser balloon;return}

}
Write-Host switch done 

# connect to the controller
$Manager = new-object -typename Microsoft.Windows.Kits.Hardware.ObjectModel.DBConnection.DatabaseProjectManager -Args $ControllerName, DTMJobs

$RootPool = $Manager.GetRootMachinePool()
$DefaultPool = $RootPool.DefaultPool

#load or create a machinepoolgroup
$TestPoolGroupFlag = 0
$RootPool.GetChildPools() | foreach {
    if ($_.Name -eq $projectname)
    {
    Write-Host $_.Path
    $TestPoolGroup = $_
    $TestPoolGroupFlag = 1
    }
}
if ($TestPoolGroup -eq "0")
{
$TestPoolGroup=$RootPool.CreateChildPool($projectname)
}

#load or create a project
$projectFlag = 0
$Manager.GetProjectNames() | foreach {
    if ($_ -eq $projectname)
    {
	$Project = $Manager.GetProject($projectname)
        $ProjectFlag = 1
       
    }

}
if ($ProjectFlag -eq "0")
{
    $Project = $Manager.CreateProject($projectname)
    $TestPoolGroup = $RootPool.CreateChildPool($projectname)
}


$DeviceFamilyFlag = 0
$Manager.GetDeviceFamilies() | foreach {
    Write-Host $_.name
    if ($_.name -eq $Driver)
    {
        $DeviceFamily = $_
        $DeviceFamilyFlag = 1
    }
}

if ($DeviceFamilyFlag -eq "0")
{
    $DeviceFamily = $Manager.CreateDeviceFamily($Driver, $HardwareIds)
}

# find all the computers in the default pool, and move them into the test pool
$DefaultPool.GetMachines() | foreach {
    write-host $_.name
    
    # create the pool
    $TestPool = $TestPoolGroup.CreateChildPool($_.Name)
    $DefaultPool.MoveMachineTo($_, $TestPool)

    # now, make sure that the computers are in a ready state
    $TestPool.GetMachines() | foreach { $_.SetMachineStatus([Microsoft.Windows.Kits.Hardware.ObjectModel.MachineStatus]::Ready, 1) }
   
    # create a product instance by using the OS Platform of the first computer that you find
    $ProductInstance = $Project.CreateProductInstance($_.name, $TestPool, $TestPool.GetMachines()[0].OSPlatform)


    # create a target family by using the device family that you created earlier
    $TargetFamily = $ProductInstance.CreateTargetFamily($DeviceFamily)

    #find all the devices in this machine pool that are in this device family
    $ProductInstance.FindTargetFromDeviceFamily($DeviceFamily) | foreach {
        "attempting to add target $_.Name on machine $_.Machine.Name to TargetFamily"
        # and add those to the target family
    
        # check this first, to make sure that this can be added to the target family
         if ($TargetFamily.IsValidTarget($_)) {
             $TargetFamily.CreateTarget($_)
            }
         } 

    #schedule all tests
    $ProductInstance.GetTests() | foreach {
        "Test {0} is {1}" -f  $_.Name.ToSTring(), $_.ScheduleOptions.ToString()
        "Test {0} will Running!! " -f $_.Name.ToString()
        $_.QueueTest();        
    }
}

Trap [Microsoft.Windows.Kits.Hardware.ObjectModel.ProjectManagerException] {
		write-host ProjectManagerException occurs!!
		exit
	}
	
Trap [Microsoft.Windows.Kits.Hardware.ObjectModel.DataIntegrityException] {
		write-host DataIntegrityException occurs!!
		exit
	}
Trap [Microsoft.Windows.Kits.Hardware.ObjectModel.MachineException] {
		write-host MachineException occurs!!
		exit
	}
Trap [Microsoft.Windows.Kits.Hardware.ObjectModel.ProductInstanceException] {
		write-host ProductInstanceException occurs!!
		exit
	}
Trap [Microsoft.Windows.Kits.Hardware.ObjectModel.ScheduleException] {
		write-host ScheduleException occurs!!
		exit
	}
Trap [Microsoft.Windows.Kits.Hardware.ObjectModel.TargetException] {
		write-host TargetException occurs!!
		exit
	}
Trap [Microsoft.Windows.Kits.Hardware.ObjectModel.TestException] {
		write-host TestException occurs!!
		exit
	}
Trap [System.Management.Automation.MethodInvocationException] {
		write-host MethodInvocationException!!
		exit
	}