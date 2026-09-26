param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Question
)

# ==============================
# UTF-8 OUTPUT
# ==============================

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()

# ==============================
# SETTINGS
# ==============================

$ApiUrl = "https://api.kilo.ai/api/openrouter/chat/completions"
$Model = "stepfun/step-3.7-flash:free"

# ==============================
# API KEY
# ==============================

if (-not $env:KILO_API_KEY) {
    Write-Host ""
    Write-Host "ERROR: KILO_API_KEY is not set." -ForegroundColor Red
    Write-Host ""
    Write-Host 'Set it with:'
    Write-Host '$env:KILO_API_KEY="YOUR_API_KEY"'
    Write-Host ""
    exit 1
}

# ==============================
# QUESTION
# ==============================

if (-not $Question -or $Question.Count -eq 0) {
    Write-Host ""
    Write-Host 'Usage: .\ai.ps1 /ai "your question"'
    Write-Host ""
    exit 1
}

$q = ($Question -join " ").Trim()

# Remove /ai
if ($q -match "^/ai(\s+|$)") {
    $q = $q -replace "^/ai\s*", ""
}

if ([string]::IsNullOrWhiteSpace($q)) {
    Write-Host ""
    Write-Host "ERROR: Question is empty." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# ==============================
# REQUEST BODY
# ==============================

$bodyObject = @{
    model = $Model

    messages = @(
        @{
            role = "user"
            content = $q
        }
    )

    stream = $true
}

$body = $bodyObject | ConvertTo-Json -Depth 10 -Compress

# ==============================
# TEMP BODY FILE
# ==============================

$bodyFile = Join-Path $env:TEMP "kilo-ai-body.json"

[System.IO.File]::WriteAllText(
    $bodyFile,
    $body,
    [System.Text.UTF8Encoding]::new($false)
)

# ==============================
# STATE
# ==============================

$answerStarted = $false
$thinking = $false

# Write-Host ""
Write-Host "Thinking..." -NoNewline

# ==============================
# STREAM
# ==============================

try {

    curl.exe -sN `
        $ApiUrl `
        -H "Content-Type: application/json" `
        -H "Authorization: Bearer $env:KILO_API_KEY" `
        --data-binary "@$bodyFile" |
    ForEach-Object {

        $line = $_

        # Ignore everything except SSE data
        if (-not $line.StartsWith("data:")) {
            return
        }

        $data = $line.Substring(5).Trim()

        # Stream finished
        if ($data -eq "[DONE]") {
            return
        }

        # Parse JSON
        try {
            $json = $data | ConvertFrom-Json
        }
        catch {
            return
        }

        if (-not $json.choices) {
            return
        }

        $delta = $json.choices[0].delta

        if (-not $delta) {
            return
        }

        # ==============================
        # REASONING
        # ==============================

        if ($null -ne $delta.reasoning) {

            if (-not $thinking) {
                $thinking = $true
            }

            return
        }

        # ==============================
        # ANSWER
        # ==============================

        if ($null -ne $delta.content) {

            if (-not $answerStarted) {

                # Remove Thinking line
                Write-Host "`r                    `r" -NoNewline

                Write-Host ""
                Write-Host "[BOT] " -NoNewline

                $answerStarted = $true
            }

            Write-Host $delta.content -NoNewline -ForegroundColor Red
        }
    }

}
catch {

    Write-Host ""
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

# ==============================
# CLEANUP
# ==============================

if (Test-Path $bodyFile) {
    Remove-Item $bodyFile -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host ""