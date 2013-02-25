##/***************************************
## Copyright (c) All rights reserved
##
## File: Library_HCK_Task_API.ps1
##
## Authors (s)
##
##   Mike Cao <bcao@redhat.com>
##
## File name:
##   Library_HCK_Task_API.ps1
##
## This file is used parsing Task Class APIs
##
## This work is licensed under the terms of the GNU GPL,Version 2.
##
##****************************************/

#Assenssmentscors function 
#return :collection of AssessmntData
function local:GetAssessmentScores($Task)
{
    $Task.AssessmentScores
}

#GetName function
#Return :task name
function local:GetName ($Task)
{
    $Task.Name
}

#GetStage function
#Return :string stage
function local:GetStage ($Task)
{
    $Task.Stage
}

#GetStatus function
#Return :TestingResultsStatus 
function local:GetStatus ($Task)
{
    $Task.Status
}

#GetTaskErrorMessage function
#Return : String 
function local:GetTaskErrorMessage($Task)
{
    $Task.TaskErrorMessage
}

#GetTaskType function
#Return :String
function local:GetTaskType($Task)
{
    $Task.TaskType
}

#GetTestResults
#Return : TestResult
function local:GetTestResults($Task)
{
    $Task.TestResult
}

#GetAppliedFilters
#Return collection of IFilter
function local:GetAppliedFilters($Task)
{
    $Task.GetAppliedFilters()
}

#GetChildTasks
#Return collection of Task
function local:GetChildTasks($Task)
{
    $Task.GetChildTasks()
}

#GetLogFiles
#Return collection of TestLog
{
    $Task.GetLogFiles()
}