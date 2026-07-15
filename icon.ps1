Add-Type -AssemblyName System.Drawing

function RoundedRect($x, $y, $w, $h, $r) {
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $path.AddArc($x, $y, $r*2, $r*2, 180, 90)
    $path.AddArc($x+$w-$r*2-1, $y, $r*2, $r*2, 270, 90)
    $path.AddArc($x+$w-$r*2-1, $y+$h-$r*2-1, $r*2, $r*2, 0, 90)
    $path.AddArc($x, $y+$h-$r*2-1, $r*2, $r*2, 90, 90)
    $path.CloseFigure()
    return $path
}

function Save-Ico($bmp, $path) {
    $ms = [System.IO.MemoryStream]::new()
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytes = $ms.ToArray()
    $ms.Dispose()

    $fs = [System.IO.File]::Open($path, [System.IO.FileMode]::Create)
    $w = [System.IO.BinaryWriter]::new($fs)

    $w.Write([UInt16]0)
    $w.Write([UInt16]1)
    $w.Write([UInt16]1)

    $bw = $bmp.Width;  if ($bw -ge 256) { $bw = 0 }
    $bh = $bmp.Height; if ($bh -ge 256) { $bh = 0 }
    $w.Write([Byte]$bw)
    $w.Write([Byte]$bh)
    $w.Write([Byte]0)
    $w.Write([Byte]0)
    $w.Write([UInt16]1)
    $w.Write([UInt16]32)
    $w.Write([UInt32]$pngBytes.Length)
    $w.Write([UInt32]22)

    $w.Write($pngBytes)
    $w.Dispose()
    $fs.Dispose()
}

$size = 256
$bmp = [System.Drawing.Bitmap]::new($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.Clear([System.Drawing.Color]::Transparent)

$cx = 128
$cy = 128

$body = RoundedRect 18 50 220 160 24
$p1 = [System.Drawing.Point]::new(18, 50)
$p2 = [System.Drawing.Point]::new(238, 210)
$c1 = [System.Drawing.Color]::FromArgb(255, 255, 64, 129)
$c2 = [System.Drawing.Color]::FromArgb(255, 123, 31, 162)
$bodyBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new($p1, $p2, $c1, $c2)
$g.FillPath($bodyBrush, $body)
$bodyBrush.Dispose()

$bodyPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 255, 128, 200), 3)
$g.DrawPath($bodyPen, $body)
$bodyPen.Dispose()

$hump = RoundedRect 80 30 96 30 10
$humpP1 = [System.Drawing.Point]::new(80, 30)
$humpP2 = [System.Drawing.Point]::new(176, 60)
$humpC1 = [System.Drawing.Color]::FromArgb(255, 255, 128, 191)
$humpC2 = [System.Drawing.Color]::FromArgb(255, 200, 64, 150)
$humpBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new($humpP1, $humpP2, $humpC1, $humpC2)
$g.FillPath($humpBrush, $hump)
$humpBrush.Dispose()
$humpPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 255, 150, 210), 2)
$g.DrawPath($humpPen, $hump)
$humpPen.Dispose()

$flashX = 200; $flashY = 60; $flashR = 12
$fp = [System.Drawing.Drawing2D.GraphicsPath]::new()
$fp.AddEllipse($flashX-$flashR, $flashY-$flashR, $flashR*2, $flashR*2)
$flashBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 230, 50))
$g.FillPath($flashBrush, $fp)
$flashBrush.Dispose()
$flashPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 255, 200, 0), 2)
$g.DrawPath($flashPen, $fp)
$flashPen.Dispose()

$lensCX = $cx; $lensCY = 138; $lensR = 60
$outerLensPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
$outerLensPath.AddEllipse($lensCX-$lensR, $lensCY-$lensR, $lensR*2, $lensR*2)

$op1 = [System.Drawing.Point]::new($lensCX-$lensR, $lensCY-$lensR)
$op2 = [System.Drawing.Point]::new($lensCX+$lensR, $lensCY+$lensR)
$oc1 = [System.Drawing.Color]::FromArgb(255, 180, 100, 220)
$oc2 = [System.Drawing.Color]::FromArgb(255, 80, 20, 120)
$outerBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new($op1, $op2, $oc1, $oc2)
$g.FillPath($outerBrush, $outerLensPath)
$outerBrush.Dispose()
$outerPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 200, 130, 255), 3)
$g.DrawPath($outerPen, $outerLensPath)
$outerPen.Dispose()

$innerR = 42
$innerLensPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
$innerLensPath.AddEllipse($lensCX-$innerR, $lensCY-$innerR, $innerR*2, $innerR*2)

$ip1 = [System.Drawing.Point]::new($lensCX-$innerR, $lensCY-$innerR)
$ip2 = [System.Drawing.Point]::new($lensCX+$innerR, $lensCY+$innerR)
$ic1 = [System.Drawing.Color]::FromArgb(255, 0, 230, 255)
$ic2 = [System.Drawing.Color]::FromArgb(255, 20, 30, 140)
$glassBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new($ip1, $ip2, $ic1, $ic2)
$g.FillPath($glassBrush, $innerLensPath)
$glassBrush.Dispose()
$innerPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 100, 240, 255), 2)
$g.DrawPath($innerPen, $innerLensPath)
$innerPen.Dispose()

$hlPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
$hlPath.AddEllipse(100, 100, 26, 16)
$hlBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(140, 255, 255, 255))
$g.FillPath($hlBrush, $hlPath)
$hlBrush.Dispose()

$dotPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
$dotPath.AddEllipse($lensCX-5, $lensCY-5, 10, 10)
$dotBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(120, 255, 60, 150))
$g.FillPath($dotBrush, $dotPath)
$dotBrush.Dispose()

$rect = [System.Drawing.Rectangle]::new(0, 0, $bmp.Width, $bmp.Height)
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, $bmp.PixelFormat)
$stride = [Math]::Abs($data.Stride)
$rawBytes = [byte[]]::new($stride * $bmp.Height)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $rawBytes, 0, $rawBytes.Length)
$bmp.UnlockBits($data)

for ($i = 0; $i -lt $rawBytes.Length; $i += 4) {
    $tmp = $rawBytes[$i]
    $rawBytes[$i] = $rawBytes[$i+2]
    $rawBytes[$i+2] = $tmp
}

$g.Dispose()

$icoPath = "camera.ico"
Save-Ico $bmp $icoPath

$rgbaPath = "camera.rgba"
[System.IO.File]::WriteAllBytes($rgbaPath, $rawBytes)

$bmp.Dispose()
Write-Output "Done: $icoPath, $rgbaPath"
