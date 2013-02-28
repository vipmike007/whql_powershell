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


function private:netkvm
{

    $XML = [XML](GetXML "WHQL_env.xml")
    $ControllerName = GetValue  $XML  "Controller"
    $Driver =  GetValue  $XML  "Driver"
    $Driver_Version = GetValue  $XML  "Driver_Version"
    $projectName = "virtio-win-prewhql-"+$Driver_Version+"-"+$Driver

    Write-host $Controllername is $projectName
    Write-host in private:Test $Controllername is $projectName

    $ObjectModel1 = LoadObjectModel "microsoft.windows.Kits.Hardware.objectmodel.dll"
    $ObjectModel2 = LoadObjectModel "microsoft.windows.Kits.Hardware.objectmodel.dbconnection.dll"


    switch($Driver)
    {
    
        {$Driver -eq "netkvm"} {Write-host "netkvm";[string[]]$HardwareIds = "PCI\VEN_1AF4&DEV_1000&SUBSYS_00011AF4"; $MachineNameSignature = "NIC"; break}
    
            default {Write-host Invalid driver name ,pls check whehter you type viostor netkvm vioscsi vioser balloon; return}
    }  # end of switch
    
	#Debug Line
	#$Controllername = "unused"
    # connect to the controller
    $Manager = ConnectDataBaseManager $Controllername

    $RootPool = GetRootMachinePool $Manager
    $DefaultPool = GetDefaultMachinePool $RootPool   
	
	#Remove ARM and IA64 platform hosts 
	$ServerPlatforms = New-Object System.Collections.ArrayList
	$Platforms = New-Object System.Collections.ArrayList
	$Manager.GetPlatforms() | foreach {
		Write-host code : $_.code
		if (!($_.Code.Contains("IA64") -or $_.Code.Contains("ARM")))
        {
			if($_.Code.Contains("Server"))
			{
				$ServerPlatforms.Add($_.Code)
			}
			else
			{
				$Platforms.Add($_.Code)
			}
		}
	}
    
    #hardcode ,need to rewrite Add features function
    $Features_Server = New-Object System.Collections.ArrayList
    
    #load or create TestMachinePoolGroup
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
        $TestPoolGroup= CreateChildMachinePool $RootPool $projectName 
        #$TestPoolGroup = $RootPool.CreateChildPool($projectName)
    } #end of load or create TestMachinePoolGroup

    #load or create a project
    $projectFlag = 0
    $Manager.GetProjectNames() | foreach {
        if ($_ -eq $projectName)
        {
	       $Project = $Manager.GetProject($projectName)
           $ProjectFlag = 1      
        } #end of if
    } # end of GetProjectNames()

    if ($ProjectFlag -eq "0")
    {
        $Project = $Manager.CreateProject($projectName)
        #$TestPoolGroup= CreateChildMachinePool $RootPool $projectName
    } #end of if

    #Load or create a DeviceFamily
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

    "there are {0} machines in the default pool" -f $DefaultPool.GetMachines().Count 

    $DefaultPool.GetMachines() | foreach {
        write-host $_.Name
        if ($_.name.Contains($MachineNameSignature) -AND  ($_.name.SubString(13,1) -eq "C") ) 
        {
            
            $SUT = $_       
            $MachineName = $SUT.Name
            $MachinePoolName = $SUT.Name.SubString(0,12)
			$SUT_OSPlatform = $_.OSPlatform.Code
            $TestMachinePoolFlag = 0    
            Write-Host We will test host majorversion is  $_.OSPlatform.MajorVersion now
            Write-Host We will test host Architecture is  $_.OSPlatform.Architecture now
            Write-Host We will test host Code is  $_.OSPlatform.Code now
            Write-Host We will test host MinorVersion is  $_.OSPlatform.MinorVersion now
            Write-Host We will test host Name is  $_.OSPlatform.Name now
            Write-Host We will test host Description is  $_.OSPlatform.Description now
            Write-Host the hashcode is $_.OSPlatform.GetHashCode() now 
			$Manager.GetFeatures() | foreach {
			if ($ServerPlatforms -contains $SUT_OSPlatform -and $_.FullName -eq ("Device.Network.LAN.RSS"))
			{ 
				$Features = $_
			}
			if ($Platforms -contains $SUT_OSPlatform -and $_.FullName -eq ("Device.Network.LAN.PM"))
			{ 
				$Features = $_
			}
    }
			
        
            $TestPoolGroup.GetChildPools() | foreach {
                if($_.Name -eq $MachinePoolName) #if the pool exists ,move the previous guests to sub-pool
                {
                    $TestPool = $_ 
                    $TestMachinePoolFlag = 1
                }
            
            } # end if GetChildPools()
        
            if ($TestMachinePoolFlag -eq "0")
            {
                $TestPool= CreateChildMachinePool $TestPoolGroup $MachinePoolName 
            }
        
            $SlaveMachineFlag = 0 
            "Machine name {0}" -f $MachineName
            "TestPool {0}" -f $TestPool
        
            $DefaultPool.GetMachines() | foreach {   

                if(($_.Name -ne $MachineName) -And ($_.Name.SubString(0,12) -eq $TestPool.Name) -and ($_.Name.SubString(13,1) -eq "S"))
                {
                    $SlaveMachine = $_
                    $DefaultPool.MoveMachineTo($_, $TestPool)
                    $SlaveMachineFlag = 1
                    Write-Host "we have slave hosts now "
                } #end of if 
        
            } #end of get Slave clients 
        
            if ($SlaveMachineFlag -eq "1")
            {
                $DefaultPool.MoveMachineTo($SUT, $TestPool) #move SUT guests to Test Pool
            
                # now, make sure that the computers are in a ready state
                $TestPool.GetMachines() | foreach { $_.SetMachineStatus([Microsoft.Windows.Kits.Hardware.ObjectModel.MachineStatus]::Ready, 1)  }   
                sleep 10
                $ProductInstance = $Project.CreateProductInstance($MachineName, $TestPool, $SUT.OSPlatform)
                $TargetFamily = $ProductInstance.CreateTargetFamily($DeviceFamily)          
                
                "Targetdata count is {0}" -f $ProductInstance.FindTargetFromDeviceFamily($DeviceFamily).Count
                #find all the devices in this machine pool that are in this device family
                $ProductInstance.FindTargetFromDeviceFamily($DeviceFamily) | foreach {                
                    #"attempting to add target $_.Name on machine $_.Machine.Name to TargetFamily"
                    # and add those to the target family
                    # check this first, to make sure that this can be added to the target family
                    "TargetData name is {0}" -f $_.Name
                    "TargetData machine is {0}" -f $_.Machine.Name
                    if ($TargetFamily.IsValidTarget($_) -And $_.Machine.Name -eq $MachineName) 
                    {                
                        $Target = $TargetFamily.CreateTarget($_)
                        $Target.AddFeature($Features)
                        
                                   
                    } 
               
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
      
            }  #end of if SlaveMachineFlag =1
        } # ($_.name.Contains($MachineNameSignature) -AND  ($_.name.SubString(13,1) -eq "C") ) 
  
    } # end of get machines

    
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
	
. netkvm