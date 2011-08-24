
<#
.Synopsis
	Examples of Use-Framework.

.Description
	Points of interest:

	* If build scripts change the current location they do not have to restore it.

	* Tasks v2.0.50727 and v4.0.30319 are conditional (see the If parameter).

	* The task v4.0.30319 shows a subtle scope issue (artificial in here).

.Link
	Invoke-Build
	.build.ps1
#>

# It is fine to change the location and leave it changed.
Set-Location "$env:windir\Microsoft.NET\Framework"

# This task calls MSBuild 2.0 and tests its version.
task v2.0.50727 -If (Test-Path 'v2.0.50727') {
	Use-Framework Framework\v2.0.50727 MSBuild {
		$version = exec { MSBuild /version /nologo }
		$version
		assert ($version -like '2.0.*')
	}
}

# This task calls MSBuild 4.0 and tests its version. It also shows a subtle
# scope issue and technique. Both Use-Framework and exec are dot-sourced.
# This is needed because $version is created in the exec block inside the
# Use-Framework block and then used outside of both. If any of two dots is
# removed then $version does not exists outside of the Use-Framework block.
task v4.0.30319 -If (Test-Path 'v4.0.30319') {
	. Use-Framework Framework\v4.0.30319 MSBuild {
		 . exec { $version = MSBuild /version /nologo }
	}
	$version
	assert ($version -like '4.0.*')
}

# In order to use the current framework pass $null or '':
task CurrentFramework {
	Use-Framework $null MSBuild {
		 exec { MSBuild /version /nologo }
	}
}

# This task fails due to invalid framework specified
task InvalidFramework {
	Use-Framework Framework\xyz MSBuild {}
}

# The default task calls the others and checks that InvalidFramework has failed properly.
# InvalidFramework is referenced as @{InvalidFramework=1} to ignore its errors.
task . v2.0.50727, v4.0.30319, CurrentFramework, @{InvalidFramework=1}, {
	$e = Get-Error InvalidFramework
	assert ("$e" -like "Directory does not exist: '*\xyz'.")
}