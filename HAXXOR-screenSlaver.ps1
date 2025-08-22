#legit random flashing background image changes that are meant to be scary haha
$i = 1
#powershell.exe -windowstyle hidden -command "location\THIS-file.ps1"
While($i -eq 1) {
$imgPath1="C:\Users\Administrator\Documents\haxxorbackground.png"
$imgPath2="C:\Users\Administrator\Documents\CALM-BACKGROUND.jpg"
$code = @' 
using System.Runtime.InteropServices; 
namespace Win32{ 
    
     public class Wallpaper{ 
        [DllImport("user32.dll", CharSet=CharSet.Auto)] 
         static extern int SystemParametersInfo (int uAction , int uParam , string lpvParam , int fuWinIni) ; 
         
         public static void SetWallpaper(string thePath){ 
            SystemParametersInfo(20,0,thePath,3); 
         }
    }
 } 
'@

add-type $code 

#Apply the Change on the system 
[Win32.Wallpaper]::SetWallpaper($imgPath1)

timeout /t 01
$randTimeout = (Get-Random -Minimum 3 -Maximum 50)

#Apply the Change on the system 
[Win32.Wallpaper]::SetWallpaper($imgPath2)
timeout /t $randTimeout
}
