##/***************************************
## Copyright (c) All rights reserved
##
## File: Library_WHQL_ENV_Parsing.ps1
##
## Authors (s)
##
##   Mike Cao <bcao@redhat.com>
##
## This file is used to run netkvm related test cases automately
##
## This work is licensed under the terms of the GNU GPL,Version 2.
##
##****************************************/

function local:GetScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}
	. (Join-Path (GetScriptDirectory) "Library_HCK_MachinePoolAPI.ps1" )
	. (Join-Path (GetScriptDirectory) "Library_WHQL_ENV_Parsing.ps1" )
	
	$ObjectModel1 = LoadObjectModel "microsoft.windows.Kits.Hardware.objectmodel.dll"
	$ObjectModel2 = LoadObjectModel "microsoft.windows.Kits.Hardware.objectmodel.dbconnection.dll"

function GetServerPlatformName($Manager)
{
	$ServerPlatforms = New-Object System.Collections.ArrayList
	$Manager.GetPlatforms() | foreach {
		if (!($_.Code.Contains("IA64") -or $_.Code.Contains("ARM")) -and $_.Code.Contains("Server") )
		{
			$ServerPlatforms.Add($_.Code)
		}
	}
	return	$ServerPlatforms
}

function GetPlatformName($Manager)
{
	$ServerPlatforms = New-Object System.Collections.ArrayList
	$Manager.GetPlatforms() | foreach {
		if (!($_.Code.Contains("IA64") -or $_.Code.Contains("ARM") -or $_.Code.Contains("Server")) )
		{
			$ServerPlatforms.Add($_.Code)
		}
	}
	return	$ServerPlatforms
}

function CreateTestMachinePoolGroup ($RootPool ,$ProjectName)
{
	$TestPoolGroupFlag = 0
    GetChildMachinePools $RootPool| foreach {
        if ($_.Name -eq $projectName)
        {
			Write-Host $_.Path
			$TestPoolGroup = $_
			$TestPoolGroupFlag = 1
        } #end of if
    } #end of GetChildPools() foreach
    

    if ($TestPoolGroupFlag -eq "0")
    {
        $TestPoolGroup = CreateChildMachinePool $RootPool $ProjectName 

    } #end of load or create TestMachinePoolGroup
	else
	{
		Write-Host $TestPoolGroup.Name is exists .no need to re-create one
	}
	return $TestPoolGroup
}

function CreateTestPool($TestPoolGroup ,$GuestNameSignature)
{
	$TestMachinePoolFlag = 0
	$TestPoolGroup.GetChildPools() | foreach {
		if($_.Name -eq $GuestNameSignature) #if the pool exists ,move the previous guests to sub-pool
            {
                $TestPool = $_ 
                $TestMachinePoolFlag = 1
            }
        } # end if GetChildPools()
        
        if ($TestMachinePoolFlag -eq "0")
        {
            $TestPool= CreateChildMachinePool $TestPoolGroup $GuestNameSignature 
        }
	return $TestPool
}

function CreateProject($Manager , $ProjectName)
{
	$projectFlag = 0
    $Manager.GetProjectNames() | foreach {
        if ($_ -eq $ProjectName)
        {
	       $Project = $Manager.GetProject($ProjectName)
           $ProjectFlag = 1      
        } #end of if
    } # end of GetProjectNames()

    if ($ProjectFlag -eq "0")
    {
        $Project = $Manager.CreateProject($ProjectName)
    } #end of if
	
	return $Project
}

function CreateDeviceFamily($Manager, $Driver ,$HardwareIds)
{
	$DeviceFamilyFlag = 0
    $Manager.GetDeviceFamilies() | foreach {
        Write-Host $_.name
        if ($_.name -eq $Driver)
        {
            $DeviceFamily = $_
            $DeviceFamilyFlag = 1
        } #end of if
    } #end of GetDeviceFamilies foreach

    if ($DeviceFamilyFlag -eq "0")
    {
        $DeviceFamily = $Manager.CreateDeviceFamily($Driver, $HardwareIds)
    } #end of if
	return $DeviceFamily
}

function ManualAddFeatures( $Manager ,$OSPlatformCode)
{
	$Manager.GetFeatures() | foreach {
		Write-Host $OSPlatformCode
		if ($OSPlatformCode.Contains("SERVER") -and $_.FullName -eq ("Device.Network.LAN.RSS"))
		{ 
			$Features = $_
		}
		if ($Platforms -contains $SUT_OSPlatform -and $_.FullName -eq ("Device.Network.LAN.PM"))
		{ 
			$Features = $_
		}
	}
	return $Features
}
#Need to investigate again!!!
function MoveMachineToTestPool( $DefaultPool , $GuestNameSignature , $TestPool, $Role ,$Driver)
{
	if ($Driver -eq "netkvm")
	{
		$DefaultPool.GetMachines() | foreach {
			if ($_.Name.Contains($GuestNameSignature) -AND ($_.Name.SubString(12,1) -eq $Role) )
			{
				$Machine = $_ 
				$DefaultPool.MoveMachineTo($Machine, $TestPool)
				# no idea why after adding this line ,this function will return object type
				#$Machine.SetMachineStatus([Microsoft.Windows.Kits.Hardware.ObjectModel.MachineStatus]::Ready, 1)
				
				#sleep 5
				
				
			}			
		}
	}
	else
	{
		$DefaultPool.GetMachines() | foreach {
			if ($_.Name.Contains($GuestNameSignature))
			{
				$Machine = $_ 
				$DefaultPool.MoveMachineTo($Machine, $TestPool)
				# no idea why after adding this line ,this function will return object type
				#$Machine.SetMachineStatus([Microsoft.Windows.Kits.Hardware.ObjectModel.MachineStatus]::Ready, 1)
				
				#sleep 5
				
				
			}			
		}
	}
	Write-Host aaa machine ,what is your type ? $Machine.GetType()
	return $Machine
	
}



function CheckStatus()
{
	Write-Host now the VM is running now ,let us checking running status .. 
}


function RunWHQLJobs
{	 

	GetXMLValuesx`
	switch($Driver)
    {

        {$Driver -eq "viostor"}{Write-host "viostor";[string[]]$HardwareIds = "PCI\VEN_1AF4&DEV_1001&SUBSYS_00021AF4";$GuestNameSignature = $Driver_Version+"BLK"+$OSPlatform;break}
		{$Driver -eq "netkvm"} {Write-host "netkvm"; [string[]]$HardwareIds = "PCI\VEN_1AF4&DEV_1000&SUBSYS_00011AF4";$GuestNameSignature = $Driver_Version+"NIC"+$OSPlatform;break}
		{$Driver -eq "vioscsi"}{Write-host "vioscsi";[string[]]$HardwareIds = "PCI\VEN_1AF4&DEV_1004&SUBSYS_00081AF4";$GuestNameSignature = $Driver_Version+"SCS"+$OSPlatform;break}
		{$Driver -eq "vioser"} {Write-host "vioser";[string[]]$HardwareIds = "PCI\VEN_1AF4&DEV_1003&SUBSYS_00031AF4";$GuestNameSignature = $Driver_Version+"SRL"+$OSPlatform;break}
		{$Driver -eq "balloon"}{Write-host "balloon";[string[]]$HardwareIds = "PCI\VEN_1AF4&DEV_1002&SUBSYS_00051AF4";$GuestNameSignature = $Driver_Version+"BLN"+$OSPlatform;break}
		default {Write-host Invalid driver name ,pls check your configuration file ,whether Driver_Name part is viostor netkvm vioscsi vioser balloon;return}

    }  # end of switch
	GetKitValues
	Write-Host GuestNameSignature is $GuestNameSignature
	
	#Remove ARM and IA64 platform hosts 
 
    #load or create a project
	$Project = CreateProject $Manager $GuestNameSignature # let's try to use GuestNameSignature instead of $Manager $ProjectName
	
	#load or create TestMachinePoolGroup
	$TestPoolGroup = CreateTestMachinePoolGroup $RootPool $ProjectName

    #Load or create a DeviceFamily
	$DeviceFamily = CreateDeviceFamily $Manager $Driver $HardwareIds
	
	#create TestPool
	$TestPool = CreateTestPool $TestPoolGroup $GuestNameSignature

    "there are {0} machines in the default pool" -f $DefaultPool.GetMachines().Count 
	#Move the Machines to the TestingPool

	$SUT = MoveMachineToTestPool $DefaultPool $GuestNameSignature $TestPool "C" $Driver
	Write-Host SUT do you have a machinetype $SUT.GetType()
	$MachineName = $SUT.Name
	Write-Host SUT machine name is $MachineName
	
	$SUT.SetMachineStatus([Microsoft.Windows.Kits.Hardware.ObjectModel.MachineStatus]::Ready, 1)
    $ProductInstance = $Project.CreateProductInstance($MachineName, $TestPool, $SUT.OSPlatform)
    $TargetFamily = $ProductInstance.CreateTargetFamily($DeviceFamily)          
               
    "Targetdata count is {0}" -f $ProductInstance.FindTargetFromDeviceFamily($DeviceFamily).Count
    #find all the devices in this machine pool that are in this device family
    $ProductInstance.FindTargetFromDeviceFamily($DeviceFamily) | foreach {                
		#attempting to add target $_.Name on machine $_.Machine.Name to TargetFamily"
		# and add those to the target family
		# check this first, to make sure that this can be added to the target family
		#"TargetData name is {0}" -f $_.Name
		#"TargetData machine is {0}" -f $_.Machine.Name
		if ($TargetFamily.IsValidTarget($_) -And $_.Machine.Name -eq $MachineName) 
		{                
			Write-host we want to add features $SUT.OSPlatform.Code			
			$Target = $TargetFamily.CreateTarget($_)		
		} 
    } #end of foreach  
	
	#Move Slave Host for netkvm
	if($Driver -eq "netkvm")
	{
		$Features = ManualAddFeatures $Manager $SUT.OSPlatform.Code
		$Target.AddFeature($Features)
		$SlaveMachine = MoveMachineToTestPool $DefaultPool $GuestNameSignature $TestPool "S"
		$SlaveMachine.SetMachineStatus([Microsoft.Windows.Kits.Hardware.ObjectModel.MachineStatus]::Ready, 1)
		sleep 5
	}

     "mike cao want {0} " -f $TestPool.GetMachines().Count

    $Target.GetTests()| foreach{    
        "Test name :{0}" -f $_.Name 
        $MachineRole = $_.GetMachineRole()   #return machineset
        if ($MachineRole -eq "" -OR $MachineRole -eq $null) 
        {
            $_.QueueTest()
            "job run"               
        }
        else 
        {
			
			$MachineRole.Roles[1].AddMachine($SlaveMachine)
            $_.QueueTest($MachineRole)
            "slave job run "
        } #end of else
    } # end of TestPool.GetTests
	
	checkStatus

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
#Trap [Exception] {
#		write-host unknownException occurs!!
#		exit
#	}
	
. RunWHQLJobs