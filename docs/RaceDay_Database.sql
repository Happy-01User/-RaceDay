-- ============================================================
-- RACEDAY DATABASE - COMPLETE SQL SCRIPT
-- Portfolio of Evidence (PoE) 
-- ============================================================


-- DESCRIPTION: This script creates the complete RaceDay database
             
-- ============================================================

-- ============================================================
-- CREATE THE DATABASE
-- ============================================================

-- Check if database exists and drop it if it does
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'RaceDay_Database')
BEGIN
    ALTER DATABASE RaceDay_Database SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDay_Database;
END
GO

-- Create the database
CREATE DATABASE RaceDay_Database;
GO

-- Use the database
USE RaceDay_Database;
GO

PRINT '========================================';
PRINT 'DATABASE CREATED: RaceDay_Database';
PRINT '========================================';
PRINT '';
GO

-- ============================================================
-- SECTION 1: DROP EXISTING TABLES (Cleanup)
-- ============================================================
-- Drop in reverse order to avoid foreign key conflicts
-- ============================================================

IF OBJECT_ID('Result', 'U') IS NOT NULL DROP TABLE Result;
IF OBJECT_ID('Enrolment', 'U') IS NOT NULL DROP TABLE Enrolment;
IF OBJECT_ID('Event', 'U') IS NOT NULL DROP TABLE Event;
IF OBJECT_ID('Category', 'U') IS NOT NULL DROP TABLE Category;
IF OBJECT_ID('Participant', 'U') IS NOT NULL DROP TABLE Participant;
IF OBJECT_ID('Organiser', 'U') IS NOT NULL DROP TABLE Organiser;

PRINT '✓ Existing tables dropped successfully';
PRINT '';
GO

-- ============================================================
-- CREATE TABLES WITH PRIMARY AND FOREIGN KEYS
-- ============================================================

-- ============================================================
-- TABLE 1: Organiser
-- ============================================================

-- RELATIONSHIPS: One Organiser can create MANY Events (1:M)
-- ============================================================

CREATE TABLE Organiser (
    OrganiserID INT PRIMARY KEY IDENTITY(1,1),  -- PRIMARY KEY
    UserName VARCHAR(50) NOT NULL UNIQUE,
    Password VARCHAR(255) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE
);

PRINT '✓ Table "Organiser" created successfully';
PRINT '   - PRIMARY KEY: OrganiserID';
PRINT '   - One Organiser can create many Events';
PRINT '';
GO

-- ============================================================
-- TABLE 2: Participant
-- ============================================================

-- RELATIONSHIPS: One Participant can have MANY Enrolments (1:M)
-- ============================================================

CREATE TABLE Participant (
    ParticipantID INT PRIMARY KEY IDENTITY(1,1),  -- PRIMARY KEY
    EmailParticipants VARCHAR(100) NOT NULL UNIQUE,
    PasswordParticipant VARCHAR(255) NOT NULL,
    DateOfBirth DATE NOT NULL
);

PRINT '✓ Table "Participant" created successfully';
PRINT '   - PRIMARY KEY: ParticipantID';
PRINT '   - One Participant can have many Enrolments';
PRINT '';
GO

-- ============================================================
-- TABLE 3: Category
-- ============================================================
-- PURPOSE: Stores different race categories (5km, 10km, etc.)
-- RELATIONSHIPS: One Category can have MANY Enrolments (1:M)
-- ============================================================

CREATE TABLE Category (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),  -- PRIMARY KEY
    CategoryName VARCHAR(50) NOT NULL,
    Description TEXT,
    Distance DECIMAL(5, 2) NOT NULL,  -- Distance in kilometers
    fee DECIMAL(10, 2) DEFAULT 0.00,
    maxAge INT,
    minAge INT DEFAULT 0,
    CONSTRAINT CHK_AgeRange CHECK (minAge <= maxAge)
);

PRINT '✓ Table "Category" created successfully';
PRINT '   - PRIMARY KEY: CategoryID';
PRINT '   - One Category can have many Enrolments';
PRINT '';
GO

-- ============================================================
-- TABLE 4: Event
-- ============================================================
-- PURPOSE: Stores information about racing events.
-- RELATIONSHIPS: 
--   - Many Events belong to ONE Organiser (M:1)
--   - One Event can have MANY Enrolments (1:M)
-- ============================================================

CREATE TABLE Event (
    EventID INT PRIMARY KEY IDENTITY(1,1),  -- PRIMARY KEY
    EventName VARCHAR(100) NOT NULL,
    EventDate DATE NOT NULL,
    EventType VARCHAR(50) NOT NULL,
    distanceKM DECIMAL(5, 2) NOT NULL,
    maxParticipant INT,
    OrganiserID INT NOT NULL,  -- FOREIGN KEY to Organiser
    
    -- FOREIGN KEY: Links Event to Organiser
    -- Cardinality: Many Events : One Organiser (M:1)
    CONSTRAINT FK_Event_Organiser FOREIGN KEY (OrganiserID) 
        REFERENCES Organiser(OrganiserID) ON DELETE CASCADE
);

PRINT '✓ Table "Event" created successfully';
PRINT '   - PRIMARY KEY: EventID';
PRINT '   - FOREIGN KEY: OrganiserID → Organiser(OrganiserID)';
PRINT '   - Cardinality: Many Events : One Organiser (M:1)';
PRINT '   - One Event can have many Enrolments';
PRINT '';
GO

-- ============================================================
-- TABLE 5: Enrolment (Associative/Intersection Entity)
-- ============================================================
-- PURPOSE: Resolves the MANY-TO-MANY relationships between:
--          - Participant and Event
--          - Participant and Category
--          - Event and Category
-- RELATIONSHIPS:
--   - Many Enrolments belong to ONE Participant (M:1)
--   - Many Enrolments belong to ONE Event (M:1)
--   - Many Enrolments belong to ONE Category (M:1)
-- ============================================================

CREATE TABLE Enrolment (
    EnrolmentID INT PRIMARY KEY IDENTITY(1,1),  -- PRIMARY KEY
    ParticipantID INT NOT NULL,  -- FOREIGN KEY to Participant
    EventID INT NOT NULL,        -- FOREIGN KEY to Event
    CategoryID INT NOT NULL,     -- FOREIGN KEY to Category
    EnrolmentDate DATETIME DEFAULT GETDATE(),
    
    -- FOREIGN KEY 1: Links Enrolment to Participant
    -- Cardinality: Many Enrolments : One Participant (M:1)
    CONSTRAINT FK_Enrolment_Participant FOREIGN KEY (ParticipantID) 
        REFERENCES Participant(ParticipantID) ON DELETE CASCADE,
    
    -- FOREIGN KEY 2: Links Enrolment to Event
    -- Cardinality: Many Enrolments : One Event (M:1)
    CONSTRAINT FK_Enrolment_Event FOREIGN KEY (EventID) 
        REFERENCES Event(EventID) ON DELETE CASCADE,
    
    -- FOREIGN KEY 3: Links Enrolment to Category
    -- Cardinality: Many Enrolments : One Category (M:1)
    CONSTRAINT FK_Enrolment_Category FOREIGN KEY (CategoryID) 
        REFERENCES Category(CategoryID) ON DELETE CASCADE,
    
    -- UNIQUE Constraint: Prevents duplicate enrolments
    CONSTRAINT UQ_Enrolment_Unique UNIQUE (ParticipantID, EventID, CategoryID)
);

PRINT '✓ Table "Enrolment" created successfully';
PRINT '   - PRIMARY KEY: EnrolmentID';
PRINT '   - FOREIGN KEY 1: ParticipantID → Participant(ParticipantID)';
PRINT '   - FOREIGN KEY 2: EventID → Event(EventID)';
PRINT '   - FOREIGN KEY 3: CategoryID → Category(CategoryID)';
PRINT '   - Cardinality: Many Enrolments : One Participant (M:1)';
PRINT '   - Cardinality: Many Enrolments : One Event (M:1)';
PRINT '   - Cardinality: Many Enrolments : One Category (M:1)';
PRINT '   - Resolves MANY-TO-MANY relationships';
PRINT '';
GO

-- ============================================================
-- TABLE 6: Result
-- ============================================================
-- PURPOSE: Stores race results for each enrolment.
-- RELATIONSHIPS: 
--   - One Result belongs to ONE Enrolment (1:1)
--   - EnrolmentID is UNIQUE to enforce 1:1 relationship
-- ============================================================

CREATE TABLE Result (
    ResultID INT PRIMARY KEY IDENTITY(1,1),  -- PRIMARY KEY
    EnrolmentID INT NOT NULL UNIQUE,  -- FOREIGN KEY with UNIQUE (enforces 1:1)
    FinishTime TIME,
    finishPosition INT,
    Status VARCHAR(10) DEFAULT 'DNS',
    
    -- FOREIGN KEY: Links Result to Enrolment
    -- Cardinality: One Result : One Enrolment (1:1)
    CONSTRAINT FK_Result_Enrolment FOREIGN KEY (EnrolmentID) 
        REFERENCES Enrolment(EnrolmentID) ON DELETE CASCADE,
    
    -- CHECK Constraint: Validates Status values
    CONSTRAINT CHK_Result_Status CHECK (Status IN ('Finished', 'DNF', 'DNS'))
);

PRINT '✓ Table "Result" created successfully';
PRINT '   - PRIMARY KEY: ResultID';
PRINT '   - FOREIGN KEY: EnrolmentID → Enrolment(EnrolmentID)';
PRINT '   - Cardinality: One Result : One Enrolment (1:1)';
PRINT '   - UNIQUE constraint on EnrolmentID enforces 1:1 relationship';
PRINT '';
GO

-- ============================================================
-- SECTION 3: CREATE INDEXES FOR PERFORMANCE
-- ============================================================

PRINT '========================================';
PRINT 'Creating Indexes for Performance';
PRINT '========================================';
PRINT '';

-- Index on Event.OrganiserID for faster joins
CREATE INDEX idx_event_organiser ON Event(OrganiserID);
PRINT '✓ Index created: Event.OrganiserID';

-- Index on Event.EventDate for faster date filtering
CREATE INDEX idx_event_date ON Event(EventDate);
PRINT '✓ Index created: Event.EventDate';

-- Index on Enrolment.ParticipantID for faster joins
CREATE INDEX idx_enrolment_participant ON Enrolment(ParticipantID);
PRINT '✓ Index created: Enrolment.ParticipantID';

-- Index on Enrolment.EventID for faster joins
CREATE INDEX idx_enrolment_event ON Enrolment(EventID);
PRINT '✓ Index created: Enrolment.EventID';

-- Index on Enrolment.CategoryID for faster joins
CREATE INDEX idx_enrolment_category ON Enrolment(CategoryID);
PRINT '✓ Index created: Enrolment.CategoryID';

-- Index on Result.EnrolmentID for faster joins
CREATE INDEX idx_result_enrolment ON Result(EnrolmentID);
PRINT '✓ Index created: Result.EnrolmentID';

-- Index on Result.finishPosition for faster sorting
CREATE INDEX idx_result_position ON Result(finishPosition);
PRINT '✓ Index created: Result.finishPosition';

PRINT '';
GO

-- ============================================================
-- SECTION 4: INSERT SAMPLE DATA
-- ============================================================

PRINT '========================================';
PRINT 'Inserting Sample Data';
PRINT '========================================';
PRINT '';

-- ============================================================
-- 4.1 Insert Organisers
-- ============================================================
PRINT '--- Inserting Organisers (3 records) ---';
INSERT INTO Organiser (UserName, Password, Email) VALUES
('john_organiser', 'hashed_password_1', 'john@raceday.com'),
('sarah_events', 'hashed_password_2', 'sarah@raceday.com'),
('mike_runs', 'hashed_password_3', 'mike@raceday.com');
PRINT '✓ 3 Organisers inserted';
PRINT '';
GO

-- ============================================================
-- 4.2 Insert Participants
-- ============================================================
PRINT '--- Inserting Participants (5 records) ---';
INSERT INTO Participant (EmailParticipants, PasswordParticipant, DateOfBirth) VALUES
('runner1@gmail.com', 'hashed_pass_1', '1990-05-15'),
('runner2@gmail.com', 'hashed_pass_2', '1985-08-22'),
('cyclist1@gmail.com', 'hashed_pass_3', '2000-12-01'),
('walker1@gmail.com', 'hashed_pass_4', '1995-03-10'),
('sprinter1@gmail.com', 'hashed_pass_5', '2002-07-19');
PRINT '✓ 5 Participants inserted';
PRINT '';
GO

-- ============================================================
-- 4.3 Insert Categories
-- ============================================================
PRINT '--- Inserting Categories (5 records) ---';
INSERT INTO Category (CategoryName, Description, Distance, fee, maxAge, minAge) VALUES
('5km Fun Run', 'Open category for all ages - perfect for beginners', 5.00, 50.00, 99, 0),
('10km Challenge', 'For serious runners looking for a challenge', 10.00, 100.00, 70, 16),
('Half Marathon', '21.1km endurance race for experienced runners', 21.10, 200.00, 65, 18),
('Kids Dash', 'Fun run for children under 12', 1.00, 30.00, 12, 4),
('42km Marathon', 'Full marathon - the ultimate challenge', 42.20, 300.00, 60, 20);
PRINT '✓ 5 Categories inserted';
PRINT '';
GO

-- ============================================================
-- 4.4 Insert Events
-- ============================================================
PRINT '--- Inserting Events (5 records) ---';
INSERT INTO Event (EventName, EventDate, EventType, distanceKM, maxParticipant, OrganiserID) VALUES
('Soweto Marathon 2026', '2026-09-15', 'Running', 42.20, 5000, 1),
('Cape Town Cycle Tour', '2026-03-10', 'Cycling', 109.00, 15000, 2),
('Durban City Run', '2026-07-20', 'Running', 10.00, 2000, 1),
('Johannesburg 5km Park Run', '2026-08-05', 'Running', 5.00, 1000, 3),
('Pretoria Half Marathon', '2026-10-12', 'Running', 21.10, 3000, 1);
PRINT '✓ 5 Events inserted';
PRINT '';
GO

-- ============================================================
-- 4.5 Insert Enrolments
-- ============================================================
PRINT '--- Inserting Enrolments (11 records) ---';
INSERT INTO Enrolment (ParticipantID, EventID, CategoryID, EnrolmentDate) VALUES
-- Soweto Marathon enrolments
(1, 1, 3, '2026-08-01 10:30:00'),  -- Runner1 in Half Marathon
(2, 1, 5, '2026-08-02 14:15:00'),  -- Runner2 in Full Marathon
(3, 1, 3, '2026-08-03 09:00:00'),  -- Cyclist1 in Half Marathon

-- Cape Town Cycle Tour enrolments
(3, 2, 3, '2026-02-01 11:00:00'),  -- Cyclist1 in Half Marathon
(1, 2, 2, '2026-02-02 16:30:00'),  -- Runner1 in 10km

-- Durban City Run enrolments
(1, 3, 2, '2026-06-15 08:45:00'),  -- Runner1 in 10km
(4, 3, 1, '2026-06-16 13:20:00'),  -- Walker1 in 5km

-- Johannesburg Park Run enrolments
(5, 4, 1, '2026-07-20 07:00:00'),  -- Sprinter1 in 5km
(4, 4, 1, '2026-07-21 09:30:00'),  -- Walker1 in 5km

-- Pretoria Half Marathon enrolments
(2, 5, 3, '2026-09-01 10:00:00'),  -- Runner2 in Half Marathon
(1, 5, 3, '2026-09-02 12:00:00');  -- Runner1 in Half Marathon
PRINT '✓ 11 Enrolments inserted';
PRINT '';
GO

-- ============================================================
-- 4.6 Insert Results
-- ============================================================
PRINT '--- Inserting Results (11 records) ---';
INSERT INTO Result (EnrolmentID, FinishTime, finishPosition, Status) VALUES
-- Soweto Marathon results
(1, '02:15:30', 45, 'Finished'),   -- Runner1 - Half Marathon
(2, '04:30:00', 120, 'Finished'),  -- Runner2 - Full Marathon
(3, NULL, NULL, 'DNS'),            -- Cyclist1 - Did Not Start

-- Cape Town Cycle Tour results
(4, '03:45:20', 200, 'Finished'),  -- Cyclist1 - Half Marathon
(5, '01:10:00', 35, 'Finished'),   -- Runner1 - 10km

-- Durban City Run results
(6, '00:45:30', 8, 'Finished'),    -- Runner1 - 10km
(7, '00:28:15', 15, 'Finished'),   -- Walker1 - 5km

-- Johannesburg Park Run results
(8, '00:22:00', 3, 'Finished'),    -- Sprinter1 - 5km
(9, NULL, NULL, 'DNF'),            -- Walker1 - Did Not Finish

-- Pretoria Half Marathon results (future event - no results yet)
(10, NULL, NULL, 'DNS'),           -- Runner2 - Not started yet
(11, NULL, NULL, 'DNS');           -- Runner1 - Not started yet
PRINT '✓ 11 Results inserted';
PRINT '';
GO

-- ============================================================
-- SECTION 5: DISPLAY ALL DATA
-- ============================================================

PRINT '========================================';
PRINT 'DISPLAYING ALL INSERTED DATA';
PRINT '========================================';
PRINT '';

-- ============================================================
-- 5.1 Display Organisers
-- ============================================================
PRINT '--- 1. ORGANISERS TABLE ---';
PRINT 'Primary Key: OrganiserID';
PRINT 'Foreign Keys: None';
PRINT 'Cardinality: One Organiser → Many Events';
PRINT '';
SELECT 
    OrganiserID AS 'PK: OrganiserID',
    UserName AS 'Username',
    Password AS 'Password (Hashed)',
    Email AS 'Email Address'
FROM Organiser;
PRINT '';
GO

-- ============================================================
-- 5.2 Display Participants
-- ============================================================
PRINT '--- 2. PARTICIPANTS TABLE ---';
PRINT 'Primary Key: ParticipantID';
PRINT 'Foreign Keys: None';
PRINT 'Cardinality: One Participant → Many Enrolments';
PRINT '';
SELECT 
    ParticipantID AS 'PK: ParticipantID',
    EmailParticipants AS 'Email',
    PasswordParticipant AS 'Password (Hashed)',
    DateOfBirth AS 'Date of Birth',
    DATEDIFF(YEAR, DateOfBirth, GETDATE()) AS 'Age'
FROM Participant;
PRINT '';
GO

-- ============================================================
-- 5.3 Display Categories
-- ============================================================
PRINT '--- 3. CATEGORIES TABLE ---';
PRINT 'Primary Key: CategoryID';
PRINT 'Foreign Keys: None';
PRINT 'Cardinality: One Category → Many Enrolments';
PRINT '';
SELECT 
    CategoryID AS 'PK: CategoryID',
    CategoryName AS 'Category Name',
    Description AS 'Description',
    Distance AS 'Distance (km)',
    fee AS 'Entry Fee (R)',
    minAge AS 'Min Age',
    maxAge AS 'Max Age'
FROM Category;
PRINT '';
GO

-- ============================================================
-- 5.4 Display Events
-- ============================================================
PRINT '--- 4. EVENTS TABLE ---';
PRINT 'Primary Key: EventID';
PRINT 'Foreign Key: OrganiserID → Organiser(OrganiserID)';
PRINT 'Cardinality: Many Events : One Organiser (M:1)';
PRINT 'Cardinality: One Event → Many Enrolments (1:M)';
PRINT '';
SELECT 
    e.EventID AS 'PK: EventID',
    e.EventName AS 'Event Name',
    e.EventDate AS 'Date',
    e.EventType AS 'Type',
    e.distanceKM AS 'Distance (km)',
    e.maxParticipant AS 'Max Participants',
    o.UserName AS 'Organiser (FK)',
    o.OrganiserID AS 'FK: OrganiserID'
FROM Event e
JOIN Organiser o ON e.OrganiserID = o.OrganiserID;
PRINT '';
GO

-- ============================================================
-- 5.5 Display Enrolments
-- ============================================================
PRINT '--- 5. ENROLMENTS TABLE ---';
PRINT 'Primary Key: EnrolmentID';
PRINT 'Foreign Keys:';
PRINT '  - ParticipantID → Participant(ParticipantID)';
PRINT '  - EventID → Event(EventID)';
PRINT '  - CategoryID → Category(CategoryID)';
PRINT 'Cardinality: Many Enrolments : One Participant (M:1)';
PRINT 'Cardinality: Many Enrolments : One Event (M:1)';
PRINT 'Cardinality: Many Enrolments : One Category (M:1)';
PRINT 'Purpose: Resolves MANY-TO-MANY relationships';
PRINT '';
SELECT 
    en.EnrolmentID AS 'PK: EnrolmentID',
    p.ParticipantID AS 'FK: ParticipantID',
    p.EmailParticipants AS 'Participant',
    e.EventID AS 'FK: EventID',
    e.EventName AS 'Event',
    c.CategoryID AS 'FK: CategoryID',
    c.CategoryName AS 'Category',
    en.EnrolmentDate AS 'Enrolment Date',
    CASE 
        WHEN r.Status IS NULL THEN 'Not Started'
        ELSE r.Status
    END AS 'Status'
FROM Enrolment en
JOIN Participant p ON en.ParticipantID = p.ParticipantID
JOIN Event e ON en.EventID = e.EventID
JOIN Category c ON en.CategoryID = c.CategoryID
LEFT JOIN Result r ON en.EnrolmentID = r.EnrolmentID
ORDER BY en.EnrolmentDate;
PRINT '';
GO

-- ============================================================
-- 5.6 Display Results
-- ============================================================
PRINT '--- 6. RESULTS TABLE ---';
PRINT 'Primary Key: ResultID';
PRINT 'Foreign Key: EnrolmentID → Enrolment(EnrolmentID)';
PRINT 'Cardinality: One Result : One Enrolment (1:1)';
PRINT 'UNIQUE constraint on EnrolmentID enforces 1:1 relationship';
PRINT '';
SELECT 
    r.ResultID AS 'PK: ResultID',
    r.EnrolmentID AS 'FK: EnrolmentID',
    p.EmailParticipants AS 'Participant',
    e.EventName AS 'Event',
    c.CategoryName AS 'Category',
    r.FinishTime AS 'Finish Time',
    r.finishPosition AS 'Position',
    r.Status AS 'Status'
FROM Result r
JOIN Enrolment en ON r.EnrolmentID = en.EnrolmentID
JOIN Participant p ON en.ParticipantID = p.ParticipantID
JOIN Event e ON en.EventID = e.EventID
JOIN Category c ON en.CategoryID = c.CategoryID
ORDER BY r.ResultID;
PRINT '';
GO

-- ============================================================
-- SECTION 6: RELATIONSHIP SUMMARY
-- ============================================================
PRINT '========================================';
PRINT 'RELATIONSHIP SUMMARY (Cardinalities)';
PRINT '========================================';
PRINT '';

PRINT '1. Organiser → Event (1:M)';
PRINT '   - One Organiser can create MANY Events';
PRINT '   - Implemented via Event.OrganiserID (FK)';
PRINT '';

PRINT '2. Participant → Enrolment (1:M)';
PRINT '   - One Participant can have MANY Enrolments';
PRINT '   - Implemented via Enrolment.ParticipantID (FK)';
PRINT '';

PRINT '3. Event → Enrolment (1:M)';
PRINT '   - One Event can have MANY Enrolments';
PRINT '   - Implemented via Enrolment.EventID (FK)';
PRINT '';

PRINT '4. Category → Enrolment (1:M)';
PRINT '   - One Category can have MANY Enrolments';
PRINT '   - Implemented via Enrolment.CategoryID (FK)';
PRINT '';

PRINT '5. Enrolment → Result (1:1)';
PRINT '   - One Enrolment has ONE Result';
PRINT '   - Implemented via Result.EnrolmentID (FK with UNIQUE)';
PRINT '';

PRINT '6. MANY-TO-MANY Relationships (Resolved by Enrolment):';
PRINT '   - Participant ⇔ Event (M:M) → Enrolment table';
PRINT '   - Participant ⇔ Category (M:M) → Enrolment table';
PRINT '   - Event ⇔ Category (M:M) → Enrolment table';
PRINT '';
GO

-- ============================================================
-- SECTION 7: DATABASE SUMMARY
-- ============================================================
PRINT '========================================';
PRINT 'DATABASE SUMMARY';
PRINT '========================================';
PRINT '';

SELECT 
    'Organisers' AS 'Table Name',
    COUNT(*) AS 'Records',
    'PK: OrganiserID' AS 'Primary Key',
    'None' AS 'Foreign Keys'
FROM Organiser
UNION ALL
SELECT 
    'Participants',
    COUNT(*),
    'PK: ParticipantID',
    'None'
FROM Participant
UNION ALL
SELECT 
    'Categories',
    COUNT(*),
    'PK: CategoryID',
    'None'
FROM Category
UNION ALL
SELECT 
    'Events',
    COUNT(*),
    'PK: EventID',
    'FK: OrganiserID'
FROM Event
UNION ALL
SELECT 
    'Enrolments',
    COUNT(*),
    'PK: EnrolmentID',
    'FK: ParticipantID, EventID, CategoryID'
FROM Enrolment
UNION ALL
SELECT 
    'Results',
    COUNT(*),
    'PK: ResultID',
    'FK: EnrolmentID'
FROM Result;

PRINT '';
PRINT '========================================';
PRINT '✓ DATABASE CREATION COMPLETE!';
PRINT '========================================';
PRINT '✓ Database Name: RaceDay_Database';
PRINT '✓ Filename: RaceDay_Database.sql';
PRINT '✓ 6 Tables created';
PRINT '✓ 7 Indexes created';
PRINT '✓ 40 Total records inserted';
PRINT '✓ All Primary Keys identified with PK: prefix';
PRINT '✓ All Foreign Keys identified with FK: prefix';
PRINT '✓ All Cardinalities displayed in output';
PRINT '✓ SQL Script matches ERD exactly';
PRINT '========================================';
GO