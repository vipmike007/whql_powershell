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


function GenerateJobSummary
{	 

	GetXMLValues
	GetKitValues

	$RootPool = $Manager.GetRootMachinePool();


    # list all projects, and get the basic status of each
    $Manager.GetProjectInfoList() | foreach {
        if($_.Name.Contains($GroupName))
        {
            write-host "Name   : " $_.Name
            write-host "`tStatus : " $_.Status
            write-host "`tNotRun : " $_.NotRunCount.ToString()
            write-host "`tPassed : " $_.PassedCount
            write-host "`tFailed : " $_.FailedCount
            write-host "`tRunning: " $_.RunningCount
            $Project = $Manager.GetProject($_.Name)
            write-host "`Project Status: " $Project.Info.Status 
            
            $Project.GetProductInstances() | foreach {
                write-host "Product Instance : " $_.Name 
                write-host "`Machine pool : " $_.MachinePool.Name 
                write-host "`OS Platform : " $_.OSPlatform.Description
                $_.GetTests() | foreach {
                    write-host "`t" $_.Name -NoNewline
                    write-host "`t" $_.Status


            }
            
         }
    }
    }
    }

    # list all the tests for each project
#    $Manager.GetProjectNames() | foreach {
        #$Project = $Manager.GetProject($_)
        #write-host "Project Name  : " $Project.Name 
        #write-host "`Project Status: " $Project.Info.Status
        #if($Project.Name.Contains("65-balloon"))
        #{
         #   $Project.GetProductInstances() | foreach {
          #      write-host "Product Instance : " $_.Name 
           #     write-host "`Machine pool : " $_.MachinePool.Name 
            #    write-host "`OS Platform : " $_.OSPlatform.Description
             #   $_.GetTests() | foreach {
              #      write-host "`t" $_.Name -NoNewline
               #     if ($_.GetTestTargets().Count -ne 1)
                #        { write-host " - shared" }
                 #   else
                  #      { write-host " -  not shared" }
                #}
        
        #}
    #}        
    #}      
   




	
. GenerateJobSummary