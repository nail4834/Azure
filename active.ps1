clear host
#
#

write-warning "Azure sccript is running to get the details..........."
Do {
[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
[System.Windows.Forms.SendKeys]::SendWait("{F5}")

Start-Sleep -Seconds 60

} While ($true)