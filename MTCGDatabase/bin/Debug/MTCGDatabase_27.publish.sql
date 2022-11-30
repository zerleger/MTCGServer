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
PRINT N'Altering Procedure [dbo].[acquire_package]...';


GO
ALTER PROCEDURE [dbo].[acquire_package]
	@Username nvarchar(50)
AS

BEGIN TRANSACTION


	IF((SELECT Coins
		 FROM dbo.MTCGUser
		 WHERE Username = @Username) < 5)
	BEGIN
		RAISERROR('Coin balance is too low',16,1);
	END

	ELSE
	BEGIN

	UPDATE dbo.MTCGUser
	SET Coins = Coins - 5
	WHERE Username = @Username;

	UPDATE top (5) dbo.MTCGCard
	SET Username = @Username
	WHERE Username is NULL;
	END


COMMIT TRANSACTION
GO
PRINT N'Update complete.';


GO
