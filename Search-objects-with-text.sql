SELECT OBJECT_NAME(OBJECT_ID) 
FROM   SYS.SQL_MODULES  S
WHERE  1 = 1
       AND DEFINITION LIKE '%not stocked at location%' 
ORDER BY 1
/*
sp_helptext USER_TR_IM_ADJ_HIST
*/