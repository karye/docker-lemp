CREATE USER 'admin'@'%' IDENTIFIED BY 'pass';
GRANT ALL PRIVILEGES ON *.* to 'admin'@'%' WITH GRANT OPTION;
DELETE FROM mysql.user WHERE user='root' AND host='localhost';
FLUSH PRIVILEGES;
CREATE DATABASE test;
