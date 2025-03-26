# Main DSC Configuration
Configuration VMSoftwareConfig {
    # Import required DSC Resources
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xChocolatey
    Import-DscResource -ModuleName xSystemSecurity

    # Node configuration
    Node 'localhost' {
        # Environment setup
        xSystemSecurity SecuritySettings {
            EnableUAC = $false
        }

        # Install Chocolatey
        xChocolateyInstaller Chocolatey {
            InstallDir = 'C:\ProgramData\chocolatey'
        }

        # Install Java
        xChocolateyPackage Java {
            Name = 'temurin17'
            Ensure = 'Present'
            DependsOn = '[xChocolateyInstaller]Chocolatey'
        }

        # Install PostgreSQL
        xChocolateyPackage PostgreSQL {
            Name = 'postgresql15'
            Ensure = 'Present'
            DependsOn = '[xChocolateyInstaller]Chocolatey'
            Parameters = "/Password:$postgresPassword"
        }

        # Environment Variables
        Environment JavaHome {
            Name = 'JAVA_HOME'
            Value = 'C:\Program Files\Java\jdk-17'
            Ensure = 'Present'
            Path = $true
        }

        # Service Configuration
        Service PostgreSQLService {
            Name = 'postgresql-x64-15'
            State = 'Running'
            Ensure = 'Present'
        }
    }
}