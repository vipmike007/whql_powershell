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

	#$RootPool = $Manager.GetRootMachinePool();
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
    [int]$Line = $JobHashTable.Count+2
    [int]$col=0
    
    
    #get the column num of ResultsTable
    $Manager.GetProjectNames() | foreach {
        $Project = $Manager.GetProject($_)
        if ($Project.Name.Contains($GroupName)) {
            $Project.GetProductInstances() | foreach {
                $col++
                }
             }
          }
    $col=$col+3
    write-host "col= " $col
    
    $ResultsTable = New-Object "String[,]" $Line,$col
    [int]$tmp_line = 2
    [int]$tmp_column = 3
    
    for([int]$i = 1; $i -lt $Line; $i++){
        for([int]$j=1;$j -lt $col;$j++){
            $ResultsTable[$i,$j] = "N/A"         
        } #end of $j
    } #end of for $i


  
    foreach($item in $JobHashTable.Keys)
    {
        #"item-key is"+$item
        #"value is"+$JobHashTable[$item]
        $ResultsTable[$tmp_line,1]=$item
        $ResultsTable[$tmp_line,2]=$JobHashTable[$item]
        $tmp_line++    
    }#end of foreach
    
    $ResultsTable[1,1]="Job ID"
    $ResultsTable[1,2]="Job Name"
    
  
    $Manager.GetProjectNames() | foreach {
        $Project = $Manager.GetProject($_)
        if ($Project.Name.Contains($GroupName)) {
            $Project.GetProductInstances() | foreach {
                write-host "Product Instance : " $_.Name 
                write-host "`Machine pool : " $_.MachinePool.Name 
                write-host "`OS Platform : " $_.OSPlatform.Description
                Write-Host "tmp_host" $tmp_column
                $ResultsTable[1,$tmp_column]=$_.OSPlatform.Description.ToString()
           
                $_.GetTests() | foreach {
                    for ($i=2 ;$i -le $Line ;$i++){
                        
                        if($_.Id -eq $ResultsTable[$i,1]){
                            $ResultsTable[$i,$tmp_column] = $_.Status
                    
                        }#end of if
                    }#end of for
                 
                } #end of GetTests
            } #end of get Projectinstance
         $tmp_column++
    
       } #end of if 
    
    } #end of $manager get projectname
	
#write-host $ResultsTable 

$excel = New-Object -ComObject Excel.Application
$workbook = $excel.Workbooks.add()
$workbook.workSheets.item(3).delete()
$workbook.workSheets.item(2).delete()
$workbook.WorkSheets.item(1).Name = "WHQL Result"
$sheet = $workbook.WorkSheets.Item("WHQL Result")

 for ($m=0 ;$m -le $Line;$m++)
  {                      
       for ($n=0 ;$n -le ($col-1) ;$n++)
       {
            $sheet.cells.item($m+1,$n+1)=$ResultsTable[$m,$n]     
            switch ($ResultsTable[$m,$n])
            {
              Passed {$sheet.cells.item($m+1,$n+1).Interior.ColorIndex=4}
              Failed {$sheet.cells.item($m+1,$n+1).Interior.ColorIndex=3}
              N/A {$sheet.cells.item($m+1,$n+1).Interior.ColorIndex=16}
              NotRun {$sheet.cells.item($m+1,$n+1).Interior.ColorIndex=9}
              default {$sheet.cells.item($m+1,$n+1).Interior.ColorIndex=24}
            }
       }
  }  
$sheet.cells.item(1,1)="Detailed Testing Result"
$sheet.cells.item($Line+1,1)="Note"
$sheet.cells.item(2,1)="please write package info here"
$sheet.cells.item(1,1).font.bold = $true

$sheet.Range($sheet.cells.item(1,1),$sheet.cells.item(1,$col)).Merge()
$sheet.Range($sheet.cells.item($Line+1,1),$sheet.cells.item($Line+1,$col)).Merge()
$sheet.Range($sheet.cells.item(2,1),$sheet.cells.item(($Line),1)).Merge()

for ($o=2;$o -lt $col+1;$o ++)
{$sheet.cells.item(2,$o).font.bold = $true}
#$sheet.range("A1,A24").VerticalAlignment=$xlCenter
$range = $sheet.usedRange
$range.EntireColumn.AutoFit() | out-null
$range.Borders.LineStyle = 1 
$workbook.SaveAs("C:\Users\virtioadmin\Documents\whql_autoit\"+$GroupName+".xlsx")
$excel.quit()
#Write-Host "totally job count" $JobHashTable.Count

}  #end of function
	
. GenerateJobSummary