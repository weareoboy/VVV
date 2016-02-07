DELETE FROM mysql.user WHERE User="";

CREATE USER 'happybits'@'localhost' IDENTIFIED BY 'culturevulture';

GRANT GRANT OPTION ON *.* TO 'new_user'@'%';
GRANT GRANT OPTION ON *.* TO 'new_user'@'localhost';

GRANT ALL PRIVILEGES ON * . * TO 'happybits'@'localhost';

-- Commands to create a MySQL database and user
CREATE SCHEMA `ninja` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON `happybits`.* TO 'ninja'@'localhost';
FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS `piwik`;
GRANT ALL PRIVILEGES ON `piwik`.* TO 'happybits'@'localhost' IDENTIFIED BY 'culturevulture';

CREATE DATABASE IF NOT EXISTS `staging`;
GRANT ALL PRIVILEGES ON `staging`.* TO 'happybits'@'localhost' IDENTIFIED BY 'culturevulture';

CREATE DATABASE IF NOT EXISTS `beta`;
GRANT ALL PRIVILEGES ON `beta`.* TO 'happybits'@'localhost' IDENTIFIED BY 'culturevulture';

CREATE DATABASE IF NOT EXISTS `home`;
GRANT ALL PRIVILEGES ON `home`.* TO 'happybits'@'localhost' IDENTIFIED BY 'culturevulture';