# MariaDB application CI toolkit

## Containers
How to choose a base image:
- `mcr.microsoft.com/windows/nanoserver:ltsc2019` doesn't support WScript.
- `mcr.microsoft.com/windows/servercore:ltsc2022` is larger but works just fine.

This is nice locally (on Windows 10 upwards), but GitHub Actions still
[don't support Windows runners](https://github.com/actions/runner/issues/904).

## ImDisk
TODO only configure it in `setup.vbs`, don't try installing it.

## Data sources
### System or user DSN
This might work but it would break a developer's config:
```
odbcconf configdsn app "p=1|q=2"
```

PowerShell would just be more future-proof:
```
Add-OdbcDsn -Name "test" -DriverName "MySQL ODBC 5.2w Driver" -Platform "32-bit" -DsnType "System" -SetPropertyValue @("SERVER=127.0.0.1", "PORT=3306", "DATABASE=mdb")
```

### File DSN
TODO
