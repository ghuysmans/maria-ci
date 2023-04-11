echo SELECT CONCAT('SELECT 0 FROM ', TABLE_NAME, ' LIMIT 0;') stmt FROM information_schema.TABLES t WHERE TABLE_SCHEMA='%1' |mysql --skip-column-names -u root |mysql -u root %1
