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
PRINT N'Altering Table [dbo].[MTCGCard]...';


GO
ALTER TABLE [dbo].[MTCGCard]
    ADD [isTraded] BIT DEFAULT 0 NOT NULL;


GO
PRINT N'Creating Foreign Key [dbo].[FK_Deal_ToCardID]...';


GO
ALTER TABLE [dbo].[MTCGDeals] WITH NOCHECK
    ADD CONSTRAINT [FK_Deal_ToCardID] FOREIGN KEY ([CardToTrade]) REFERENCES [dbo].[MTCGCard] ([CardID]);


GO
PRINT N'Refreshing View [dbo].[CardOwners]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[CardOwners]';


GO
PRINT N'Altering Procedure [dbo].[add_cards_to_deck]...';


GO
ALTER PROCEDURE [dbo].[add_cards_to_deck]
	@FirstCard nvarchar(50),
	@SecondCard nvarchar(50),
	@ThirdCard nvarchar(50),
	@FourthCard nvarchar(50),
	@Username nvarchar(50)
AS

BEGIN


	IF NOT EXISTS(SELECT * FROM dbo.MTCGCard WHERE CardID = @FirstCard AND Username = @Username AND isTraded = 0)
	BEGIN
		RAISERROR('Card 1 is not in users posession or is being traded',16,1);
		RETURN
	END

	IF NOT EXISTS(SELECT * FROM dbo.MTCGCard WHERE CardID = @SecondCard AND Username = @Username AND isTraded = 0)
	BEGIN
		RAISERROR('Card 2 is not in users posession or is being traded',16,1);
		RETURN
	END

	IF NOT EXISTS(SELECT * FROM dbo.MTCGCard WHERE CardID = @ThirdCard AND Username = @Username AND isTraded = 0)
	BEGIN
		RAISERROR('Card 3 is not in users posession or is being traded',16,1);
		RETURN
	END

	IF NOT EXISTS(SELECT * FROM dbo.MTCGCard WHERE CardID = @FourthCard AND Username = @Username AND isTraded = 0)
	BEGIN
		RAISERROR('Card 4 is not in users posession or is being traded',16,1);
		RETURN
	END

	UPDATE dbo.MTCGUser SET FirstCard = @FirstCard, SecondCard = @SecondCard, ThirdCard = @ThirdCard, FourthCard = @FourthCard WHERE Username = @Username


END
GO
PRINT N'Altering Procedure [dbo].[create_trade]...';


GO
ALTER PROCEDURE [dbo].[create_trade]
	@Username nvarchar(50),
	@Id nvarchar(50),
	@CardToTrade nvarchar(50),
	@isSpell bit,
	@MinDmg int
AS

BEGIN TRANSACTION


	IF((SELECT COUNT(*)
		 FROM dbo.MTCGCard
		 WHERE Username = @Username AND CardID = @CardToTrade) = 0)
	BEGIN
		RAISERROR('Card is not in users possesion',16,1);
		RETURN
	END

	IF((SELECT COUNT(*) from (SELECT  * from dbo.MTCGDeals WHERE Id = @Id) x) != 0)
	BEGIN
		RAISERROR('Trade deal with provided ID already exists',16,1);
		RETURN
	END

	IF((SELECT COUNT(*) from (SELECT FirstCard, SecondCard, ThirdCard, FourthCard
		FROM dbo.MTCGUser
		WHERE FirstCard = @CardToTrade OR SecondCard = @CardToTrade OR ThirdCard = @CardToTrade OR FourthCard = @CardToTrade) x) != 0)
	BEGIN
		RAISERROR('Card is registered in users deck therefore it cannnot be traded',16,1);
		RETURN
	END

	ELSE

	BEGIN

	INSERT INTO dbo.MTCGDeals (Id,CardToTrade,isSpell,MinDmg) values (@Id,@CardToTrade,@isSpell,@MinDmg)
	
	UPDATE dbo.MTCGCard SET isTraded = 1 WHERE CardID = @CardToTrade;
	
	END


COMMIT TRANSACTION
GO
PRINT N'Refreshing Procedure [dbo].[acquire_package]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[acquire_package]';


GO
PRINT N'Refreshing Procedure [dbo].[delete_db_records]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[delete_db_records]';


GO
PRINT N'Refreshing Procedure [dbo].[reset_card_owners]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[reset_card_owners]';


GO
PRINT N'Checking existing data against newly created constraints';


GO
USE [$(DatabaseName)];


GO
ALTER TABLE [dbo].[MTCGDeals] WITH CHECK CHECK CONSTRAINT [FK_Deal_ToCardID];


GO
PRINT N'Update complete.';


GO
