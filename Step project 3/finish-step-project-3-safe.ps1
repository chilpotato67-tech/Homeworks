param(
    [string]$RepoRoot = "E:\Devops\Homeworks",
    [string]$ProjectName = "Step project 3",
    [string]$WorkerLabel = "worker1",
    [string]$SourceJenkinsfile = ""
)

$ErrorActionPreference = "Stop"
$nl = [Environment]::NewLine

function Say {
    param([string]$Text, [string]$Color = "Gray")
    Write-Host $Text -ForegroundColor $Color
}

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Say "Created: $Path" "Green"
    }
}

function Write-JoinedFile {
    param([string]$Path, [string[]]$Lines)
    $parent = Split-Path -Parent $Path
    if ($parent) { Ensure-Dir $parent }
    Set-Content -LiteralPath $Path -Value ($Lines -join $nl) -Encoding UTF8
    Say "Written: $Path" "Green"
}

function Move-ToTrash {
    param([string]$Path, [string]$TrashRoot)

    if (-not (Test-Path -LiteralPath $Path)) { return }

    try {
        $name = Split-Path -Leaf $Path
        $dest = Join-Path $TrashRoot $name

        if (Test-Path -LiteralPath $dest) {
            $dest = Join-Path $TrashRoot ($name + "_" + (Get-Date -Format "yyyyMMdd_HHmmssfff"))
        }

        Move-Item -LiteralPath $Path -Destination $dest -Force
        Say "Moved to trash: $Path" "Yellow"
    }
    catch {
        Say "Skip: $Path :: $($_.Exception.Message)" "Yellow"
    }
}

$ProjectRoot = Join-Path $RepoRoot $ProjectName
if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    throw "Project root not found: $ProjectRoot"
}

$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$TrashRoot = Join-Path $ProjectRoot ("_trash_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
Ensure-Dir $TrashRoot

Say "Project root: $ProjectRoot" "Cyan"

# 1. Structure
$dirs = @(
    "ansible\inventory",
    "ansible\playbooks",
    "ansible\templates",
    "jenkins",
    "screenshots\01-bucket",
    "screenshots\02-network",
    "screenshots\03-ec2",
    "screenshots\04-ansible",
    "screenshots\05-jenkins",
    "screenshots\06-pipeline",
    "screenshots\07-destroy",
    "terraform\bucket",
    "terraform\infrastructure"
)

foreach ($d in $dirs) {
    Ensure-Dir (Join-Path $ProjectRoot $d)
}

# 2. Move local junk
Get-ChildItem -Path $ProjectRoot -Recurse -Force -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -eq "terraform.tfvars" -or
        $_.Name -like "*.tfstate" -or
        $_.Name -like "*.tfstate.*"
    } |
    ForEach-Object {
        Move-ToTrash -Path $_.FullName -TrashRoot $TrashRoot
    }

Get-ChildItem -Path $ProjectRoot -Recurse -Force -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq ".terraform" } |
    ForEach-Object {
        Move-ToTrash -Path $_.FullName -TrashRoot $TrashRoot
    }

foreach ($junk in @("Set-Location", "git", "fix-step-project-3.ps1", "fix-step-project-3-mini.ps1", "finish-step-project-3.ps1")) {
    Move-ToTrash -Path (Join-Path $ProjectRoot $junk) -TrashRoot $TrashRoot
}

foreach ($keyName in @("pr1.pem", "pr1.pub")) {
    Move-ToTrash -Path (Join-Path $ProjectRoot $keyName) -TrashRoot $TrashRoot
}

# 3. If terraform/infrastructure/main.tf contains ansible inventory text, move it away
$infraMain = Join-Path $ProjectRoot "terraform\infrastructure\main.tf"
if (Test-Path -LiteralPath $infraMain) {
    $mainContent = Get-Content -LiteralPath $infraMain -Raw
    if (($mainContent -match "ansible_host=") -or ($mainContent -match "\[jenkins_master\]")) {
        Move-ToTrash -Path $infraMain -TrashRoot $TrashRoot
    }
}

# 4. Move screenshots from jenkins folder
$jenkinsDir = Join-Path $ProjectRoot "jenkins"
if (Test-Path -LiteralPath $jenkinsDir) {
    Get-ChildItem -Path $jenkinsDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '^\.(png|jpg|jpeg|webp)$' } |
        ForEach-Object {
            $destDir = if ($_.Name -match "pipeline|console|stage|jenkinsfile") {
                Join-Path $ProjectRoot "screenshots\06-pipeline"
            } else {
                Join-Path $ProjectRoot "screenshots\05-jenkins"
            }

            Ensure-Dir $destDir
            Move-Item -LiteralPath $_.FullName -Destination (Join-Path $destDir $_.Name) -Force
            Say "Moved screenshot: $($_.Name)" "Green"
        }
}

# 5. .gitignore
$gitignoreLines = @(
    "# Secrets",
    "*.pem",
    "*.key",
    "*.p12",
    "*.pfx",
    "*.pub",
    "",
    "# Terraform local files",
    "**/.terraform/*",
    "*.tfstate",
    "*.tfstate.*",
    "crash.log",
    "",
    "# Terraform variable files with secrets",
    "*.auto.tfvars",
    "terraform.tfvars",
    "terraform.tfvars.local",
    "secrets.tfvars",
    "",
    "# Local inventories",
    "ansible/inventory/inventory.ini",
    "",
    "# Local cleanup area",
    "_trash_*/",
    "",
    "# OS / editors",
    ".DS_Store",
    "Thumbs.db",
    ".vscode/",
    ".idea/"
)
Write-JoinedFile -Path (Join-Path $ProjectRoot ".gitignore") -Lines $gitignoreLines

# 6. Example files
$inventoryExampleLines = @(
    "[jenkins_master]",
    "master ansible_host=YOUR_MASTER_PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=/path/to/your-key.pem ansible_python_interpreter=/usr/bin/python3"
)
Write-JoinedFile -Path (Join-Path $ProjectRoot "ansible\inventory\inventory.ini.example") -Lines $inventoryExampleLines

$bucketTfvarsExampleLines = @(
    'bucket_name = "your-unique-tfstate-bucket-name"',
    'aws_region  = "eu-central-1"'
)
Write-JoinedFile -Path (Join-Path $ProjectRoot "terraform\bucket\terraform.tfvars.example") -Lines $bucketTfvarsExampleLines

$infraTfvarsExampleLines = @(
    'aws_region           = "eu-central-1"',
    'project_name         = "step-project-3"',
    'availability_zone    = "eu-central-1a"',
    'key_pair_name        = "your-keypair-name"',
    'public_key_path      = "../../keys/your-key.pub"',
    'master_instance_type = "t3.micro"',
    'worker_instance_type = "t3.micro"',
    'ami_id               = "ami-005f97cc4a61dd3b4"'
)
Write-JoinedFile -Path (Join-Path $ProjectRoot "terraform\infrastructure\terraform.tfvars.example") -Lines $infraTfvarsExampleLines

# 7. README
$readmePath = Join-Path $ProjectRoot "README.md"
$readmeLines = @(
    "# Step project 3",
    "",
    "## Structure",
    "- terraform/bucket",
    "- terraform/infrastructure",
    "- ansible/playbooks",
    "- ansible/templates",
    "- ansible/inventory",
    "- jenkins/Jenkinsfile",
    "- screenshots/",
    "",
    "## Flow",
    "1. Create S3 bucket for Terraform state",
    "2. Create AWS infrastructure",
    "3. Configure Jenkins master with Ansible",
    "4. Add Jenkins worker and run pipeline",
    "5. Destroy infrastructure",
    "",
    "## Jenkins pipeline path",
    "$ProjectName/jenkins/Jenkinsfile"
)

if (-not (Test-Path -LiteralPath $readmePath)) {
    Write-JoinedFile -Path $readmePath -Lines $readmeLines
} else {
    $readmeNow = Get-Content -LiteralPath $readmePath -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($readmeNow)) {
        Write-JoinedFile -Path $readmePath -Lines $readmeLines
    } else {
        Say "Keeping existing README.md" "Cyan"
    }
}

# 8. Copy Jenkinsfile from Step project 2 / RepoStep if found
$jenkinsCandidates = @(
    $SourceJenkinsfile,
    (Join-Path $RepoRoot "Step project 2\jenkins\Jenkinsfile"),
    (Join-Path $RepoRoot "Step project 2\Jenkinsfile"),
    (Join-Path $RepoRoot "RepoStep\Jenkinsfile")
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

$destJenkinsfile = Join-Path $ProjectRoot "jenkins\Jenkinsfile"

if ($jenkinsCandidates.Count -gt 0) {
    $sourceJenkinsfilePath = (Resolve-Path -LiteralPath $jenkinsCandidates[0]).Path
    Copy-Item -LiteralPath $sourceJenkinsfilePath -Destination $destJenkinsfile -Force
    Say "Copied Jenkinsfile from: $sourceJenkinsfilePath" "Green"
} elseif (-not (Test-Path -LiteralPath $destJenkinsfile)) {
    $placeholderLines = @(
        "pipeline {",
        "    agent { label '$WorkerLabel' }",
        "    stages {",
        "        stage('Placeholder') {",
        "            steps {",
        "                echo 'Replace this Jenkinsfile with the real pipeline from Step project 2'",
        "            }",
        "        }",
        "    }",
        "}"
    )
    Write-JoinedFile -Path $destJenkinsfile -Lines $placeholderLines
}

# 9. Patch Jenkinsfile worker label
if (Test-Path -LiteralPath $destJenkinsfile) {
    $jf = Get-Content -LiteralPath $destJenkinsfile -Raw
    $jfNew = $jf
    $jfNew = $jfNew -replace "agent\s*\{\s*label\s*'[^']+'\s*\}", "agent { label '$WorkerLabel' }"
    $jfNew = $jfNew -replace 'agent\s*\{\s*label\s*"[^"]+"\s*\}', "agent { label '$WorkerLabel' }"

    if ($jfNew -ne $jf) {
        Set-Content -LiteralPath $destJenkinsfile -Value $jfNew -Encoding UTF8
        Say "Patched worker label in Jenkinsfile -> $WorkerLabel" "Green"
    }
}

# 10. Patch ec2.tf one-time -> persistent
$ec2Path = Join-Path $ProjectRoot "terraform\infrastructure\ec2.tf"
if (Test-Path -LiteralPath $ec2Path) {
    $ec2 = Get-Content -LiteralPath $ec2Path -Raw
    $ec2New = $ec2 -replace 'spot_type\s*=\s*"one-time"', 'spot_type = "persistent"'

    if ($ec2New -ne $ec2) {
        Set-Content -LiteralPath $ec2Path -Value $ec2New -Encoding UTF8
        Say 'Patched ec2.tf: spot_type "one-time" -> "persistent"' "Green"
    } else {
        Say 'No "spot_type = one-time" found in ec2.tf' "Cyan"
    }
}

Say ""
Say "Done." "Green"
Say "Trash folder: $TrashRoot" "Cyan"
Say ""
Say "Next run:" "Cyan"
Say 'cd "E:\Devops\Homeworks"' "White"
Say 'git add "Step project 3"' "White"
Say 'git status' "White"