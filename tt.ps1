$ResultsTable = New-Object "String[,]" 28,14
[int]$tmp_line = 1
[int]$tmp_column = 2
for([int]$i = 0; $i -lt 28; $i++){
  for([int]$j=0;$j -lt 14;$j++){
      $ResultsTable[$i][$j] = "NA"
      Write-host $ResultsTable[$][$j]
  } #end of $j
} #end of for $ic