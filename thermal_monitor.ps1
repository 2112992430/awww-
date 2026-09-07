# RyzenAdj 路径
$ryzenAdjPath = "C:\ryzenadj\ryzenadj.exe"

# 温度阈值（摄氏度）
$tempThreshold = 90
# 高性能功耗（25W）和降频功耗（20W，单位毫瓦）
$powerLimitHigh = 25000
$powerLimitLow = 20000
# 触发降频后，强制维持低功耗的秒数（冷却时间）
$coolDownPeriod = 30

$throttled = $false
$throttleStartTime = Get-Date

while ($true) {
    $info = & $ryzenAdjPath -i | Out-String
    if ($info -match "THM VALUE CORE\s+\|\s+([\d.]+)") {
        $currentTemp = [double]$matches[1]
        $currentTime = Get-Date
        
        if ($throttled) {
            $elapsed = ($currentTime - $throttleStartTime).TotalSeconds
            $remaining = [math]::Round($coolDownPeriod - $elapsed)
            
            Write-Host "$(Get-Date) - [冷却中] 温度 ${currentTemp}°C，剩余 ${remaining} 秒"
            
            if ($elapsed -ge $coolDownPeriod) {
                if ($currentTemp -lt ($tempThreshold - 2)) {
                    $throttled = $false
                    & $ryzenAdjPath --stapm-limit=$powerLimitHigh --fast-limit=$powerLimitHigh --slow-limit=$powerLimitHigh --tctl-temp=$tempThreshold
                    Write-Host "$(Get-Date) - [恢复] 冷却结束，温度 ${currentTemp}°C，已恢复 25W"
                } else {
                    $throttleStartTime = $currentTime
                    Write-Host "$(Get-Date) - [等待] 冷却结束但温度 ${currentTemp}°C 仍偏高，继续冷却"
                }
            }
        } else {
            Write-Host "$(Get-Date) - [正常] 温度 ${currentTemp}°C"
            
            if ($currentTemp -ge $tempThreshold) {
                $throttled = $true
                $throttleStartTime = $currentTime
                & $ryzenAdjPath --stapm-limit=$powerLimitLow --fast-limit=$powerLimitLow --slow-limit=$powerLimitLow --tctl-temp=$tempThreshold
                Write-Host "$(Get-Date) - [降频] 温度 ${currentTemp}°C 达到阈值，限制为 20W，持续 ${coolDownPeriod} 秒"
            }
        }
    }
    Start-Sleep -Seconds 5
}