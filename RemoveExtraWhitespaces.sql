/****** Object:  StoredProcedure [v2].[WS_FullPIDetails]    Script Date: 07/12/2023 8:51:39 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:      <Mohammed>  
-- Create Date: <09/23/2019>  
-- Description: <To retrieve full monograph details by monograph id> 
-- Change Log: 
-- 2 July 2021 Lik Siong: Included NOT Deleted Monograph Content by adding b.StatusChanged <> 'Deleted' check
-- 23 Nov 2023 Alvin Patron: Add replace support to trim \r\n and \t in new format Full PI
-- 06 Dec 2023 Alvin Patron: Remove extra whitespaces for TGA <> 1
-- =============================================  
ALTER   PROCEDURE [v2].[WS_FullPIDetails]  
(  
    -- Add the parameters for the stored procedure here  
    @MonographId  varchar(40)  
)  
AS  
BEGIN  
    -- SET NOCOUNT ON added to prevent extra result sets from  
    -- interfering with SELECT statements.  
    SET NOCOUNT ON  
  
 DECLARE @IS_TGA BIT  
 DECLARE @BlackTraiangle NVARCHAR(MAX)  
  
 SELECT @BlackTraiangle = N'&#9660; This medicinal product is subject to additional monitoring in Australia. This will allow quick identification of new safety information. Healthcare professionals are asked to report any suspected adverse events at www.tga.gov.au/reporting-problems.'  
 SELECT @IS_TGA = AU_IsTGA  FROM [dbo].[Monograph] WHERE Id = @MonographId  
    -- Insert statements for procedure here  
 IF(@IS_TGA = 1)  
 BEGIN  
	SELECT m.Id AS 'FullPIId'  
	, REPLACE(m.DisplayName,'&amp;','&') AS 'FullPIName'
	, b.Id AS 'BrandId'  
	, b.Name AS 'BrandName'  
	, IIF(b.AU_IsBlackTriangle=0,'false',@BlackTraiangle) AS 'BlackTriangle'  
	, 'Content'  
	, m.AU_IsTGA  
	, CONVERT(varchar, tga.TgaApprovalDate, 126) AS 'TGAApprovalDate'  
	, CONVERT(varchar, tga.TgaAmendmentDate, 126) AS 'TGAAmendmentDate'  
	, CASE WHEN tga.RevisedDate IS NULL THEN CONVERT(varchar, tga.NewDate, 126)
			ELSE CONVERT(varchar, tga.RevisedDate, 126)
			END AS 'MimsRevisionDate'  
	FROM [dbo].[Monograph] m  
	INNER JOIN [dbo].[rel_Brand_Monograph] rbm ON rbm.MonographId = m.Id  
	INNER JOIN [dbo].[Brand] b ON b.Id = rbm.BrandId  
	INNER JOIN [dbo].[TGAMonograph] tga ON tga.MonographId = m.Id  
	WHERE m.Id = @MonographId  
	AND m.MonographTypeCT = '8b29f44d-26c7-47c6-8a65-a32100c8190d' 
	AND (b.StatusChanged IS NULL OR b.StatusChanged <> 'Deleted')
	ORDER BY b.Name

	SELECT
		t.Header, 
		dbo.RemoveExtraWhitespaces(REPLACE(t.Value, N'</monoref><monoref', N'</monoref> <monoref')) AS 'Text',
		t.SubContent AS 'IsSubContent' 
	FROM (
		SELECT
			t.Headings AS 'Header', 
			d.[Value], 
			t.SubContent,
			t.DisplayOrder
		FROM [dbo].[TGAMonographTemplate] t 
			LEFT JOIN [dbo].[TGAMonographSection] s ON LTRIM(RTRIM(s.SectionName)) = LTRIM(RTRIM(t.Headings)) AND  s.MonographId = @MonographId 
			LEFT JOIN [dbo].[TGAMonographSectionData] d ON s.MonographSectionId = d.MonographSectionId 
		UNION
		SELECT
			'References' AS 'Header',
			m.[AU_References] AS [Value],
			0 AS SubContent,
			31 DisplayOrder
		FROM [dbo].[Monograph] m WHERE
			m.[Id] = @MonographId
	) t
	ORDER BY t.DisplayOrder
 END  
 ELSE  
 BEGIN  
	SELECT m.Id AS 'FullPIId' 
	, REPLACE(m.DisplayName,'&amp;','&') AS 'FullPIName'
	, b.Id AS 'BrandId'  
	, b.Name AS 'BrandName'  
	, IIF(b.AU_IsBlackTriangle=0,'false',@BlackTraiangle) AS 'BlackTriangle'  
	, 'Content'  
	, m.AU_IsTGA  
	, CONVERT(varchar, m.AU_TGAApproveDate, 126) AS 'TGAApprovalDate'  
	, CONVERT(varchar, m.AU_ReferenceDate, 126) AS 'TGAAmendmentDate'  
	--, CONVERT(varchar, m.AU_ChangeDate, 126) AS 'MimsRevisionDate' 
	, CASE WHEN m.AU_ChangeDate IS NULL THEN CONVERT(varchar, m.AU_CreateDate, 126)
			ELSE CONVERT(varchar, m.AU_ChangeDate, 126)
			END AS 'MimsRevisionDate'
	FROM [dbo].[Monograph] m  
	INNER JOIN [dbo].[rel_Brand_Monograph] rbm ON rbm.MonographId = m.Id  
	INNER JOIN [dbo].[Brand] b ON b.Id = rbm.BrandId  
	WHERE m.Id = @MonographId  
	AND m.MonographTypeCT = '8b29f44d-26c7-47c6-8a65-a32100c8190d' 
	AND (b.StatusChanged IS NULL OR b.StatusChanged <> 'Deleted')
  
	SELECT  
	dbo.RemoveExtraWhitespaces(m.BoxedWarning) AS 'Boxed warning'  
	, dbo.RemoveExtraWhitespaces(m.Content + ' ' + ISNULL(m.ChemicalStructure,'')) AS 'Name of the medicine'   
	, dbo.RemoveExtraWhitespaces(m.Description) AS 'Description'
	, dbo.RemoveExtraWhitespaces(m.Action) AS 'Actions'  
	, dbo.RemoveExtraWhitespaces(m.Pharmacology) AS Pharmacology
	, dbo.RemoveExtraWhitespaces(m.AU_ClinicalTrials) AS 'Clinical Trials'  
	, dbo.RemoveExtraWhitespaces(m.Indication) AS 'Indications'  
	, dbo.RemoveExtraWhitespaces(m.ContraIndication) AS 'Contraindications'  
	, dbo.RemoveExtraWhitespaces(m.Warning) AS 'Warnings'  
	, dbo.RemoveExtraWhitespaces(m.Precaution) AS 'Precautions'  
	, dbo.RemoveExtraWhitespaces(m.DrugInteraction) AS 'Interactions'  
	, dbo.RemoveExtraWhitespaces(m.AdverseReaction) AS 'Adverse effects'  
	, dbo.RemoveExtraWhitespaces(m.Dosage) AS 'Dosage and Administration'  
	, dbo.RemoveExtraWhitespaces(m.OverDosage) AS 'Overdosage'  
	, dbo.RemoveExtraWhitespaces(m.Presentation) AS Presentation
	, dbo.RemoveExtraWhitespaces(m.AU_DirectionOfUse) AS 'Directions for Use'  
	, dbo.RemoveExtraWhitespaces(m.Storage) AS Storage
	, dbo.RemoveExtraWhitespaces(m.AU_References) AS 'Reference'  
	, dbo.RemoveExtraWhitespaces(m.PoisonClass) AS 'Poison schedule' 
	FROM [dbo].[Monograph] m  
	WHERE m.Id = @MonographId  
	AND m.MonographTypeCT = '8b29f44d-26c7-47c6-8a65-a32100c8190d'  

 END  

END
