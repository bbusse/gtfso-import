CREATE TABLE IF NOT EXISTS agency (
    agency_id VARCHAR(20) PRIMARY KEY,
    agency_name VARCHAR(255),
    agency_url VARCHAR(255),
    agency_timezone VARCHAR(50),
    agency_lang VARCHAR(100),
    agency_phone VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS calendar (
    service_id VARCHAR(50), -- Changed from INT to VARCHAR(50)
    monday SMALLINT,
    tuesday SMALLINT,
    wednesday SMALLINT,
    thursday SMALLINT,
    friday SMALLINT,
    saturday SMALLINT,
    sunday SMALLINT,
    start_date VARCHAR(8),
    end_date VARCHAR(8)
);

CREATE TABLE IF NOT EXISTS calendar_dates (
    service_id VARCHAR(50), -- Changed from INT to VARCHAR(50)
    date VARCHAR(8),
    exception_type INT
);

CREATE TABLE IF NOT EXISTS routes (
    route_id VARCHAR(12) PRIMARY KEY,
    agency_id VARCHAR(20), -- Changed from INT to VARCHAR(20)
    route_short_name VARCHAR(10),
    route_long_name VARCHAR(32),
    route_type INT,
    route_color VARCHAR(255),
    route_text_color VARCHAR(255),
    route_desc VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS stops (
    stop_id VARCHAR(25) PRIMARY KEY,
    stop_code VARCHAR(255),
    stop_name VARCHAR(255),
    stop_desc VARCHAR(255),
    stop_lat DECIMAL(8,6),
    stop_lon DECIMAL(8,6),
    location_type VARCHAR(255),
    parent_station VARCHAR(255),
    wheelchair_boarding SMALLINT,
    platform_code VARCHAR(100),
    zone_id VARCHAR(100),
    zone_level VARCHAR(9)
);

CREATE TABLE IF NOT EXISTS stop_times (
    trip_id VARCHAR(255),
    arrival_time INTERVAL,
    departure_time INTERVAL,
    stop_id VARCHAR(25),
    stop_sequence INT,
    pickup_type INT,
    drop_off_type INT,
    stop_headsign VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS transfers (
    from_stop_id VARCHAR(25),
    to_stop_id VARCHAR(25),
    transfer_type INT,
    min_transfer_time INT,
    from_route_id VARCHAR(32),
    to_route_id VARCHAR(32),
    from_trip_id VARCHAR(32),
    to_trip_id VARCHAR(32)
);

CREATE TABLE IF NOT EXISTS trips (
    route_id VARCHAR(25),
    service_id VARCHAR(50), -- Changed from INT to VARCHAR(50)
    trip_id VARCHAR(255) PRIMARY KEY,
    trip_headsign VARCHAR(255),
    trip_short_name VARCHAR(255),
    direction_id SMALLINT,
    block_id INT,
    shape_id VARCHAR(50), -- Changed from INT to VARCHAR(50)
    wheelchair_accessible SMALLINT,
    bikes_allowed SMALLINT
);
