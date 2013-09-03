##/***************************************
## Copyright (c) All rights reserved
##
## File: Library_WHQL_ENV_Parsing.ps1
##
## Authors (s)
##
##   Mike Cao <bcao@redhat.com>
##
## File name:
##   Library_WHQL_ENV_Parsing.ps1
##
## This file is used parsing XML File
##
## This work is licensed under the terms of the GNU GPL,Version 2.
##
##****************************************/ 
function global:GetXMLValues
{
	$global:XML = [XML](GetXML "WHQL_env.xml")
    $global:ControllerName = GetValue  $XML  "Controller"
    $global:Driver =  GetValue  $XML  "Driver"
    $global:Driver_Version = GetValue  $XML  "Driver_Version"
    $global:ProjectName = "virtio-win-prewhql-"+$Driver_Version+"-"+$Driver
	$global:OSPlatform = GetValue $XML "OSPlatform"
    $global:GroupName = GetValue $XML "GroupName"
	$global:SavePath = GetValue $XML "SavePath"

    Write-host $Controllername is $ProjectName
    Write-host in private:Test $Controllername is $ProjectName
    Write-host in groupname is $GroupName
}

function GetKitValues
{
	
	#Debug Line
	#$Controllername = "unused"
    #connect to the controller
    $global:Manager = ConnectDataBaseManager $Controllername
	$global:RootPool = GetRootMachinePool $Manager
    $global:DefaultPool = GetDefaultMachinePool $RootPool 
}

function local:GetXML($XML_Name)
{
    get-content $XML_Name
}

##Get Values
function local:GetValue ($XML_Name, $Name)
{

    Isnull $XML_Name.Config.$Name
    return $XML_Name.Config.$Name

}

## check whether the value if null
function local:Isnull ($Parameter)
{
    if ($Parameter -eq $null -OR $Parameter -eq "")
    {
        Write-Host :the value of $Name parameter is null ,pls add it in configuration file
        exit
    }
}

function private:Test
{
    $XML = [XML](GetXML "WHQL_env.xml")
   # Write-host aaaa $XML.Config.Driver
    $ControllerName = GetValue  $XML  "Controller"
    $Driver =  GetValue  $XML  "Driver"
    $Driver_version = GetValue  $XML  "Driver_version"
    $projectname = "virtio-win-prewhql-"+$Driver_version+"-"+$Driver

    Write-host $Controllername is $projectname
}
