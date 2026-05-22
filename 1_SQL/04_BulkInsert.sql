USE DMD941_Superstore_DW;
GO

BULK INSERT dbo.raw_superstore
FROM 'C:\Users\Mythical\OneDrive - Universidad Don Bosco\UDB\Ciclo 2\DMD941\Proyecto Final\2_Data\Superstore_DMD941.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO