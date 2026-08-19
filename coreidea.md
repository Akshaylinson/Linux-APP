You are a senior Flutter desktop engineer and Linux systems engineer.

Build a production-quality Linux desktop application called:

    Linux System Dashboard

The application is a LOCAL-ONLY native Flutter desktop utility for Ubuntu/Linux.

The primary purpose is to give the user a beautiful, modern dashboard showing:

- Disk/storage information
- Physical disks
- Partitions
- Filesystem usage
- Folder usage
- CPU
- RAM
- GPU
- Temperature
- Battery
- Network
- Docker
- System information

IMPORTANT:

This is NOT a web application.

This is NOT a client-server application.

This is NOT a Flutter web application.

This does NOT require a backend server.

This does NOT require Docker.

This does NOT require a database.

The application runs entirely on the user's Linux laptop.

Flutter provides the UI.

Linux system interfaces, procfs, sysfs and safe system commands provide the data.

============================================================
1. CORE ARCHITECTURE
============================================================

Use this architecture:

Flutter UI
    ↓
Presentation layer
    ↓
Application/service layer
    ↓
Linux system information providers
    ↓
Linux OS

For Docker:

Flutter UI
    ↓
DockerService
    ↓
Docker CLI / Docker socket
    ↓
Docker daemon

Do NOT create a backend server.

Do NOT create a REST API.

Do NOT create a localhost HTTP server.

Do NOT create a database unless it becomes absolutely necessary.

The application should work completely offline.

============================================================
2. TARGET PLATFORM
============================================================

Primary target:

    Linux desktop
    Ubuntu 24.04 LTS or newer

Flutter:

    Latest stable Flutter version compatible with Ubuntu Linux desktop.

Architecture:

    x86_64 / amd64

The application should also be designed so ARM64 support can be added later.

============================================================
3. TECHNOLOGY STACK
============================================================

Use:

- Flutter
- Dart
- Material 3
- Linux desktop support
- Riverpod for state management

Prefer packages that are actively maintained.

Do NOT introduce unnecessary dependencies.

For Linux-specific functionality, use:

1. Dart packages where reliable.
2. Process execution for read-only Linux utilities.
3. FFI only when necessary.
4. Direct /proc and /sys reading where appropriate.

Keep Linux-specific code isolated from the Flutter UI.

============================================================
4. PROJECT STRUCTURE
============================================================

Create a clean architecture similar to:

lib/

    main.dart

    app/
        app.dart
        theme/
            app_theme.dart

    core/
        constants/
        errors/
        utils/

    models/
        disk_info.dart
        partition_info.dart
        filesystem_info.dart
        folder_usage.dart
        cpu_info.dart
        memory_info.dart
        gpu_info.dart
        temperature_info.dart
        battery_info.dart
        network_info.dart
        docker_info.dart
        system_info.dart

    services/
        storage_service.dart
        system_service.dart
        cpu_service.dart
        memory_service.dart
        gpu_service.dart
        temperature_service.dart
        battery_service.dart
        network_service.dart
        docker_service.dart

    platform/
        linux/
            linux_command_runner.dart
            linux_proc_reader.dart
            linux_sys_reader.dart
            linux_storage_provider.dart
            linux_system_provider.dart
            linux_docker_provider.dart

    providers/
        storage_provider.dart
        system_provider.dart
        docker_provider.dart
        monitoring_provider.dart

    screens/
        dashboard/
            dashboard_screen.dart

        storage/
            storage_screen.dart

        docker/
            docker_screen.dart

        system/
            system_screen.dart

        settings/
            settings_screen.dart

    widgets/
        cards/
        charts/
        storage/
        docker/
        system/
        common/

test/

linux/

assets/

============================================================
5. APPLICATION UI
============================================================

The UI should feel like a modern professional Linux system utility.

Do NOT make it look like a generic Flutter demo.

Use:

- Material 3
- dark/light theme
- rounded cards
- subtle borders
- clean typography
- compact information hierarchy
- smooth animations
- responsive desktop layout

Default theme:

    Dark

Allow:

    Light
    Dark
    System

Use a left navigation rail/sidebar.

Navigation:

    Dashboard
    Storage
    Docker
    System
    Network
    Settings

============================================================
6. DASHBOARD
============================================================

The main Dashboard should show a high-level overview.

Top section:

    CPU
    RAM
    Storage
    Temperature

Example:

    CPU
    17%

    MEMORY
    8.2 GB / 16 GB

    STORAGE
    423 GB / 1 TB

    TEMPERATURE
    43°C

Below that:

    Storage Overview
    Docker Overview
    System Information
    Network Activity

The dashboard should refresh automatically.

Default refresh interval:

    2 seconds

Allow the user to change it:

    1 sec
    2 sec
    5 sec
    10 sec
    Manual

Do not excessively poll the filesystem.

============================================================
7. STORAGE MODULE
============================================================

This is one of the most important modules.

Display:

Physical disks:

    /dev/nvme0n1
    /dev/sda
    etc.

For each physical disk show:

    Model
    Device
    Size
    Type
    Interface
    Temperature if available

Example:

    Samsung SSD 980
    /dev/nvme0n1
    1 TB
    NVMe

Then show partitions.

Example:

    /dev/nvme0n1p1
    EFI
    512 MB

    /dev/nvme0n1p2
    /
    932 GB

Use Linux commands such as:

    lsblk

    df

    findmnt

Use appropriate flags that make output machine-readable.

Prefer:

    lsblk --json

when available.

============================================================
8. FILESYSTEM USAGE
============================================================

For mounted filesystems display:

    Mount point
    Total
    Used
    Available
    Usage %

Example:

    /
    932 GB

    Used:
    351 GB

    Available:
    581 GB

    37.7%

Show a visual progress bar.

Ignore pseudo filesystems such as:

    /proc
    /sys
    /dev
    /run

unless explicitly requested.

Avoid counting temporary filesystems as user storage.

============================================================
9. DIRECTORY USAGE
============================================================

Provide a "Storage Explorer" section.

Allow the user to select:

    /
    /home
    ~/Downloads
    ~/Documents
    ~/Projects

Show largest directories.

Example:

    Projects       48.2 GB
    Downloads      21.4 GB
    .cache         12.8 GB
    Documents       8.4 GB

Use safe filesystem traversal.

Do NOT recursively scan the entire root filesystem every few seconds.

Directory scans should be:

    user initiated

or cached.

Display:

    scanning...
    
while scanning.

Handle:

    permission denied
    symbolic links
    inaccessible directories

without crashing.

Never follow symlink loops.

============================================================
10. DOCKER MODULE
============================================================

Docker is extremely important for this user.

The application should detect whether Docker is installed.

Possible states:

    Docker Running
    Docker Installed but Stopped
    Docker Not Installed
    Docker Permission Denied

Do NOT require Docker to be installed.

If Docker exists, display:

    Running Containers
    Images
    Volumes
    Build Cache
    Docker Disk Usage

Use:

    docker info

    docker ps

    docker images

    docker volume ls

    docker system df

Do NOT continuously execute expensive Docker commands.

Cache appropriate results.

============================================================
11. DOCKER DASHBOARD
============================================================

Display a card:

    Docker

    Containers       7
    Running          3
    Stopped          4

    Images           12
    Volumes           8
    Disk Usage      24.6 GB

Then show running containers:

    codevoice-api
    codevoice-redis
    postgres
    frontend

For each:

    Name
    Image
    Status
    CPU
    Memory
    Ports

If feasible use:

    docker stats --no-stream

for resource information.

Never leave a continuous docker stats process running unnecessarily.

============================================================
12. DOCKER CLEANUP
============================================================

Provide a SAFE cleanup interface.

Examples:

    Reclaim unused build cache
    Remove stopped containers
    Remove unused images
    Remove unused volumes

IMPORTANT:

Never execute destructive Docker commands immediately.

Always show:

    What will be removed
    Estimated space recovered

Then require explicit confirmation.

Never automatically delete:

    running containers
    active volumes
    currently used images

============================================================
13. CPU MODULE
============================================================

Display:

    CPU usage
    CPU model
    Core count
    Thread count
    Frequency if available

Use Linux sources such as:

    /proc/stat

    /proc/cpuinfo

or appropriate system utilities.

CPU usage must be calculated from intervals rather than simply displaying a static value.

Show:

    Overall CPU %

and optionally:

    Per-core CPU %

Use a lightweight implementation.

============================================================
14. MEMORY MODULE
============================================================

Read:

    /proc/meminfo

Display:

    Total RAM
    Used RAM
    Available RAM
    Cached
    Swap
    Swap usage

Example:

    RAM

    16 GB total
    8.3 GB used
    7.7 GB available

Show a percentage indicator.

============================================================
15. GPU MODULE
============================================================

Detect GPU where possible.

Support:

    NVIDIA
    AMD
    Intel

If NVIDIA tools are available:

    nvidia-smi

Use it safely.

If NVIDIA is unavailable, do not show an error.

Instead show:

    GPU detected through PCI/system information

or:

    GPU information unavailable

Never assume NVIDIA.

============================================================
16. TEMPERATURE MODULE
============================================================

Read Linux hardware sensors where available.

Possible source:

    /sys/class/thermal/

Also support:

    lm-sensors

if installed.

Display:

    CPU temperature
    GPU temperature
    NVMe temperature
    Other relevant sensors

Do not crash if sensors are unavailable.

Use:

    N/A

instead.

============================================================
17. BATTERY MODULE
============================================================

If the machine has a battery:

Display:

    Battery %
    Charging / Discharging
    Estimated status
    Battery health if available

Read from:

    /sys/class/power_supply/

If desktop:

    hide battery information

or show:

    No battery detected

============================================================
18. NETWORK MODULE
============================================================

Display:

    Active interface
    IP address
    Link state
    Download speed
    Upload speed

Example:

    Wi-Fi
    Connected

    ↓ 12.4 MB/s
    ↑ 1.8 MB/s

Read network statistics from Linux.

Do not require internet access to calculate traffic statistics.

============================================================
19. SYSTEM INFORMATION
============================================================

Display:

    OS
    Ubuntu version
    Kernel version
    Architecture
    Hostname
    Uptime
    Desktop environment

Example:

    Ubuntu 24.04 LTS
    Linux 6.x
    x86_64
    GNOME
    Uptime: 3h 42m

============================================================
20. PROCESS INFORMATION
============================================================

Add an optional process view.

Display:

    Top CPU processes
    Top memory processes

Example:

    Process       CPU       RAM

    chrome        18%       1.8 GB
    code           7%       1.2 GB
    docker         4%       600 MB

Do not implement a full task manager initially.

Keep this lightweight.

============================================================
21. ALERTS
============================================================

Create local warnings.

Examples:

    Storage > 80%
    Storage > 90%

    RAM > 90%

    CPU temperature > configured threshold

    Disk nearly full

    Docker disk usage unusually high

Use non-intrusive UI notifications.

Do not create desktop notifications initially unless necessary.

============================================================
22. SETTINGS
============================================================

Settings should include:

    Theme
        System
        Light
        Dark

    Refresh interval
        1 sec
        2 sec
        5 sec
        10 sec
        Manual

    Temperature unit
        Celsius
        Fahrenheit

    Storage scan behavior

    Docker monitoring
        Enabled / Disabled

    Start minimized
        optional

Persist settings locally.

Use a simple local configuration mechanism.

Do NOT introduce SQLite just for settings.

============================================================
23. ERROR HANDLING
============================================================

This application must NEVER crash simply because a Linux command is unavailable.

Example:

    docker command not found

should result in:

    Docker not installed

not:

    Application crash

Similarly:

    nvidia-smi unavailable

should result in:

    NVIDIA GPU metrics unavailable

Handle:

    Permission denied
    Command not found
    Timeout
    Invalid output
    Missing /proc files
    Missing /sys files
    Hardware without sensors

Use typed error states.

============================================================
24. SECURITY
============================================================

The application should operate with normal user privileges.

DO NOT recommend:

    sudo flutter run

DO NOT run the application as root.

DO NOT execute arbitrary shell commands supplied by the user.

All commands must be hardcoded and validated.

Use Process.run safely.

Do not use:

    shell: true

for user-controlled input.

Never expose:

    passwords
    SSH keys
    environment secrets
    tokens

============================================================
25. DOCKER PERMISSIONS
============================================================

The application should work with normal Docker group access.

If the current user cannot access:

    /var/run/docker.sock

display:

    Docker permission unavailable.

Explain:

    Add your user to the docker group.

Do NOT automatically modify system permissions.

============================================================
26. PERFORMANCE
============================================================

Performance is extremely important.

The dashboard must remain lightweight.

Avoid:

    continuous full filesystem scans
    repeated expensive shell commands
    unnecessary widget rebuilds

Use:

    caching
    timers
    providers
    isolated refresh mechanisms

CPU/RAM:

    refresh every 1–2 seconds

Storage:

    refresh every 5–10 seconds

Directory analysis:

    manual

Docker:

    5–10 seconds

Hardware information:

    10–30 seconds

============================================================
27. RESPONSIVE UI
============================================================

The application is designed for laptop/desktop screens.

Support:

    1280x720
    1366x768
    1920x1080
    ultrawide

Do not create a mobile UI.

Use responsive layouts.

============================================================
28. VISUAL DESIGN
============================================================

Design language:

    Professional
    Minimal
    Technical
    Modern
    Clean

Avoid:

    excessive gradients
    excessive animations
    giant icons
    childish colors
    unnecessary glassmorphism

Use subtle visual hierarchy.

Cards should have:

    title
    primary value
    secondary information
    small status indicator

Use charts only where useful.

Examples:

    CPU history
    RAM history
    Network traffic
    Storage usage

Charts should show a short rolling history.

For example:

    last 60 seconds

============================================================
29. APPLICATION NAME
============================================================

Use:

    SystemLens

Full name:

    SystemLens — Linux System Dashboard

Create a professional application icon.

The icon should represent:

    Linux/system monitoring
    storage
    hardware

Do not use the official Ubuntu logo.

============================================================
30. APP LAUNCHER
============================================================

Configure Linux desktop integration.

The application should appear in the Ubuntu application launcher.

Create:

    .desktop

configuration.

Set:

    Name=SystemLens
    Comment=Linux system monitoring dashboard

Configure an application icon.

============================================================
31. BUILD OUTPUT
============================================================

The project must support:

    flutter run -d linux

and:

    flutter build linux --release

The final release should produce a Linux executable.

Also provide a convenient packaging strategy.

Preferred:

    .deb

Secondary:

    AppImage

Do not make packaging the first development milestone.

============================================================
32. DEVELOPMENT PHASES
============================================================

Implement in phases.

PHASE 1:

Create Flutter Linux project.

Implement:

    App shell
    Navigation
    Theme
    Dashboard layout

Use mock data initially.

Make the UI beautiful.

PHASE 2:

Implement real:

    CPU
    RAM
    OS
    uptime

PHASE 3:

Implement:

    disks
    partitions
    filesystem usage

PHASE 4:

Implement:

    directory analysis

PHASE 5:

Implement:

    Docker detection
    Docker containers
    Docker images
    Docker volumes
    Docker disk usage

PHASE 6:

Implement:

    GPU
    temperature
    battery

PHASE 7:

Implement:

    network monitoring
    process monitoring

PHASE 8:

Implement:

    alerts
    settings
    persistence

PHASE 9:

Implement:

    application icon
    .desktop integration
    release build

PHASE 10:

Package as:

    .deb

============================================================
33. IMPORTANT DEVELOPMENT RULE
============================================================

Do not attempt to implement everything in one giant file.

Keep each Linux data source isolated.

For example:

StorageService
    ↓
LinuxStorageProvider

MemoryService
    ↓
LinuxMemoryProvider

DockerService
    ↓
LinuxDockerProvider

This is extremely important because the project may later support:

    Windows
    macOS

without rewriting the UI.

============================================================
34. TESTING
============================================================

Create tests for parsers.

Examples:

    lsblk JSON parser
    df parser
    /proc/meminfo parser
    /proc/stat CPU parser
    Docker output parser

Test error conditions.

Examples:

    empty output
    malformed output
    command unavailable
    permission denied

Do not require actual hardware in unit tests.

Use mocks for Linux commands.

============================================================
35. FINAL UX
============================================================

When the user launches SystemLens:

    Application opens.

    Within approximately 1 second:

        CPU
        RAM
        Storage
        OS

    should appear.

    Docker information should appear if Docker is installed.

    Hardware information should gracefully appear when available.

The user should not need:

    terminal
    sudo
    Docker
    browser
    server

to use the dashboard.

============================================================
36. FIRST-RUN EXPERIENCE
============================================================

On first launch:

    Detect system.

Show:

    Welcome to SystemLens

Then automatically detect:

    CPU
    RAM
    storage
    GPU
    battery
    Docker
    sensors

Do not ask unnecessary questions.

If something is unavailable:

    simply mark it unavailable.

============================================================
37. IMPORTANT FOR THIS USER
============================================================

The user is a software developer who uses Docker extensively.

Therefore Docker monitoring must be treated as a first-class feature.

The user commonly runs projects using:

    docker compose up
    docker compose build
    docker compose down

The application should make it easy to understand why Docker may be consuming disk/RAM.

Especially show:

    Docker disk usage
    container count
    image count
    volume usage
    build cache
    running container resource usage

The application is intended to help the user understand the local development machine.

============================================================
38. DO NOT OVERENGINEER
============================================================

Do not create:

    backend server
    REST API
    GraphQL
    authentication
    cloud database
    Firebase
    Redis
    PostgreSQL
    Docker Compose
    Kubernetes

This is a LOCAL DESKTOP APPLICATION.

============================================================
39. DOCUMENTATION
============================================================

Create:

    README.md

Include:

    Requirements
    Flutter installation
    Linux dependencies
    Development commands
    Running the application
    Building release
    Packaging
    Architecture
    Linux data sources
    Permission requirements
    Troubleshooting

Also create:

    docs/architecture.md

Explain the architecture.

============================================================
40. REQUIRED COMMANDS
============================================================

The final README must include commands such as:

    flutter pub get

    flutter run -d linux

    flutter analyze

    flutter test

    flutter build linux --release

Do not assume Docker is needed to build or run this application.

============================================================
41. FINAL QUALITY BAR
============================================================

Before declaring the project complete:

Run:

    flutter analyze

    flutter test

    flutter build linux --release

Fix all analyzer errors.

Fix all warnings that are caused by our code.

Verify:

    application launches

    navigation works

    dashboard loads

    storage information is accurate

    Docker detection works

    missing Docker does not crash application

    missing GPU tools do not crash application

    missing sensors do not crash application

    permission errors are handled

    dark/light themes work

    refresh works

    application can run without sudo

============================================================
42. START NOW
============================================================

Start by creating the complete Flutter Linux project.

Do NOT begin by implementing every feature.

First:

1. Inspect the development environment.
2. Verify Flutter Linux support.
3. Create the project.
4. Configure dependencies.
5. Create the architecture.
6. Build the application shell.
7. Implement the Dashboard UI with realistic mock data.
8. Run it on Linux.
9. Verify the UI.
10. Then progressively replace mock data with real Linux data providers.

After each phase:

    run flutter analyze

    run tests

    run the application

Do not move forward while the previous phase is broken.

The final result should feel like a real Linux desktop application, not a tutorial project.