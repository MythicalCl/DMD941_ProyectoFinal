USE DMD941_Superstore_DW;
GO

CREATE OR ALTER FUNCTION dbo.fn_to_date (@value NVARCHAR(100))
RETURNS DATE
AS
BEGIN
    DECLARE @result DATE;
    DECLARE @num FLOAT;

    SET @result = COALESCE(
        TRY_CONVERT(DATE, @value, 103),
        TRY_CONVERT(DATE, @value, 101),
        TRY_CONVERT(DATE, @value, 120),
        TRY_CONVERT(DATE, @value)
    );

    SET @num = TRY_CONVERT(FLOAT, @value);

    IF @result IS NULL AND @num IS NOT NULL AND @num BETWEEN 20000 AND 60000
    BEGIN
        SET @result = DATEADD(DAY, CONVERT(INT, @num) - 2, '19000101');
    END

    RETURN @result;
END;
GO