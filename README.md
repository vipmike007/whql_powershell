WHQL automation via powershell 

License
===============
   Copyright (C) 2013  Mike Cao <vipmike007@gmail.com>
 
   whql_powershell: A simple kit to automate WHQL testing
 
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; under version 2 of the License.
 
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
 
   You should have received a copy of the GNU General Public License
   along with this program; if not, see <http://www.gnu.org/licenses/>.
   
Usage
(a) Submit HCK Jobs for each driver
1.Modify SUT name as following format
[ver][[driver][os][arch][c/s][random]
dictitory for each bit
[ver] 3bit eg: 011 068 099 100
[Driver] 3bit : SRL BLN BLK SCS NIC
[os]  4bit : WIXP 2003 WIN7 WIN8 BLUE 2012
[Arch] 2 bit : 32 64 R2
[C/S] 1 bit : espically for HCK netkvm tests . C/S
[Random ] 2bit : write anything you like eg aa 01 03 1
2.Reboot your host
3.Install HCK Client
\\<HCKStdio>\Client\Setup.exe \qb /ICFAGREE=yes
4.Modify xml file in this testing kit .
eg:
<Config>
<Controller>virtio-hck</Controller>
<Driver>netkvm</Driver>
<Driver_Version>069</Driver_Version>
<OSPlatform>BLUE32</OSPlatform>
</Config>
5.Run the script
C:\windows\syswow64\windowspowershell\v1.0\powershell -file netkvm.ps1

(b)Generate HCKX file your the same driver on different operation systems
eg in your HCK ,there are following  projects named as below (submit them via the command in (a0)
070BLNwixp32
070BLN200332
070BLN200364
070BLNWIN732
070BLNWIN764
070BLN200832
070BLN200864
070BLN2008R2
070BLN201264
070BLNWIN832
070BLNWIN864

1.Modify XML File in this testing suite
<Controller>virtio-hck</Controller>
<Driver>netkvm</Driver>  #keep defaults 
<Driver_Version>069</Driver_Version>  #keep defaults
<OSPlatform>BLUE32</OSPlatform>   #keep defaults
<GroupName>070BLN</GroupName>   
<SavePath>C:\</SavePath>
</Config>
2.Run C:\windows\syswow64\windowspowershell/v1.0/powershell.exe -file Generate_Test_Summary.ps1
3.hckx file will be generated ,and the results will be export to a windows xlsx file .if the results is pass ,mark it as green ,red if it is failed

todo list
1.merge hckx file 
2.add driver folder according to driver folder mapping matrix


