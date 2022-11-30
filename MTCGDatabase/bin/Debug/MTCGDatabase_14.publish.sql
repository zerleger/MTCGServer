﻿/*
Deployment script for MTCG_DB

This code was generated by a tool.
Changes to this file may cause incorrect behavior and will be lost if
the code is regenerated.
*/

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;


GO
:setvar DatabaseName "MTCG_DB"
:setvar DefaultFilePrefix "MTCG_DB"
:setvar DefaultDataPath "C:\Users\wikto\AppData\Local\Microsoft\Microsoft SQL Server Local DB\Instances\MSSQLLocalDB\"
:setvar DefaultLogPath "C:\Users\wikto\AppData\Local\Microsoft\Microsoft SQL Server Local DB\Instances\MSSQLLocalDB\"

GO
:on error exit
GO
/*
Detect SQLCMD mode and disable script execution if SQLCMD mode is not supported.
To re-enable the script after enabling SQLCMD mode, execute the following:
SET NOEXEC OFF; 
*/
:setvar __IsSqlCmdEnabled "True"
GO
IF N'$(__IsSqlCmdEnabled)' NOT LIKE N'True'
    BEGIN
        PRINT N'SQLCMD mode must be enabled to successfully execute this script.';
        SET NOEXEC ON;
    END


GO
USE [$(DatabaseName)];


GO
/*
The column [dbo].[MTCGCard].[UserID] is being dropped, data loss could occur.

The column [dbo].[MTCGCard].[Username] on table [dbo].[MTCGCard] must be added, but the column has no default value and does not allow NULL values. If the table contains data, the ALTER script will not work. To avoid this issue you must either: add a default value to the column, mark it as allowing NULL values, or enable the generation of smart-defaults as a deployment option.
*/

IF EXISTS (select top 1 1 from [dbo].[MTCGCard])
    RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

GO
/*
The column [dbo].[MTCGUser].[UserID] is being dropped, data loss could occur.
*/

IF EXISTS (select top 1 1 from [dbo].[MTCGUser])
    RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

GO
PRINT N'Dropping Foreign Key [dbo].[FK_Card_ToUser]...';


GO
ALTER TABLE [dbo].[MTCGCard] DROP CONSTRAINT [FK_Card_ToUser];


GO
PRINT N'Altering Table [dbo].[MTCGCard]...';


GO
ALTER TABLE [dbo].[MTCGCard] DROP COLUMN [UserID];


GO
ALTER TABLE [dbo].[MTCGCard]
    ADD [Username] NVARCHAR (50) NOT NULL;


GO
PRINT N'Starting rebuilding table [dbo].[MTCGUser]...';


GO
BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

CREATE TABLE [dbo].[tmp_ms_xx_MTCGUser] (
    [Username] NVARCHAR (50) NOT NULL,
    [Password] NVARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([Username] ASC)
);

IF EXISTS (SELECT TOP 1 1 
           FROM   [dbo].[MTCGUser])
    BEGIN
        INSERT INTO [dbo].[tmp_ms_xx_MTCGUser] ([Username], [Password])
        SELECT   [Username],
                 [Password]
        FROM     [dbo].[MTCGUser]
        ORDER BY [Username] ASC;
    END

DROP TABLE [dbo].[MTCGUser];

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_MTCGUser]', N'MTCGUser';

COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;


GO
PRINT N'Creating Foreign Key [dbo].[FK_Card_ToUser]...';


GO
ALTER TABLE [dbo].[MTCGCard] WITH NOCHECK
    ADD CONSTRAINT [FK_Card_ToUser] FOREIGN KEY ([Username]) REFERENCES [dbo].[MTCGUser] ([Username]);


GO
PRINT N'Refreshing View [dbo].[CardOwners]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[CardOwners]';


GO
PRINT N'Checking existing data against newly created constraints';


GO
USE [$(DatabaseName)];


GO
ALTER TABLE [dbo].[MTCGCard] WITH CHECK CHECK CONSTRAINT [FK_Card_ToUser];


GO
PRINT N'Update complete.';


GO
