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
    $JobHashTable=new-Object System.Collections.hashtable


    # list all projects, and get the basic status of each
    $projectcount = 0
    $Manager.GetProjectInfoList() | foreach {
        if($_.Name.Contains($GroupName)){
            write-host "Name   : " $_.Name
            write-host "`tStatus : " $_.Status
            write-host "`tNotRun : " $_.NotRunCount.ToString()
            write-host "`tPassed : " $_.PassedCount
            write-host "`tFailed : " $_.FailedCount
            write-host "`tRunning: " $_.RunningCount
            write-host "`Project Status: " $Project.Info.Status 
            $Project = $Manager.GetProject($_.Name)
            $Project.GetTests()|foreach {
                $JobHashTable.Add($_.Id,$_.Name)               
            
			}  #end of guest tests foreach
            
        } #end of if
    } #end of manager foreach
    
    Write-Host "totally job count" $JobHashTable.Count
    [int]$Line = $JobHashTable.Count+1
    
    $ResultsTable = New-Object "String[,]" $Line,13
    [int]$tmp_line = 1
    [int]$tmp_column = 2
    
    for([int]$i = 0; $i -lt $Line; $i++){
        for([int]$j=0;$j -lt 14;$j++){
            $ResultsTable[$i,$j] = "N/A"
            #Write-host $ResultsTable[$i,$j]
        } #end of $j
    } #end of for $i


  
    foreach($item in $JobHashTable.Keys)
    {
        #"item-key is"+$item
        #"value is"+$JobHashTable[$item]
        $ResultsTable[$tmp_line,0]=$item
        $ResultsTable[$tmp_line,1]=$JobHashTable[$item]
        $tmp_line++    
    }#end of foreach
  
  
    $Manager.GetProjectNames() | foreach {
        $Project = $Manager.GetProject($_)
        if ($Project.Name.Contains($GroupName)) {
            $Project.GetProductInstances() | foreach {
                write-host "Product Instance : " $_.Name 
                write-host "`Machine pool : " $_.MachinePool.Name 
                write-host "`OS Platform : " $_.OSPlatform.Description
                Write-Host "tmp_host" $tmp_column
                $ResultsTable[0,$tmp_column]=$_.OSPlatform.Description.ToString()
           
                $_.GetTests() | foreach {
                    for ($i=1 ;$i -le $Line ;$i++){
                        
                        if($_.Id -eq $ResultsTable[$i,0]){
                            $ResultsTable[$i,$tmp_column] = $_.Status
                    
                        }#end of if
                    }#end of for
                 
                } #end of GetTests
            } #end of get Projectinstance
         $tmp_column++
    
       } #end of if 
    
    } #end of $manager get projectname
	
	
write-host $ResultsTable 

$excel = New-Object -ComObject Excel.Application 
$workbook = $excel.Workbooks.add()
$workbook.workSheets.item(3).delete()
$workbook.workSheets.item(2).delete()
$workbook.WorkSheets.item(1).Name = "WHQL Result"
$sheet = $workbook.WorkSheets.Item("WHQL Result")
 for ($m=0 ;$m -le $Line ;$m++)
  {                      
       for ($n=0 ;$n -le 13 ;$n++)
       {
            $sheet.cells.item($m+1,$n+1)=$ResultsTable[$m,$n]  
       }
  }
$sheet.cells.item(1,1)="Job ID"
$sheet.cells.item(1,2)="Job Name"
$range = $sheet.usedRange
$range.EntireColumn.AutoFit() | out-null
$excel.Visible = $true

}  #end of function
	
. GenerateJobSummary