
lpane.net
=================

### INSTALLATION

Install perl modules

	sudo apt-get install cpanm libdbd-mysql-perl
	sudo cpanm --installdeps .

Log in to MySQL console and run

	CREATE USER 'lpane'@'localhost';
	CREATE DATABASE 'lpane';
	GRANT ALL PRIVILEGES ON lpane.* TO 'lpane'@'localhost';

Then create tables

	mysql lpane -u lpane < etc/db.sql
