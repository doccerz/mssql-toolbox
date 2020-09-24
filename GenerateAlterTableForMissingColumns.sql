;WITH TBL AS
(SELECT
     TABLE_CATALOG
    ,TABLE_SCHEMA
    ,TABLE_NAME
    ,COLUMN_NAME
	,DOMAIN_NAME
	,DATA_TYPE
	,I.CHARACTER_MAXIMUM_LENGTH
	,I.NUMERIC_PRECISION
	,I.NUMERIC_SCALE
	,DTYP = CASE WHEN DOMAIN_NAME IS NULL THEN DATA_TYPE + '()' ELSE DOMAIN_NAME END
	,isNullPhrase = CASE IS_NULLABLE WHEN 'NO' THEN ' NOT ' ELSE '' END + ' NULL '
	,PRCSN = IsNull('('+
				CASE WHEN CHARACTER_MAXIMUM_LENGTH IS NULL 
					THEN CAST(NUMERIC_PRECISION AS VARCHAR)+ ',' + CAST(NUMERIC_SCALE AS VARCHAR)
					ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR)
				END
				+')','')
FROM INFORMATION_SCHEMA.COLUMNS I
WHERE TABLE_NAME = 'AR_CUST' AND TABLE_SCHEMA = 'DBO')
SELECT 
	SCRIPT = 'IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '''+TABLE_NAME+''' AND COLUMN_NAME = '''+COLUMN_NAME+''') BEGIN '+ 'ALTER TABLE ['+TABLE_SCHEMA+'].['+TABLE_NAME+'] ADD ['+COLUMN_NAME+'] '+ REPLACE(DTYP, '()', PRCSN) + isNullPhrase + ' END'
FROM TBL
