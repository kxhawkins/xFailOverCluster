$script:DSCModuleName = 'xFailOverCluster'
$script:DSCResourceName = 'MSFT_xClusterNetwork'

#region Header

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion Header

function Invoke-TestSetup
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ModuleVersion
    )

    Import-Module -Name (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'Unit') -ChildPath 'Stubs') -ChildPath "FailoverClusters$ModuleVersion.stubs.psm1") -Global -Force
    $global:moduleVersion = $ModuleVersion
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    Remove-Variable -Name moduleVersion -Scope Global
}

# Begin Testing
try
{
    foreach ($moduleVersion in @('2012', '2016'))
    {
        Invoke-TestSetup -ModuleVersion $moduleVersion

        InModuleScope $script:DSCResourceName {
            $mockPresentClusterNetworkName = 'Client1'
            $mockPresentClusterNetworkAddress = '10.0.0.0'
            $mockPresentClusterNetworkAddressMask = '255.255.255.0'
            $mockPresentClusterNetworkRole = [System.UInt32] 1
            $mockPresentClusterNetworkRole2 = [PSCustomObject] @{ value__ = 1 }
            $mockPresentClusterNetworkMetric = '70240'

            $mockAbsentClusterNetworkName = 'Client2'
            $mockAbsentClusterNetworkAddress = '10.0.0.0'
            $mockAbsentClusterNetworkAddressMask = '255.255.255.0'
            $mockAbsentClusterNetworkRole = [System.UInt32] 3
            $mockAbsentClusterNetworkMetric = '10'

            if ($moduleVersion -eq '2012')
            {
                $mockGetClusterNetwork = {
                    [PSCustomObject] @{
                        Cluster     = 'CLUSTER01'
                        Name        = $mockPresentClusterNetworkName
                        Address     = $mockPresentClusterNetworkAddress
                        AddressMask = $mockPresentClusterNetworkAddressMask
                        Role        = $mockPresentClusterNetworkRole
                        Metric      = $mockPresentClusterNetworkMetric
                    }
                }

                $mockGetClusterNetwork2 = {
                    [PSCustomObject] @{
                        Cluster     = 'CLUSTER01'
                        Name        = $mockPresentClusterNetworkName
                        Address     = $mockPresentClusterNetworkAddress
                        AddressMask = $mockPresentClusterNetworkAddressMask
                        Role        = $mockPresentClusterNetworkRole2
                        Metric      = $mockPresentClusterNetworkMetric
                    }
                }
            }
            else
            {
                $mockGetClusterNetwork = {
                    [PSCustomObject] @{
                        Cluster     = 'CLUSTER01'
                        Name        = $mockPresentClusterNetworkName
                        Address     = $mockPresentClusterNetworkAddress
                        AddressMask = $mockPresentClusterNetworkAddressMask
                        Role        = $mockPresentClusterNetworkRole
                        Metric      = $mockPresentClusterNetworkMetric
                    } | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $script:mockNumberOfTimesMockedMethodUpdateWasCalled += 1
                    } -PassThru
                }

                $mockGetClusterNetwork2 = {
                    [PSCustomObject] @{
                        Cluster     = 'CLUSTER01'
                        Name        = $mockPresentClusterNetworkName
                        Address     = $mockPresentClusterNetworkAddress
                        AddressMask = $mockPresentClusterNetworkAddressMask
                        Role        = $mockPresentClusterNetworkRole2
                        Metric      = $mockPresentClusterNetworkMetric
                    } | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $script:mockNumberOfTimesMockedMethodUpdateWasCalled += 1
                    } -PassThru
                }
            }

            $mockTestParameters_PresentNetwork = @{
                Address     = $mockPresentClusterNetworkAddress
                AddressMask = $mockPresentClusterNetworkAddressMask
                Name        = $mockPresentClusterNetworkName
                Role        = $mockPresentClusterNetworkRole
                Metric      = $mockPresentClusterNetworkMetric
            }

            $mockTestParameters_PresentNetwork_WrongValues = @{
                Address     = $mockPresentClusterNetworkAddress
                AddressMask = $mockPresentClusterNetworkAddressMask
                Name        = $mockAbsentClusterNetworkName
                Role        = $mockAbsentClusterNetworkRole
                Metric      = $mockAbsentClusterNetworkMetric
            }

            Describe "xClusterNetwork_$moduleVersion\Get-TargetResource" {
                Mock -CommandName 'Get-ClusterNetwork' -MockWith $mockGetClusterNetwork

                Context 'When the system is not in the desired state' {
                    BeforeAll {
                        $mockTestParameters = $mockTestParameters_PresentNetwork_WrongValues.Clone()
                        $mockTestParameters.Remove('Name')
                        $mockTestParameters.Remove('Role')
                        $mockTestParameters.Remove('Metric')
                    }

                    It 'Should return the correct type' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters
                        $getTargetResourceResult | Should -BeOfType [System.Collections.Hashtable]
                    }

                    It 'Should return the same values passed as parameters' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters
                        $getTargetResourceResult.Address      | Should -Be $mockTestParameters.Address
                        $getTargetResourceResult.AddressMask  | Should -Be $mockTestParameters.AddressMask
                    }

                    It 'Should not return the the correct values for the cluster network' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters
                        $getTargetResourceResult.Name         | Should -Not -Be $mockAbsentClusterNetworkName
                        $getTargetResourceResult.Role         | Should -Not -Be $mockAbsentClusterNetworkRole
                        $getTargetResourceResult.Metric       | Should -Not -Be $mockAbsentClusterNetworkMetric

                        Assert-MockCalled -CommandName Get-ClusterNetwork -Exactly -Times 1 -Scope It
                    }

                    It 'Should not return the the correct values for the cluster network role on WS2016' {
                        Mock -CommandName 'Get-ClusterNetwork' -MockWith $mockGetClusterNetwork2

                        $getTargetResourceResult = Get-TargetResource @mockTestParameters
                        $getTargetResourceResult.Name         | Should -Not -Be $mockAbsentClusterNetworkName
                        $getTargetResourceResult.Role         | Should -Not -Be $mockAbsentClusterNetworkRole
                        $getTargetResourceResult.Metric       | Should -Not -Be $mockAbsentClusterNetworkMetric

                        Assert-MockCalled -CommandName Get-ClusterNetwork -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the system is in the desired state' {
                    BeforeAll {
                        $mockTestParameters = $mockTestParameters_PresentNetwork.Clone()
                        $mockTestParameters.Remove('Name')
                        $mockTestParameters.Remove('Role')
                        $mockTestParameters.Remove('Metric')
                    }

                    It 'Should return the correct type' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters
                        $getTargetResourceResult | Should -BeOfType [System.Collections.Hashtable]
                    }

                    It 'Should return the same values passed as parameters' {
                        $Result = Get-TargetResource @mockTestParameters
                        $Result.Address      | Should -Be $mockTestParameters.Address
                        $Result.AddressMask  | Should -Be $mockTestParameters.AddressMask
                    }

                    It 'Should return the the correct values for the cluster network' {
                        $Result = Get-TargetResource @mockTestParameters
                        $Result.Name         | Should -Be $mockPresentClusterNetworkName
                        $Result.Role         | Should -Be $mockPresentClusterNetworkRole
                        $Result.Metric       | Should -Be $mockPresentClusterNetworkMetric

                        Assert-MockCalled -CommandName Get-ClusterNetwork -Exactly -Times 1 -Scope It
                    }

                    It 'Should return the the correct values for the cluster network role on WS2016' {
                        Mock -CommandName 'Get-ClusterNetwork' -MockWith $mockGetClusterNetwork2

                        $Result = Get-TargetResource @mockTestParameters
                        $Result.Name         | Should -Be $mockPresentClusterNetworkName
                        $Result.Role         | Should -Be $mockPresentClusterNetworkRole
                        $Result.Metric       | Should -Be $mockPresentClusterNetworkMetric

                        Assert-MockCalled -CommandName Get-ClusterNetwork -Exactly -Times 1 -Scope It
                    }
                }
            }
            Describe "xClusterNetwork_$moduleVersion\Test-TargetResource" {
                Mock -CommandName 'Get-ClusterNetwork' -MockWith $mockGetClusterNetwork

                Context 'When the system is not in the desired state' {
                    Context 'When all supported properties is not in desired state' {
                        BeforeAll {
                            $mockTestParameters = $mockTestParameters_PresentNetwork_WrongValues
                        }

                        It 'Should return result as $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should -Be $false
                        }
                    }

                    Context 'When all Name property is not in desired state' {
                        BeforeAll {
                            $mockTestParameters = $mockTestParameters_PresentNetwork.Clone()
                            $mockTestParameters.Name = $mockAbsentClusterNetworkName
                        }

                        It 'Should return result as $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should -Be $false
                        }
                    }

                    Context 'When all Role property is not in desired state' {
                        BeforeAll {
                            $mockTestParameters = $mockTestParameters_PresentNetwork.Clone()
                            $mockTestParameters.Role = $mockAbsentClusterNetworkRole
                        }

                        It 'Should return result as $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should -Be $false
                        }
                    }

                    Context 'When all Metric property is not in desired state' {
                        BeforeAll {
                            $mockTestParameters = $mockTestParameters_PresentNetwork.Clone()
                            $mockTestParameters.Metric = $mockAbsentClusterNetworkMetric
                        }

                        It 'Should return result as $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should -Be $false
                        }
                    }
                }

                Context 'When the system is in the desired state' {
                    BeforeAll {
                        $mockTestParameters = $mockTestParameters_PresentNetwork
                    }

                    It 'Should return result as $true' {
                        $testTargetResourceResult = Test-TargetResource @mockTestParameters
                        $testTargetResourceResult | Should -Be $true
                    }
                }
            }

            Describe "xClusterNetwork_$moduleVersion\Set-TargetResource" {
                Mock -CommandName 'Get-ClusterNetwork' -MockWith $mockGetClusterNetwork

                Context 'When the system is not in the desired state' {
                    BeforeEach {
                        $script:mockNumberOfTimesMockedMethodUpdateWasCalled = 0
                    }

                    Context 'When all supported properties is not in desired state' {
                        BeforeAll {
                            $mockTestParameters = $mockTestParameters_PresentNetwork_WrongValues
                        }

                        It 'Should call Update method correct number of times' {
                            if ($moduleVersion -eq '2012')
                            {
                                $expectedNumberOfTimesMockedMethodUpdateShouldBeCalled = 0
                            }
                            else
                            {
                                $expectedNumberOfTimesMockedMethodUpdateShouldBeCalled = 3
                            }

                            { Set-TargetResource @mockTestParameters } | Should -Not -Throw
                            $script:mockNumberOfTimesMockedMethodUpdateWasCalled | Should -BeExactly $expectedNumberOfTimesMockedMethodUpdateShouldBeCalled
                        }
                    }

                    Context 'When all Name property is not in desired state' {
                        BeforeAll {
                            $mockTestParameters = $mockTestParameters_PresentNetwork.Clone()
                            $mockTestParameters.Name = $mockAbsentClusterNetworkName
                        }

                        It 'Should call Update method correct number of times' {
                            if ($moduleVersion -eq '2012') {
                                $expectedNumberOfTimesMockedMethodUpdateShouldBeCalled = 0
                            } else {
                                $expectedNumberOfTimesMockedMethodUpdateShouldBeCalled = 1
                            }

                            { Set-TargetResource @mockTestParameters } | Should -Not -Throw
                            $script:mockNumberOfTimesMockedMethodUpdateWasCalled | Should -BeExactly $expectedNumberOfTimesMockedMethodUpdateShouldBeCalled
                        }
                    }

                    Context 'When all Role property is not in desired state' {
                        BeforeAll {
                            $mockTestParameters = $mockTestParameters_PresentNetwork.Clone()
                            $mockTestParameters.Role = $mockAbsentClusterNetworkRole
                        }

                        It 'Should call Update method correct number of times' {
                            if ($moduleVersion -eq '2012') {
                                $expectedNumberOfTimesMockedMethodUpdateShouldBeCalled = 0
                            } else {
                                $expectedNumberOfTimesMockedMethodUpdateShouldBeCalled = 1
                            }

                            { Set-TargetResource @mockTestParameters } | Should -Not -Throw
                            $script:mockNumberOfTimesMockedMethodUpdateWasCalled | Should -BeExactly $expectedNumberOfTimesMockedMethodUpdateShouldBeCalled
                        }
                    }

                    Context 'When all Metric property is not in desired state' {
                        BeforeAll {
                            $mockTestParameters = $mockTestParameters_PresentNetwork.Clone()
                            $mockTestParameters.Metric = $mockAbsentClusterNetworkMetric
                        }

                        It 'Should call Update method correct number of times' {
                            if ($moduleVersion -eq '2012') {
                                $expectedNumberOfTimesMockedMethodUpdateShouldBeCalled = 0
                            } else {
                                $expectedNumberOfTimesMockedMethodUpdateShouldBeCalled = 1
                            }

                            { Set-TargetResource @mockTestParameters } | Should -Not -Throw
                            $script:mockNumberOfTimesMockedMethodUpdateWasCalled | Should -BeExactly $expectedNumberOfTimesMockedMethodUpdateShouldBeCalled
                        }
                    }
                }

                Context 'When the system is in the desired state' {
                    BeforeAll {
                        $mockTestParameters = $mockTestParameters_PresentNetwork
                    }

                    BeforeEach {
                        $script:mockNumberOfTimesMockedMethodUpdateWasCalled = 0
                    }

                    It 'Should call Update method correct number of times' {
                        { Set-TargetResource @mockTestParameters } | Should -Not -Throw
                        $script:mockNumberOfTimesMockedMethodUpdateWasCalled | Should -BeExactly 0
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
