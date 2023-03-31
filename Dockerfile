FROM mcr.microsoft.com/windows/servercore:ltsc2022

COPY mariadb-10.6.7-winx64.msi c:
RUN msiexec /i mariadb-10.6.7-winx64.msi /q
RUN ["setx", "path", "%PATH%;c:\\Program Files\\MariaDB 10.6\\bin\\"]
RUN mariadb-install-db -d c:\\data -S MariaDB -p test

RUN mysql -u root --password=test -e "SELECT 1+1;"

COPY mariadb-connector-odbc-3.1.15-win64.msi c:
RUN msiexec /i mariadb-connector-odbc-3.1.15-win64.msi

LABEL org.opencontainers.image.source=https://github.com/ghuysmans/maria-ci
