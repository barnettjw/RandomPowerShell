# Send email alert when domain controller replication error is detected
# parses status from "repadmin /replsum" command

# Dependency: Active Directory RSAT

$subject = "Domain Controller Replication Errors Detected"
$from = 'reporting@example.com'
$to = 'admin@example.com'
$mailServer = 'mail.example.com'

###

$replSumErrorsArray = @()
$replSum = repadmin /replsum

###

#iterate through lines of repl sum
for($i = 0; $i -le $replSum.length -1; $i++) {

    # add current line to array if, an error is detected
    if( ($replSum[$i].length -gt 57) -and ($replSum[$i] -match 'dc\d$') ) {
        $replSumErrorsArray += $replSum[$i]
    }
}

# email contents of array
if ($replsumerror -ne @()) {
    $body = $replSumErrorsArray.tostring() 
    Send-MailMessage -to $to -From $from -smtpServer $mailServer -subject $subject -Body $body
}