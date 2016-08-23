## Test for DFW Memory heap usage
#a: Anthony Burke - @pandom_
#c: (dcoghland for original idea and initial code, nbradford for sanity checks and matching)
#r: PowerCLI, PowerNSX, PSate, PShould


## DO NOT EDIT.
### The limit threshold is recommended as a buffer. If 80% of memory or more is used the test will fail.
## Some math for heap percentage
  $limit = 20
  $total = (100-$limit)
## Collect all VMhosts under vCenter
  $esxi_creds = (Get-Credential)



## Initiate Test sequence
DescribingEach "Distributed Firewall Memory heaps"{
  $vSphereHosts = get-cluster | % {
    $currclus = $_
      if (($currclus | get-nsxclusterstatus | ? { $_.featureId -eq 'com.vmware.vshield.firewall' }).Installed -eq 'true') {
        $currclus
    }
  } | get-vmhost

  # For each vSphere host found by Get-VMhost connect to host with SSH
  foreach ( $vsphere in $vSphereHosts ) {
    GivenEach "vSphere Host $($vSphere.name)" {
      $esxi_SSH_Session = New-SSHSession -ComputerName $vsphere -Credential $esxi_creds -AcceptKey
      #Invoke vsish command to list all VSIP heaps and store it
      $vsish_command_1 = "vsish -e ls /system/heaps|grep vsip"
      $vsish_object_1 = Invoke-SSHCommand -SessionId $esxi_SSH_Session.SessionId -Command $vsish_command_1 -EnsureConnection
      #Upon the stored object, for each heap listed, use SSH session to check heap memory remaining.
      foreach ($heap in $vsish_object_1.output) {

        $command = "vsish -e get /system/heaps/$heap'stats'"
        $stats = Invoke-SSHCommand -SessionId $esxi_SSH_Session.SessionId -Command $command -EnsureConnection
        $stats.output | ? { $_ -match "(percent free of max size):(\d{1,3})" } > $Null
        # Based on the regex output, use matches and PShould to determine remaining memory is more than limit (ex:80 is more than 20)
        It "has not surpassed the $total % memory threshold on memory heap $heap for $vsphere" {
          $matches[2] | should be  -gt $limit
        }
      }
    }
  }
}
