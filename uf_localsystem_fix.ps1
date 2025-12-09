try {
    # Query the service using CIM
    $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='SplunkForwarder'" -ErrorAction Stop

    if ($null -eq $service) {
        Write-Output "Unable to find SplunkForwarder service."
        exit 1
    }

    if ($service.StartName -ne "LocalSystem") {
        # Stop Splunk Universal Forwarder if it is running
        if ($service.State -eq "Running") {
            & "C:\Program Files\SplunkUniversalForwarder\bin\splunk" stop

            # Wait until service is stopped
            do {
                Start-Sleep -Seconds 2
                $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='SplunkForwarder'"
            } while ($service.State -ne "Stopped")
        }

        # Set the service to start as LocalSystem
        sc.exe config "SplunkForwarder" obj= "LocalSystem"

        # Start the universal forwarder
        & "C:\Program Files\SplunkUniversalForwarder\bin\splunk" start
    }

    # Verify success
    $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='SplunkForwarder'" -ErrorAction Stop
    if ($service.StartName -eq "LocalSystem" -and $service.State -eq "Running") {
        Write-Output "SplunkForwarder successfully running as LocalSystem."
    }
    else {
        Write-Output "SplunkForwarder failed initial verification. Attempting one more start..."

        # Try to start again
        & "C:\Program Files\SplunkUniversalForwarder\bin\splunk" start

        # Wait briefly and re-check
        Start-Sleep -Seconds 5
        $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='SplunkForwarder'" -ErrorAction Stop

        if ($service.StartName -eq "LocalSystem" -and $service.State -eq "Running") {
            Write-Output "SplunkForwarder successfully running as LocalSystem after retry."
        }
        else {
            Write-Output "SplunkForwarder failed to start or is not running as LocalSystem after retry."
            exit 1
        }
    }
}
catch {
    Write-Output "Error occurred: $_"
    exit 1
}
