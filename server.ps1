$listener = New-Object System.Net.HttpListener
$port = 8080
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Prefixes.Add("http://127.0.0.1:$port/")

try {
    $listener.Start()
} catch {
    $port = 8088
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$port/")
    $listener.Prefixes.Add("http://127.0.0.1:$port/")
    $listener.Start()
}

Write-Output "QIW Fence & Gates Server listening on http://localhost:$port/"

$baseDir = $PSScriptRoot

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        try {
            $url = $request.Url.LocalPath
            if ($url -eq "/") {
                $url = "/index.html"
            }
            
            $subPath = $url.TrimStart('/').Replace('/', '\')
            $filePath = Join-Path $baseDir $subPath
            
            if (Test-Path $filePath -PathType Leaf) {
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                
                $contentType = "application/octet-stream"
                switch ($ext) {
                    ".html" { $contentType = "text/html; charset=utf-8" }
                    ".htm"  { $contentType = "text/html; charset=utf-8" }
                    ".js"   { $contentType = "application/javascript; charset=utf-8" }
                    ".css"  { $contentType = "text/css; charset=utf-8" }
                    ".png"  { $contentType = "image/png" }
                    ".jpg"  { $contentType = "image/jpeg" }
                    ".jpeg" { $contentType = "image/jpeg" }
                    ".gif"  { $contentType = "image/gif" }
                    ".svg"  { $contentType = "image/svg+xml; charset=utf-8" }
                    ".json" { $contentType = "application/json; charset=utf-8" }
                    ".woff" { $contentType = "font/woff" }
                    ".woff2"{ $contentType = "font/woff2" }
                    ".ttf"  { $contentType = "font/ttf" }
                }
                
                $response.ContentType = $contentType
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $response.StatusCode = 404
                $errorMsg = [System.Text.Encoding]::UTF8.GetBytes("404 - File Not Found: $url")
                $response.ContentType = "text/plain; charset=utf-8"
                $response.ContentLength64 = $errorMsg.Length
                $response.OutputStream.Write($errorMsg, 0, $errorMsg.Length)
            }
        } catch {
            Write-Host "Request processing error: $_"
        } finally {
            $response.Close()
        }
    }
} finally {
    $listener.Stop()
}
