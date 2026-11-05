DROP DATABASE IF EXISTS grl_delivery;
CREATE DATABASE grl_delivery CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE grl_delivery;


CREATE TABLE province (
  province_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  province_name VARCHAR(100) NOT NULL,
  PRIMARY KEY (province_id),
  UNIQUE KEY uq_province_name (province_name)
) ENGINE=InnoDB;

CREATE TABLE client_type_table (
  client_type_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  type_name      VARCHAR(100) NOT NULL,
  PRIMARY KEY (client_type_id),
  UNIQUE KEY uq_client_type_name (type_name)
) ENGINE=InnoDB;

CREATE TABLE booking_channel (
  channel_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  channel_name VARCHAR(100) NOT NULL,
  PRIMARY KEY (channel_id),
  UNIQUE KEY uq_channel_name (channel_name)
) ENGINE=InnoDB;

CREATE TABLE cargo_type (
  cargo_type_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  type_name     VARCHAR(100) NOT NULL,
  PRIMARY KEY (cargo_type_id),
  UNIQUE KEY uq_cargo_type_name (type_name)
) ENGINE=InnoDB;

CREATE TABLE unit (
  unit_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  unit_name VARCHAR(50) NOT NULL,
  PRIMARY KEY (unit_id),
  UNIQUE KEY uq_unit_name (unit_name)
) ENGINE=InnoDB;

CREATE TABLE document_type (
  document_type_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  type_name        VARCHAR(100) NOT NULL,
  PRIMARY KEY (document_type_id),
  UNIQUE KEY uq_document_type_name (type_name)
) ENGINE=InnoDB;

CREATE TABLE truck_type (
  truck_type_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  type_name     VARCHAR(100) NOT NULL,
  description   VARCHAR(255) NULL,
  PRIMARY KEY (truck_type_id),
  UNIQUE KEY uq_truck_type_name (type_name)
) ENGINE=InnoDB;

CREATE TABLE role (
  role_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  role_name VARCHAR(50) NOT NULL,
  PRIMARY KEY (role_id),
  UNIQUE KEY uq_role_name (role_name)
) ENGINE=InnoDB;

CREATE TABLE user_account_status (
  status_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  status_name VARCHAR(50) NOT NULL,
  PRIMARY KEY (status_id),
  UNIQUE KEY uq_user_status_name (status_name)
) ENGINE=InnoDB;


CREATE TABLE city_municipality (
  city_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  province_id INT UNSIGNED NOT NULL,
  city_name   VARCHAR(100) NOT NULL,
  PRIMARY KEY (city_id),
  KEY idx_city_province (province_id),
  CONSTRAINT fk_city_province FOREIGN KEY (province_id)
    REFERENCES province (province_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE location (
  location_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  city_id        INT UNSIGNED NOT NULL,
  location_name  VARCHAR(150) NOT NULL,
  street_address VARCHAR(255) NULL,
  latitude       DECIMAL(10,7) NULL,
  longitude      DECIMAL(10,7) NULL,
  PRIMARY KEY (location_id),
  KEY idx_location_city (city_id),
  CONSTRAINT fk_location_city FOREIGN KEY (city_id)
    REFERENCES city_municipality (city_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;



CREATE TABLE employee (
  employee_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  first_name     VARCHAR(100) NOT NULL,
  last_name      VARCHAR(100) NOT NULL,
  contact_number VARCHAR(30) NULL,
  status         ENUM('active','inactive') NOT NULL DEFAULT 'active',
  PRIMARY KEY (employee_id)
) ENGINE=InnoDB;

CREATE TABLE user_account (
  user_id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  employee_id   INT UNSIGNED NOT NULL,
  role_id       INT UNSIGNED NOT NULL,
  status_id     INT UNSIGNED NOT NULL,
  username      VARCHAR(50) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,   -- store bcrypt/argon2 hash, never plain text
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  UNIQUE KEY uq_user_username (username),
  UNIQUE KEY uq_user_employee (employee_id),   -- 1 employee : 0..1 account
  KEY idx_user_role (role_id),
  KEY idx_user_status (status_id),
  CONSTRAINT fk_user_employee FOREIGN KEY (employee_id)
    REFERENCES employee (employee_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_user_role FOREIGN KEY (role_id)
    REFERENCES role (role_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_user_status FOREIGN KEY (status_id)
    REFERENCES user_account_status (status_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE driver (
  driver_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  employee_id    INT UNSIGNED NOT NULL,
  license_number VARCHAR(50) NOT NULL,
  license_expiry DATE NOT NULL,
  PRIMARY KEY (driver_id),
  UNIQUE KEY uq_driver_employee (employee_id),
  UNIQUE KEY uq_driver_license (license_number),
  CONSTRAINT fk_driver_employee FOREIGN KEY (employee_id)
    REFERENCES employee (employee_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE truck (
  truck_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  truck_type_id INT UNSIGNED NOT NULL,
  plate_number  VARCHAR(20) NOT NULL,
  unit_code     VARCHAR(30) NULL,
  status        ENUM('available','on_trip','maintenance','inactive') NOT NULL DEFAULT 'available',
  PRIMARY KEY (truck_id),
  UNIQUE KEY uq_truck_plate (plate_number),
  KEY idx_truck_type (truck_type_id),
  CONSTRAINT fk_truck_type FOREIGN KEY (truck_type_id)
    REFERENCES truck_type (truck_type_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE trailer (
  trailer_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  trailer_number VARCHAR(30) NOT NULL,
  status         ENUM('available','on_trip','maintenance','inactive') NOT NULL DEFAULT 'available',
  PRIMARY KEY (trailer_id),
  UNIQUE KEY uq_trailer_number (trailer_number)
) ENGINE=InnoDB;

CREATE TABLE dashcam (
  dashcam_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  truck_id      INT UNSIGNED NULL,
  device_serial VARCHAR(100) NOT NULL,
  status        ENUM('active','inactive','faulty') NOT NULL DEFAULT 'active',
  PRIMARY KEY (dashcam_id),
  UNIQUE KEY uq_dashcam_serial (device_serial),
  UNIQUE KEY uq_dashcam_truck (truck_id),     -- one dashcam per truck
  CONSTRAINT fk_dashcam_truck FOREIGN KEY (truck_id)
    REFERENCES truck (truck_id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;


CREATE TABLE client (
  client_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  client_type_id INT UNSIGNED NOT NULL,
  client_name    VARCHAR(150) NOT NULL,
  contact_person VARCHAR(100) NULL,
  contact_number VARCHAR(30) NULL,
  email          VARCHAR(150) NULL,
  status         ENUM('active','inactive') NOT NULL DEFAULT 'active',
  PRIMARY KEY (client_id),
  KEY idx_client_type (client_type_id),
  CONSTRAINT fk_client_type FOREIGN KEY (client_type_id)
    REFERENCES client_type_table (client_type_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE booking (
  booking_id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_number       VARCHAR(30) NOT NULL,
  client_id            INT UNSIGNED NOT NULL,
  channel_id           INT UNSIGNED NOT NULL,
  pickup_location_id   INT UNSIGNED NOT NULL,
  delivery_location_id INT UNSIGNED NOT NULL,
  created_by           INT UNSIGNED NOT NULL,   -- user_account.user_id
  client_reference_no  VARCHAR(50) NULL,
  booking_date         DATE NOT NULL,
  pickup_date          DATE NULL,
  status               ENUM('pending','confirmed','dispatched','in_transit','delivered','cancelled')
                       NOT NULL DEFAULT 'pending',
  remarks              TEXT NULL,
  created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (booking_id),
  UNIQUE KEY uq_booking_number (booking_number),
  KEY idx_booking_client (client_id),
  KEY idx_booking_channel (channel_id),
  KEY idx_booking_pickup (pickup_location_id),
  KEY idx_booking_delivery (delivery_location_id),
  KEY idx_booking_created_by (created_by),
  KEY idx_booking_status (status),
  CONSTRAINT fk_booking_client FOREIGN KEY (client_id)
    REFERENCES client (client_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_booking_channel FOREIGN KEY (channel_id)
    REFERENCES booking_channel (channel_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_booking_pickup FOREIGN KEY (pickup_location_id)
    REFERENCES location (location_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_booking_delivery FOREIGN KEY (delivery_location_id)
    REFERENCES location (location_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_booking_created_by FOREIGN KEY (created_by)
    REFERENCES user_account (user_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE booking_item (
  booking_item_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id      INT UNSIGNED NOT NULL,
  cargo_type_id   INT UNSIGNED NOT NULL,
  unit_id         INT UNSIGNED NOT NULL,
  description     VARCHAR(255) NULL,
  quantity        DECIMAL(12,2) NOT NULL DEFAULT 0,
  weight_kg       DECIMAL(12,2) NULL,
  container_no    VARCHAR(30) NULL,
  seal_no         VARCHAR(30) NULL,
  PRIMARY KEY (booking_item_id),
  KEY idx_bitem_booking (booking_id),
  KEY idx_bitem_cargo (cargo_type_id),
  KEY idx_bitem_unit (unit_id),
  CONSTRAINT fk_bitem_booking FOREIGN KEY (booking_id)
    REFERENCES booking (booking_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_bitem_cargo FOREIGN KEY (cargo_type_id)
    REFERENCES cargo_type (cargo_type_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_bitem_unit FOREIGN KEY (unit_id)
    REFERENCES unit (unit_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE booking_document (
  document_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id       INT UNSIGNED NOT NULL,
  uploaded_by      INT UNSIGNED NOT NULL,
  document_type_id INT UNSIGNED NOT NULL,
  file_path        VARCHAR(255) NOT NULL,
  uploaded_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (document_id),
  KEY idx_bdoc_booking (booking_id),
  KEY idx_bdoc_user (uploaded_by),
  KEY idx_bdoc_type (document_type_id),
  CONSTRAINT fk_bdoc_booking FOREIGN KEY (booking_id)
    REFERENCES booking (booking_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_bdoc_user FOREIGN KEY (uploaded_by)
    REFERENCES user_account (user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_bdoc_type FOREIGN KEY (document_type_id)
    REFERENCES document_type (document_type_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE trip (
  trip_id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  trip_number         VARCHAR(30) NOT NULL,
  booking_id          INT UNSIGNED NOT NULL,
  created_by          INT UNSIGNED NOT NULL,
  scheduled_departure DATETIME NULL,
  remarks             TEXT NULL,
  created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (trip_id),
  UNIQUE KEY uq_trip_number (trip_number),
  KEY idx_trip_booking (booking_id),
  KEY idx_trip_created_by (created_by),
  CONSTRAINT fk_trip_booking FOREIGN KEY (booking_id)
    REFERENCES booking (booking_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_trip_created_by FOREIGN KEY (created_by)
    REFERENCES user_account (user_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE trip_item (
  trip_item_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  trip_id         INT UNSIGNED NOT NULL,
  booking_item_id INT UNSIGNED NOT NULL,
  quantity_loaded DECIMAL(12,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (trip_item_id),
  UNIQUE KEY uq_trip_bitem (trip_id, booking_item_id),
  KEY idx_titem_bitem (booking_item_id),
  CONSTRAINT fk_titem_trip FOREIGN KEY (trip_id)
    REFERENCES trip (trip_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_titem_bitem FOREIGN KEY (booking_item_id)
    REFERENCES booking_item (booking_item_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE trip_assignment (
  trip_assignment_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  trip_id            INT UNSIGNED NOT NULL,
  truck_id           INT UNSIGNED NOT NULL,
  driver_id          INT UNSIGNED NOT NULL,
  trailer_id         INT UNSIGNED NULL,          -- not every trip needs a trailer
  assigned_by        INT UNSIGNED NOT NULL,
  assigned_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ended_at           DATETIME NULL,
  reason             VARCHAR(255) NULL,          -- e.g. reassignment reason
  PRIMARY KEY (trip_assignment_id),
  KEY idx_ta_trip (trip_id),
  KEY idx_ta_truck (truck_id),
  KEY idx_ta_driver (driver_id),
  KEY idx_ta_trailer (trailer_id),
  KEY idx_ta_assigned_by (assigned_by),
  CONSTRAINT fk_ta_trip FOREIGN KEY (trip_id)
    REFERENCES trip (trip_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ta_truck FOREIGN KEY (truck_id)
    REFERENCES truck (truck_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ta_driver FOREIGN KEY (driver_id)
    REFERENCES driver (driver_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ta_trailer FOREIGN KEY (trailer_id)
    REFERENCES trailer (trailer_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ta_assigned_by FOREIGN KEY (assigned_by)
    REFERENCES user_account (user_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE trip_status_log (
  status_log_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  trip_id       INT UNSIGNED NOT NULL,
  updated_by    INT UNSIGNED NOT NULL,
  status        ENUM('scheduled','dispatched','loading','in_transit','arrived','delivered','delayed','cancelled')
                NOT NULL,
  remarks       VARCHAR(255) NULL,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (status_log_id),
  KEY idx_tsl_trip (trip_id, updated_at),
  KEY idx_tsl_user (updated_by),
  CONSTRAINT fk_tsl_trip FOREIGN KEY (trip_id)
    REFERENCES trip (trip_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_tsl_user FOREIGN KEY (updated_by)
    REFERENCES user_account (user_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE location_log (
  location_log_id    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,  -- grows fast
  trip_assignment_id INT UNSIGNED NOT NULL,
  latitude           DECIMAL(10,7) NOT NULL,
  longitude          DECIMAL(10,7) NOT NULL,
  source             ENUM('driver_app','dashcam','manual') NOT NULL DEFAULT 'driver_app',
  recorded_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (location_log_id),
  KEY idx_ll_assignment_time (trip_assignment_id, recorded_at),
  CONSTRAINT fk_ll_assignment FOREIGN KEY (trip_assignment_id)
    REFERENCES trip_assignment (trip_assignment_id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE proof_of_delivery (
  pod_id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  trip_id            INT UNSIGNED NOT NULL,
  submitted_by       INT UNSIGNED NOT NULL,
  validated_by       INT UNSIGNED NULL,
  received_by_name   VARCHAR(150) NOT NULL,
  delivered_at       DATETIME NOT NULL,
  latitude           DECIMAL(10,7) NULL,
  longitude          DECIMAL(10,7) NULL,
  validation_status  ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  validation_remarks VARCHAR(255) NULL,
  validated_at       DATETIME NULL,
  PRIMARY KEY (pod_id),
  KEY idx_pod_trip (trip_id),
  KEY idx_pod_submitted (submitted_by),
  KEY idx_pod_validated (validated_by),
  CONSTRAINT fk_pod_trip FOREIGN KEY (trip_id)
    REFERENCES trip (trip_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pod_submitted FOREIGN KEY (submitted_by)
    REFERENCES user_account (user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pod_validated FOREIGN KEY (validated_by)
    REFERENCES user_account (user_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE pod_attachment (
  attachment_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  pod_id          INT UNSIGNED NOT NULL,
  attachment_type ENUM('photo','signature','document') NOT NULL DEFAULT 'photo',
  file_path       VARCHAR(255) NOT NULL,
  captured_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (attachment_id),
  KEY idx_podatt_pod (pod_id),
  CONSTRAINT fk_podatt_pod FOREIGN KEY (pod_id)
    REFERENCES proof_of_delivery (pod_id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;


INSERT INTO role (role_name) VALUES ('Admin'),('Dispatcher'),('Booking Staff'),('Driver');
INSERT INTO user_account_status (status_name) VALUES ('Active'),('Inactive'),('Suspended');
INSERT INTO client_type_table (type_name) VALUES ('Corporate'),('Individual'),('Government');
INSERT INTO booking_channel (channel_name) VALUES ('Walk-in'),('Phone'),('Email'),('Facebook'),('Web');
INSERT INTO cargo_type (type_name) VALUES ('General Cargo'),('Container'),('Perishable'),('Bulk');
INSERT INTO unit (unit_name) VALUES ('Pallet'),('Box'),('Sack'),('Container'),('Piece');
INSERT INTO document_type (type_name) VALUES ('Delivery Receipt'),('Bill of Lading'),('Purchase Order'),('Invoice');
INSERT INTO truck_type (type_name, description) VALUES
  ('Wing Van','Enclosed wing van'),('10-Wheeler','10-wheeler cargo truck'),('Tractor Head','For trailers/containers');

INSERT INTO province (province_name) VALUES ('Misamis Oriental'),('Bukidnon');
INSERT INTO city_municipality (province_id, city_name) VALUES (1,'Cagayan de Oro City'),(2,'Malaybalay City');
INSERT INTO location (city_id, location_name, street_address, latitude, longitude) VALUES
  (1,'GRL Main Yard','Sample St., Cagayan de Oro',8.4542000,124.6319000),
  (2,'Client Warehouse','Sample Rd., Malaybalay',8.1575000,125.1278000);

INSERT INTO employee (first_name,last_name,contact_number) VALUES
  ('Admin','User','09170000001'),('Juan','Dela Cruz','09170000002');
-- Replace the hash below with a real bcrypt hash generated by your app
INSERT INTO user_account (employee_id,role_id,status_id,username,password_hash) VALUES
  (1,1,1,'admin','REPLACE_WITH_BCRYPT_HASH');
INSERT INTO driver (employee_id,license_number,license_expiry) VALUES (2,'N01-23-456789','2028-12-31');

INSERT INTO truck (truck_type_id,plate_number,unit_code) VALUES (2,'ABC 1234','TRK-001');
INSERT INTO trailer (trailer_number) VALUES ('TRL-001');
INSERT INTO dashcam (truck_id,device_serial) VALUES (1,'DC-0001');
INSERT INTO client (client_type_id,client_name,contact_person,contact_number,email) VALUES
  (1,'Sample Trading Corp.','Maria Santos','09171112222','maria@sample.com');


-- Dispatch board: every trip with its current assignment and latest status
CREATE OR REPLACE VIEW v_trip_overview AS
SELECT t.trip_id, t.trip_number, b.booking_number, c.client_name,
       pl.location_name AS pickup, dl.location_name AS delivery,
       tr.plate_number, CONCAT(e.first_name,' ',e.last_name) AS driver,
       (SELECT s.status FROM trip_status_log s
         WHERE s.trip_id = t.trip_id
         ORDER BY s.updated_at DESC, s.status_log_id DESC LIMIT 1) AS current_status
FROM trip t
JOIN booking b   ON b.booking_id = t.booking_id
JOIN client c    ON c.client_id = b.client_id
JOIN location pl ON pl.location_id = b.pickup_location_id
JOIN location dl ON dl.location_id = b.delivery_location_id
LEFT JOIN trip_assignment ta ON ta.trip_id = t.trip_id AND ta.ended_at IS NULL
LEFT JOIN truck tr   ON tr.truck_id = ta.truck_id
LEFT JOIN driver d   ON d.driver_id = ta.driver_id
LEFT JOIN employee e ON e.employee_id = d.employee_id;

-- Latest GPS point per active assignment (for the live tracking map)
CREATE OR REPLACE VIEW v_latest_location AS
SELECT ll.*
FROM location_log ll
JOIN (SELECT trip_assignment_id, MAX(recorded_at) AS max_time
        FROM location_log GROUP BY trip_assignment_id) m
  ON m.trip_assignment_id = ll.trip_assignment_id AND m.max_time = ll.recorded_at;


-- SHOW TABLES;                 -- should list 27 tables + 2 views
-- SELECT * FROM v_trip_overview;
