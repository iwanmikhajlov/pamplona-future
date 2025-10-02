$ErrorActionPreference = 'Stop'

$host.UI.RawUI.WindowTitle = "Pamplona Future AIO"

$defaultGamePath = "C:\Program Files (x86)\Steam\steamapps\common\Mirrors Edge Catalyst"

function Read-KeyPress {
    param(
        [string]$Prompt = "",
        [switch]$ShowKey = $true,
        [switch]$UseVirtualKey = $false
    )

    if ($Prompt) {
        Write-Host $Prompt -NoNewline
    }

    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    if ($ShowKey) {
        Write-Host $key.Character
    } else {
        Write-Host ""
    }

    if ($UseVirtualKey) {

        if ($key.VirtualKeyCode -ge 49 -and $key.VirtualKeyCode -le 54) {
            return [char]$key.VirtualKeyCode
        }

        return $null
    }

    return $key.Character
}

function Invoke-DockerCommand {
    param($Command)
    try {
        Invoke-Expression $Command 2>&1 | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Test-ContainerExists {
    param($ContainerName)
    $exists = docker ps -a --filter "name=$ContainerName" --format "{{.Names}}" 2>$null
    return $exists -eq $ContainerName
}

function Test-ContainerRunning {
    param($ContainerName)
    $status = docker ps --filter "name=$ContainerName" --format "{{.Names}}" 2>$null
    return $status -eq $ContainerName
}

function Test-DockerAvailable {
    $dockerInstalled = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $dockerInstalled) {
        Write-Host "Error: Docker is not installed!" -ForegroundColor Red
        Write-Host "Please install Docker Desktop from https://www.docker.com/products/docker-desktop" -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to continue"
        return $false
    }

    try {
        docker ps 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw
        }
    } catch {
        Write-Host "Error: Docker is not running!" -ForegroundColor Red
        Write-Host "Please start Docker Desktop and try again." -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to continue"
        return $false
    }

    return $true
}

function Write-Centered {
    param(
        [string]$Text,
        [string]$ForegroundColor = "White"
    )
    $windowWidth = $host.UI.RawUI.WindowSize.Width
    $padding = [Math]::Max(0, [Math]::Floor(($windowWidth - $Text.Length) / 2))
    Write-Host (" " * $padding + $Text) -ForegroundColor $ForegroundColor
}

function Show-Menu {
    Clear-Host

    $windowWidth = $host.UI.RawUI.WindowSize.Width
    $windowHeight = $host.UI.RawUI.WindowSize.Height

    $menuLines = @(
        "╔═══════════════════════════════════════════════════╗",
        "║                                                   ║",
        "║                                                   ║",
        "║           P A M P L O N A   F U T U R E           ║",
        "║                                                   ║",
        "║                       A I O                       ║",
        "║                                                   ║",
        "║                                                   ║",
        "╠═══════════════════════════════════════════════════╣",
        "║                                                   ║",
        "║         [1] Install and start server              ║",
        "║                                                   ║",
        "║         [2] Check server status                   ║",
        "║                                                   ║",
        "║         [3] View server logs                      ║",
        "║                                                   ║",
        "║         [4] Stop and remove server                ║",
        "║                                                   ║",
        "║         [5] Credits                               ║",
        "║                                                   ║",
        "║         [6] Exit                                  ║",
        "║                                                   ║",
        "╚═══════════════════════════════════════════════════╝"
    )

    $menuHeight = $menuLines.Count
    $verticalOffset = [Math]::Max(0, [Math]::Floor(($windowHeight - $menuHeight - 3) / 2))

    for ($i = 0; $i -lt $verticalOffset; $i++) {
        Write-Host ""
    }

    $menuWidth = 55
    $horizontalOffset = [Math]::Max(0, [Math]::Floor(($windowWidth - $menuWidth) / 2))
    $padding = " " * $horizontalOffset

    foreach ($line in $menuLines) {
        if ($line -match "P A M P L O N A|A I O") {
            Write-Host ($padding + $line) -ForegroundColor Cyan
        } else {
            Write-Host ($padding + $line)
        }
    }

    Write-Host ""
    Write-Centered "Enter a menu option in the Keyboard [1,2,3,4,5,6]" -ForegroundColor Green
}


function Start-Server {
    Clear-Host
    Write-Host "=== Install and Start Server ===" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-DockerAvailable)) {
        return
    }

    Write-Host "Docker is installed and running." -ForegroundColor Green
    Write-Host ""

    if (Test-ContainerExists "pamplona-future") {
        Write-Host "Server is already installed!"
        Write-Host ""

        if (Test-ContainerRunning "pamplona-future") {
            Write-Host "Server is currently running." -ForegroundColor Green
            Write-Host ""
            Read-Host "Press Enter to continue"
            return
        } else {
            Write-Host "Server is not running. Starting..."
            docker start pamplona-future-db 2>$null
            docker start pamplona-future 2>$null
            Start-Sleep -Seconds 2
            Write-Host "Server started!" -ForegroundColor Green
            Write-Host ""
            Read-Host "Press Enter to continue"
            return
        }
    }

    Write-Host "Enter the full path to Mirror's Edge Catalyst folder" -ForegroundColor Cyan
    Write-Host "Press Enter to use default path:" -ForegroundColor Gray
    Write-Host $defaultGamePath -ForegroundColor Gray
    Write-Host ""
    $userInput = Read-Host "Game path (or press Enter for default)"

    if ([string]::IsNullOrWhiteSpace($userInput)) {
        $gamePath = $defaultGamePath
        Write-Host "Using default path: $gamePath"
    } else {
        $gamePath = $userInput
    }

    if (-not (Test-Path $gamePath)) {
        Write-Host ""
        Write-Host "Error: Path does not exist!" -ForegroundColor Red
        Write-Host "Path: $gamePath"
        Write-Host ""
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host ""
    Write-Host "Enter player name (default: Player)" -ForegroundColor Cyan
    $playerInput = Read-Host "Player name"

    if ([string]::IsNullOrWhiteSpace($playerInput)) {
        $personaUsername = "Player"
    } else {
        $personaUsername = $playerInput
    }
    Write-Host "Using player name: $personaUsername"

    $dbUser = "dbuser"
    $dbPassword = "dbpasswd"
    $dbName = "dbname"
    $gatewayPort = "3000"
    $blazePort = "25565"
    $hostname = "localhost"
    $userId = "2407107883"
    $personaId = "1011786733"

    Write-Host ""
    Write-Host "Do you want to customize advanced server settings? [y/N]: " -NoNewline -ForegroundColor Cyan
    $configChoice = Read-KeyPress -ShowKey:$true

    if ($configChoice -match '^[Yy]') {
        Clear-Host
        Write-Host "=== Advanced Server Configuration ===" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "Database Settings:" -ForegroundColor Yellow
        $input = Read-Host "Database username (default: $dbUser)"
        if (-not [string]::IsNullOrWhiteSpace($input)) { $dbUser = $input }

        $input = Read-Host "Database password (default: $dbPassword)"
        if (-not [string]::IsNullOrWhiteSpace($input)) { $dbPassword = $input }

        $input = Read-Host "Database name (default: $dbName)"
        if (-not [string]::IsNullOrWhiteSpace($input)) { $dbName = $input }

        Write-Host ""
        Write-Host "Server Settings:" -ForegroundColor Yellow
        $input = Read-Host "Gateway port (default: $gatewayPort)"
        if (-not [string]::IsNullOrWhiteSpace($input)) { $gatewayPort = $input }

        $input = Read-Host "Blaze port (default: $blazePort)"
        if (-not [string]::IsNullOrWhiteSpace($input)) { $blazePort = $input }

        $input = Read-Host "Hostname (default: $hostname)"
        if (-not [string]::IsNullOrWhiteSpace($input)) { $hostname = $input }

        Write-Host ""
        Write-Host "Player IDs:" -ForegroundColor Yellow
        $input = Read-Host "User ID (default: $userId)"
        if (-not [string]::IsNullOrWhiteSpace($input)) { $userId = $input }

        $input = Read-Host "Persona ID (default: $personaId)"
        if (-not [string]::IsNullOrWhiteSpace($input)) { $personaId = $input }

        Write-Host ""
        Write-Host "Configuration complete!" -ForegroundColor Green
        Write-Host ""
    }

    Write-Host "Creating network [pamplona-net]..."
    Invoke-DockerCommand "docker network create pamplona-net"

    Write-Host "Starting database [pamplona-future-db]..."
    $dbResult = docker run -d `
      --name pamplona-future-db `
      --restart unless-stopped `
      --network pamplona-net `
      -e POSTGRES_USER=$dbUser `
      -e POSTGRES_PASSWORD=$dbPassword `
      -e POSTGRES_DB=$dbName `
      postgres:17 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Failed to start database!" -ForegroundColor Red
        Write-Host "Error: $dbResult" -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host "Waiting for database to initialize..."
    Start-Sleep -Seconds 3

    Write-Host "Starting server [pamplona-future]..."
    $serverResult = docker run -d `
      --name pamplona-future `
      --restart unless-stopped `
      --network pamplona-net `
      -p "${gatewayPort}:3000" `
      -p "${blazePort}:25565" `
      -p 42230:42230 `
      -e GATEWAY_PORT=3000 `
      -e BLAZE_PORT=25565 `
      -e POSTGRES_USER=$dbUser `
      -e POSTGRES_PASSWORD=$dbPassword `
      -e POSTGRES_DB=$dbName `
      -e POSTGRES_HOSTNAME=pamplona-future-db `
      -e POSTGRES_PORT=5432 `
      -e HOSTNAME=$hostname `
      -e GAME_PATH=/mitm_volume `
      -e USER_ID=$userId `
      -e PERSONA_ID=$personaId `
      -e PERSONA_USERNAME=$personaUsername `
      -v "${gamePath}:/mitm_volume" `
      ghcr.io/iwanmikhajlov/pamplona-future-aio 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Failed to start server!" -ForegroundColor Red
        Write-Host "Error: $serverResult" -ForegroundColor Red
        Write-Host ""
        Write-Host "Cleaning up database container..."
        docker rm -f pamplona-future-db 2>$null
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host ""
    Write-Host "Waiting for server to start..."
    Start-Sleep -Seconds 5

    $serverRunning = Test-ContainerRunning "pamplona-future"
    $dbRunning = Test-ContainerRunning "pamplona-future-db"

    if ($serverRunning -and $dbRunning) {
        Write-Host "Server started successfully!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Something went wrong!" -ForegroundColor Red
        Write-Host ""

        if (-not $dbRunning) {
            Write-Host "[DATABASE] Failed to start" -ForegroundColor Red
            Write-Host "Last database logs:"
            docker logs --tail 20 pamplona-future-db
        }

        if (-not $serverRunning) {
            Write-Host "[SERVER] Failed to start" -ForegroundColor Red
            Write-Host "Last server logs:"
            docker logs --tail 20 pamplona-future
        }

        Write-Host ""
        Write-Host "Check logs above for more details." -ForegroundColor Red
    }

    Write-Host ""
    Read-Host "Press Enter to continue"
}


function Get-ServerStatus {
    Clear-Host
    Write-Host "=== Server Status ===" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-DockerAvailable)) {
        return
    }

    $serverRunning = Test-ContainerRunning "pamplona-future"
    $dbRunning = Test-ContainerRunning "pamplona-future-db"

    if ($serverRunning) {
        Write-Host "[SERVER] Running" -ForegroundColor Green
    } else {
        Write-Host "[SERVER] Not running" -ForegroundColor Red
    }

    if ($dbRunning) {
        Write-Host "[DATABASE] Running" -ForegroundColor Green
    } else {
        Write-Host "[DATABASE] Not running" -ForegroundColor Red
    }

    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Show-Logs {
    Clear-Host
    Write-Host "=== Server Logs (last 100 lines) ===" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-DockerAvailable)) {
        return
    }

    if (Test-ContainerRunning "pamplona-future") {
        docker logs --tail 100 pamplona-future
        Write-Host ""
        Read-Host "Press Enter to return to menu"
    } else {
        Write-Host "Server is not running!" -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to continue"
    }
}


function Stop-And-Remove-Server {
    Clear-Host
    Write-Host "=== Stop and Remove Server ===" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-DockerAvailable)) {
        return
    }

    if (-not (Test-ContainerExists "pamplona-future")) {
        Write-Host "Server is not installed!" -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host "Are you sure you want to stop and remove all containers and network? [y/N]: " -NoNewline
    $confirm = Read-KeyPress -ShowKey:$true

    if ($confirm -match '^[Yy]') {
        Write-Host ""
        Write-Host "Stopping containers..."
        docker stop pamplona-future 2>$null
        docker stop pamplona-future-db 2>$null

        Write-Host "Waiting for containers to stop completely..."
        Start-Sleep -Seconds 5

        Write-Host "Removing containers and network..."
        docker rm -f pamplona-future 2>$null
        docker rm -f pamplona-future-db 2>$null
        docker network rm pamplona-net 2>$null

        Write-Host "Server stopped and removed!" -ForegroundColor Green
    } else {
        Write-Host "Cancelled."
    }
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Show-Credits {
    Clear-Host
    Write-Host "=== Credits ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Pamplona Future Server" -ForegroundColor Green
    Write-Host ""
    Write-Host "Thanks to:"
    Write-Host "  - ploxxxy (core development)                   https://github.com/ploxxxy"
    Write-Host "  - iwanmikhajlov (dockerization and scripting)  https://github.com/iwanmikhajlov"
    Write-Host "  - DICE & EA (for shutting down servers, bruh)"
    Write-Host ""
    Read-Host "Press Enter to continue"
}

do {
    Show-Menu
    $choice = Read-KeyPress -ShowKey:$false -UseVirtualKey

    switch ($choice) {
        "1" { Start-Server }
        "2" { Get-ServerStatus }
        "3" { Show-Logs }
        "4" { Stop-And-Remove-Server }
        "5" { Show-Credits }
        "6" {
            Clear-Host
            Write-Host ""
            Write-Centered "Goodbye!" -ForegroundColor Cyan
            Write-Host ""
            Start-Sleep -Seconds 1
            exit
        }
    }
} while ($true)