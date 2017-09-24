gwmi Win32_USBControllerDevice |%{[wmi]($_.Dependent)} | Sort Manufacturer,Description,DeviceID | Ft -GroupBy Manufacturer Description,Service,DeviceID
