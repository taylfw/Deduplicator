# Creates an object containing all workstation in Inventory
$workstationInventory = (Get-ADUser workstationInventory -Properties workstations |
Select-Object workstations).workstations

# Creates an object containing all workstations assigned to users. 
$usersWithLaptops = (Get-ADUser -searchbase "OU=Employees,DC=contoso,DC=local" -filter * -properties workstations |
Where-Object workstations |
Select-Object workstations).workstations

#Compare the two objects and select any workstations that are in both workstation inventory and assigned to a user.
$duplicates = (Compare-Object -ReferenceObject $usersWithLaptops -DifferenceObject $workstationInventory -IncludeEqual |
Where-Object SideIndicator -EQ '==').InputObject


# Creates a function that requires human judgement to decide weather the workstation needs to be removed from inventory or the user.
function deduplicator{
    param (
        $luserName,
        $dupName
    )
    write-Host "Remove " $dupName " from:"
    Write-Host "1: workstation inventory "
    Write-Host "2:"$luserName
    Write-Host "'s' to skip"
    $answer = Read-Host "Please make a selection"

    switch($answer){
        1 {Set-ADUser -Identity workstationInventory -Remove @{workstations = "$dupName"}}
        2 {Set-ADUser -Identity $luserName -Remove @{workstations = "$dupName"}}
        "s"{break}
    }
}

write-host "These are the following workstations in question:"
write-host  "#########################"
$duplicates
write-host  "#########################"
Read-Host "Press enter to continue"
Clear-Host

#loop through the list of duplicates and call the deplilcator function.
foreach ($duplicate in $duplicates){

    $luser = (Get-ADComputer $duplicate -Properties Description | Select-Object Description).Description
    Write-Host $duplicate "is assigned to both Workstation Inventory and " $luser

    deduplicator -luserName $luser -dupName $duplicate
    Clear-Host
}

Write-Host "Later, Gator."