-- To create the database execute
-- mysql mhlan -u mhlan < db.sql

CREATE TABLE attendees (
	user_id INT PRIMARY KEY AUTO_INCREMENT,
	email VARCHAR(255) UNIQUE,
	firstname VARCHAR(255),
	lastname VARCHAR(255),
	handle VARCHAR(255),
	paypal_id VARCHAR(32)
);

CREATE TABLE paid (
	user_id INT UNIQUE NOT NULL
);
