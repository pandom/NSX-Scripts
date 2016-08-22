## Basic NSX health check
#
#
# Requires Psate
# Requires Pshould
# Requests PowerNSX
#
#
# To Do. Build in more checks.
#* Get feedback from Nick
#* Look at outputs based on failure
#* What should be tested?

TestFixture "VMware components" {


## A list of URIs to test connectivity environment.
    $a = "http://vmware.com/"
    $b = "https://vc-01a.corp.local/vsphere-client/?csp"
    $c = "https://192.168.100.201/login.jsp"
    $uris = @($a,$b,$c)

    foreach ($u in $uris){
        TestCase "$u is accessible" {
            $results = Invoke-WebRequest -Uri $u
            $results.StatusCode | Should be 200
        }
    }

    TestCase "GitHub API status check" {
        $results = Invoke-RestMethod https://status.github.com/api/status.json

        $results.status | Should be good
    }

    TestCase "NSX Manager API check" {

    	$results = Invoke-NsxRestMethod -uri /api/1.0/appliance-management/summary/system -method get

    	$results.versioninfo.majorVersion | Should be 6

}

    TestCase "Check NSX Controllers"{


    	$results = Invoke-NsxRestMethod -uri /api/2.0/vdn/controller -method get
      # For loop to test the same command against EACH controller found.
      foreach ($controller in $($results.Controllers.controller)) {

          $controller.status | should be RUNNING
          # This write-host here was to prove my loop works for each controller.
	    write-host -foregroundcolor green "        [++]Testing individual controller"

      }




}

}
