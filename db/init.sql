-- this file for local dev purposes only!! should never be run against prod

DROP DATABASE IF EXISTS netgo;

CREATE DATABASE IF NOT EXISTS netgo;

CREATE OR REPLACE USER 'username'@'localhost' IDENTIFIED BY 'password';

-- Grant read/write access (all privileges except GRANT OPTION) to the 'netgo' database
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER
ON netgo.* TO 'username'@'%';

-- Apply the privileges
FLUSH PRIVILEGES;
