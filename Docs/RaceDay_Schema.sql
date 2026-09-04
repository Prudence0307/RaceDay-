/* ============================================================
   RaceDay Database Schema
   Target: SQL Server Management Studio (SSMS)
   This script creates the full schema for the RaceDay system
   and seeds it with sample data, matching /docs/ERD.png exactly.
   ============================================================ */

-- Uncomment and adjust if you want to create/use a dedicated database
-- CREATE DATABASE RaceDayDB;
-- GO
-- USE RaceDayDB;
-- GO

/* ------------------------------------------------------------
   Drop tables if they already exist (in dependency order)
   so the script can be re-run cleanly.
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.Results', 'U') IS NOT NULL DROP TABLE dbo.Results;
IF OBJECT_ID('dbo.Enrolments', 'U') IS NOT NULL DROP TABLE dbo.Enrolments;
IF OBJECT_ID('dbo.Routes', 'U') IS NOT NULL DROP TABLE dbo.Routes;
IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL DROP TABLE dbo.Categories;
IF OBJECT_ID('dbo.Events', 'U') IS NOT NULL DROP TABLE dbo.Events;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
GO

/* ------------------------------------------------------------
   1. USERS
   Holds both Organisers and Participants, distinguished by Role.
   ------------------------------------------------------------ */
CREATE TABLE dbo.Users (
    UserID          INT             IDENTITY(1,1)   NOT NULL,
    FullName        VARCHAR(100)    NOT NULL,
    Email           VARCHAR(150)    NOT NULL,
    PasswordHash    VARCHAR(255)    NOT NULL,
    Role            VARCHAR(20)     NOT NULL DEFAULT 'Participant',
    PhoneNumber     VARCHAR(20)     NULL,
    DateRegistered  DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Users PRIMARY KEY (UserID),
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT CK_Users_Role CHECK (Role IN ('Organiser', 'Participant', 'Admin'))
);
GO

/* ------------------------------------------------------------
   2. EVENTS
   Created by a User with Role = 'Organiser'.
   ------------------------------------------------------------ */
CREATE TABLE dbo.Events (
    EventID         INT             IDENTITY(1,1)   NOT NULL,
    OrganiserID     INT             NOT NULL,
    EventName       VARCHAR(150)    NOT NULL,
    EventDate       DATE            NOT NULL,
    Location        VARCHAR(150)    NOT NULL,
    Description     VARCHAR(MAX)    NULL,
    EventType       VARCHAR(20)     NOT NULL DEFAULT 'Running',
    CreatedAt       DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Events PRIMARY KEY (EventID),
    CONSTRAINT FK_Events_Organiser FOREIGN KEY (OrganiserID)
        REFERENCES dbo.Users(UserID),
    CONSTRAINT CK_Events_Type CHECK (EventType IN ('Running', 'Walking', 'Cycling'))
);
GO

/* ------------------------------------------------------------
   3. CATEGORIES
   Each Event has multiple distance/category options.
   ------------------------------------------------------------ */
CREATE TABLE dbo.Categories (
    CategoryID      INT             IDENTITY(1,1)   NOT NULL,
    EventID         INT             NOT NULL,
    CategoryName    VARCHAR(50)     NOT NULL,
    Distance        DECIMAL(5,2)    NOT NULL,
    EntryFee        DECIMAL(8,2)    NOT NULL DEFAULT 0,
    MaxParticipants INT             NOT NULL DEFAULT 500,
    CONSTRAINT PK_Categories PRIMARY KEY (CategoryID),
    CONSTRAINT FK_Categories_Event FOREIGN KEY (EventID)
        REFERENCES dbo.Events(EventID)
);
GO

/* ------------------------------------------------------------
   4. ROUTES
   One route per Category (1:1).
   ------------------------------------------------------------ */
CREATE TABLE dbo.Routes (
    RouteID         INT             IDENTITY(1,1)   NOT NULL,
    CategoryID      INT             NOT NULL,
    RouteName       VARCHAR(100)    NULL,
    StartPoint      VARCHAR(150)    NOT NULL,
    EndPoint        VARCHAR(150)    NOT NULL,
    ElevationGain   INT             NULL DEFAULT 0,
    MapURL          VARCHAR(255)    NULL,
    CONSTRAINT PK_Routes PRIMARY KEY (RouteID),
    CONSTRAINT FK_Routes_Category FOREIGN KEY (CategoryID)
        REFERENCES dbo.Categories(CategoryID),
    CONSTRAINT UQ_Routes_Category UNIQUE (CategoryID)
);
GO

/* ------------------------------------------------------------
   5. ENROLMENTS
   Resolves the many-to-many relationship between Users
   (Participants) and Categories.
   ------------------------------------------------------------ */
CREATE TABLE dbo.Enrolments (
    EnrolmentID     INT             IDENTITY(1,1)   NOT NULL,
    ParticipantID   INT             NOT NULL,
    CategoryID      INT             NOT NULL,
    EnrolmentDate   DATETIME        NOT NULL DEFAULT GETDATE(),
    Status          VARCHAR(20)     NOT NULL DEFAULT 'Confirmed',
    CONSTRAINT PK_Enrolments PRIMARY KEY (EnrolmentID),
    CONSTRAINT FK_Enrolments_Participant FOREIGN KEY (ParticipantID)
        REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_Enrolments_Category FOREIGN KEY (CategoryID)
        REFERENCES dbo.Categories(CategoryID),
    CONSTRAINT CK_Enrolments_Status CHECK (Status IN ('Pending', 'Confirmed', 'Cancelled')),
    CONSTRAINT UQ_Enrolments_Participant_Category UNIQUE (ParticipantID, CategoryID)
);
GO

/* ------------------------------------------------------------
   6. RESULTS
   One result per Enrolment (1:1).
   ------------------------------------------------------------ */
CREATE TABLE dbo.Results (
    ResultID        INT             IDENTITY(1,1)   NOT NULL,
    EnrolmentID     INT             NOT NULL,
    FinishTime      TIME            NULL,
    Position        INT             NULL,
    Status          VARCHAR(20)     NOT NULL DEFAULT 'Finished',
    CONSTRAINT PK_Results PRIMARY KEY (ResultID),
    CONSTRAINT FK_Results_Enrolment FOREIGN KEY (EnrolmentID)
        REFERENCES dbo.Enrolments(EnrolmentID),
    CONSTRAINT UQ_Results_Enrolment UNIQUE (EnrolmentID),
    CONSTRAINT CK_Results_Status CHECK (Status IN ('Finished', 'DNF', 'DSQ'))
);
GO

/* ============================================================
   SEED DATA
   ============================================================ */

-- 2 Organisers + 2 Participants (minimum required)
INSERT INTO dbo.Users (FullName, Email, PasswordHash, Role, PhoneNumber) VALUES
('Thabo Nkosi',      'thabo.nkosi@raceday.co.za',   'HASHED_PWD_1', 'Organiser',   '0821234567'),
('Lindiwe Dube',      'lindiwe.dube@raceday.co.za',  'HASHED_PWD_2', 'Organiser',   '0837654321'),
('Johan van der Merwe','johan.vdm@example.com',      'HASHED_PWD_3', 'Participant', '0721112222'),
('Naledi Mokoena',    'naledi.mokoena@example.com',  'HASHED_PWD_4', 'Participant', '0733334444');
GO

-- 3 Events (minimum required), one per organiser plus an extra
INSERT INTO dbo.Events (OrganiserID, EventName, EventDate, Location, Description, EventType) VALUES
(1, 'Polokwane Peace Run',    '2026-10-11', 'Polokwane, Limpopo',   'Annual community road running event through Polokwane.', 'Running'),
(2, 'Cape Winelands Cycle Tour', '2026-11-08', 'Stellenbosch, Western Cape', 'Scenic cycling tour through the Cape Winelands.', 'Cycling'),
(1, 'Bloemfontein Fun Walk',  '2026-09-20', 'Bloemfontein, Free State', 'Family-friendly charity fun walk in support of local schools.', 'Walking');
GO

-- Categories for each event
INSERT INTO dbo.Categories (EventID, CategoryName, Distance, EntryFee, MaxParticipants) VALUES
(1, '10km Run',   10.00, 150.00, 1000),
(1, '21km Half Marathon', 21.10, 250.00, 800),
(2, '50km Cycle Route',  50.00, 350.00, 500),
(2, '100km Cycle Route', 100.00, 500.00, 300),
(3, '5km Fun Walk', 5.00, 50.00, 1200);
GO

-- Routes (1:1 with categories)
INSERT INTO dbo.Routes (CategoryID, RouteName, StartPoint, EndPoint, ElevationGain, MapURL) VALUES
(1, 'City Loop 10km',      'Polokwane Civic Centre', 'Polokwane Civic Centre', 120, 'https://maps.example.com/route1'),
(2, 'Half Marathon Route', 'Polokwane Civic Centre', 'Nirvana Stadium',        260, 'https://maps.example.com/route2'),
(3, 'Winelands 50km',      'Stellenbosch Square',    'Franschhoek Village',    480, 'https://maps.example.com/route3'),
(4, 'Winelands 100km',     'Stellenbosch Square',    'Stellenbosch Square',    920, 'https://maps.example.com/route4'),
(5, 'Fun Walk Route',      'Bloemfontein City Hall', 'Free State Stadium',      30, 'https://maps.example.com/route5');
GO

-- Sample enrolments (participants entering categories)
INSERT INTO dbo.Enrolments (ParticipantID, CategoryID, Status) VALUES
(3, 1, 'Confirmed'),  -- Johan enters 10km Run
(3, 3, 'Confirmed'),  -- Johan enters 50km Cycle
(4, 2, 'Confirmed'),  -- Naledi enters 21km Half Marathon
(4, 5, 'Confirmed');  -- Naledi enters 5km Fun Walk
GO

-- Sample results for completed enrolments
INSERT INTO dbo.Results (EnrolmentID, FinishTime, Position, Status) VALUES
(1, '00:52:30', 15, 'Finished'),
(3, '01:48:12', 8,  'Finished');
GO

/* ============================================================
   Quick verification queries (optional - comment out before submission
   if your rubric requires a script with no SELECT statements)
   ============================================================ */
-- SELECT * FROM dbo.Users;
-- SELECT * FROM dbo.Events;
-- SELECT * FROM dbo.Categories;
-- SELECT * FROM dbo.Routes;
-- SELECT * FROM dbo.Enrolments;
-- SELECT * FROM dbo.Results;
