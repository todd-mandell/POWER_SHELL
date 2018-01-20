$iPre = '192.168.0.';For ($ip=0; $ip -lt 255; $ip++){Test-Connection $($iPre + $ip) -auth packet -count 1 -ErrorAction SilentlyContinue}
