UPDATE dbo.aspnet_Membership
SET IsLockedOut = 0, FailedPasswordAttemptCount = 0, LastPasswordChangedDate = GETDATE(), [Password] = 'Baritone123', PasswordFormat = 0
WHERE Email like '%silver%'