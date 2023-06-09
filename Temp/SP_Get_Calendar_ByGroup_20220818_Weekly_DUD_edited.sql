USE [WorkFlow]
GO
/****** Object:  StoredProcedure [DASHBOARD].[SP_Get_Calendar_ByGroup_20220818_Weekly]    Script Date: 5/19/2023 12:17:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [DASHBOARD].[SP_Get_Calendar_ByGroup_20220818_Weekly](@UserID Varchar(10), @ShowAll Integer = 0, @StartDate Varchar(10), @EndDate Varchar(10), 
	@OfficeID Integer = 0, @SalesLineID Integer = 0, @TitleID Integer = 0, @GroupID Integer = 0,
	@TimeOffStatusCd Integer = 0, @EmpTypeID Integer = 0) AS
BEGIN
--Created:Han(8/29/22) - Created using DASHBOARD.SP_Get_Calendar_ByGroup_20220818 due to speical weekly format for fullcalendar

/* Modified:Han(9/6/19) - Added @TimeOffStatusCd and @EmpTypeID
	-. @TimeOffStatusCd: 0: All, 1: Sales Call, 2: Day-Off, 3) Time-Off
	-. @EmpTypeID: 0: All, 1: Corporate(Admin), 2: Sales, 3: Marketing
*/

--Calendar Source: EMS.dbo.Card_Upload
--SELECT * from EMS.dbo.ADP_Calendar
--DECLARE @UserID Varchar(10) = '10023', @ShowAll Integer = 0, @StartDate Varchar(10) = Convert(Varchar(10), DateAdd(m, -1, GetDate()),120), @EndDate Varchar(10) = Convert(Varchar(10), DateAdd(m, 2, GetDate()),120)
--DECLARE @UserID Varchar(10) = '10660', @ShowAll Integer = 1
--DECLARE @OfficeID Integer = 0, @SalesLineID Integer = 0, @TitleID Integer = 0

--DECLARE @UserID Varchar(10) = '10023', @ShowAll Integer = 0, @StartDate Varchar(10) = '2019-06-02', @EndDate Varchar(10) = '2019-06-07', @OfficeID Integer = 0, @SalesLineID Integer = 0, @TitleID Integer = 0, @GroupID Integer = 0
--DECLARE @UserID Varchar(10) = '10013', @ShowAll Integer = 0, @StartDate Varchar(10) = '2019-06-02', @EndDate Varchar(10) = '2019-06-07', @OfficeID Integer = 0, @SalesLineID Integer = 0, @TitleID Integer = 0, @GroupID Integer = 0
--DECLARE @UserID Varchar(10) = '10902', @ShowAll Integer = 0, @StartDate Varchar(10) = '2021-02-01', @EndDate Varchar(10) = '2021-02-26', @OfficeID Integer = 0, @SalesLineID Integer = 0, @TitleID Integer = 0, @GroupID Integer = 0
--DECLARE @UserID Varchar(10) = '10250', @ShowAll Integer = 0, @StartDate Varchar(10) = '2022-08-18', @EndDate Varchar(10) = '2022-08-20', @OfficeID Integer = 0, @SalesLineID Integer = 0, @TitleID Integer = 0, @GroupID Integer = 0
--DECLARE @UserID Varchar(10) = '99999', @ShowAll Integer = 0, @StartDate Varchar(10) = '2022-08-22', @EndDate Varchar(10) = '2022-08-23', @OfficeID Integer = 23, @SalesLineID Integer = 0, @TitleID Integer = 0, @GroupID Integer = 0
--DECLARE @UserID Varchar(10) = '99999', @ShowAll Integer = 0, @StartDate Varchar(10) = '2022-09-11', @EndDate Varchar(10) = '2022-09-17', @OfficeID Integer = 31, @SalesLineID Integer = 0, @TitleID Integer = 0, @GroupID Integer = 0
--DECLARE @TimeOffStatusCd Integer = 0, @EmpTypeID Integer = 0

SET NOCOUNT ON;

--Modified:Han(9/1/22) - Added to log the usage
DECLARE @LogUserID Varchar(10) = @UserID
If (@UserID = '99999') SET @LogUserID = @ShowAll
--Modified:Han(9/15/22) - Added NTLogInUserID
Insert Into EMS.dbo.Calendar_Usage (CalendarType, UserID, NTLogInUserID) Values ('KEYENCE_SCH_WK', @LogUserID, @ShowAll)

--If (@UserID = '99999') SET @ShowAll = 1

If (@UserID = '99999') GoTo SearchByFilters;

/*Modified:Han(9/20/22) - Based on EmployeeID
--Modified:Han(11/8/19) - New special group of employees to access sales calls
DECLARE @AdminEmpTab TABLE (EmployeeID Varchar(10))
INSERT INTO @AdminEmpTab Values ('10013')
INSERT INTO @AdminEmpTab Values ('11565')
INSERT INTO @AdminEmpTab Values ('11722')
--Modified:Han(12/14/20) - Added Yosuke(11566) based on the email from Shinji on 12/14/20
INSERT INTO @AdminEmpTab Values ('11566')
--Modified:Han(12/5/19) - Added IMMs to allow Salce Call access based on email from Mike on 12/5
INSERT INTO @AdminEmpTab 
Select EmployeeID From EMS.V_CurrentEmpInfo IMM 
Where TitleID = 14 and Not Exists (Select 1 From @AdminEmpTab A WHERE A.EmployeeID = IMM.EmployeeID)

--Modified:Han(11/8/19) - Total filters' ID sum
DECLARE @TotSumOfIDs Integer
SET @TotSumOfIDs = @OfficeID + @SalesLineID + @TitleID + @GroupID
*/

--Modified:Han(6/4/19) - Added
DECLARE @EmpTable TABLE (EmployeeHierID Integer, EmployeeID Varchar(10), EmployeeName Varchar(50), 
	ApprTitleTypeID Integer, EmployeeTitleName Varchar(20), EmployeeTitleDescr Varchar(100)) 

/*Modified:Han(9/20/22) - Based on EmployeeID
--Modified:Han(11/8/19) - To allow special group to access sales calls
--INSERT INTO @EmpTable Exec KeyFlow.SP_Confirm_Employee_Hierarchy_ByManager @UserID
If EXISTS (Select 1 From @AdminEmpTab Where EmployeeID = @UserID)
	INSERT INTO @EmpTable Exec KeyFlow.SP_Confirm_Employee_Hierarchy_ByManager '10013'
Else
	INSERT INTO @EmpTable Exec KeyFlow.SP_Confirm_Employee_Hierarchy_ByManager @UserID
*/

INSERT INTO @EmpTable Exec KeyFlow.SP_Confirm_Employee_Hierarchy_ByManager @UserID

/*Modified:Han(9/20/22) - Based on EmployeeID
--Modified:Han(12/14/20) - Added for CSM Managers, by email from Shinji on 12/8/20
INSERT INTO @EmpTable
SELECT 4, EMS.EmployeeID, E.EmployeeName, EMS.TitleID, TL.TitleShort, EMS.TitleName
FROM EMS.V_CurrentEmpInfo EMS
	JOIN V_Employeedepartmentlist E ON E.EmployeeID = EMS.EmployeeID AND EMS.GrpID = 8
	JOIN EMS.dbo.ADP_TitleTable TL WITH(NOLOCK) ON TL.TitleID = EMS.TitleID
WHERE Not Exists (Select 1 From @EmpTable T WHERE T.EmployeeID = EMS.EmployeeID)
	AND Exists (Select 1 From EMS.V_CSM_Manager M WHERE M.EmployeeID = @UserID)

--Modified:Han(1/4/21) - Added for CSM(8) & OPS(26) to access dept's members
INSERT INTO @EmpTable
SELECT 999, E.EmployeeID, E.NickName + ' ' + E.LastName, E.TitleID, T.TitleShort, T.TitleName
FROM EMS.V_CurrentEmpInfo E 
	JOIN EMS.dbo.ADP_TitleTable T WITH(NOLOCK) ON T.TitleID = E.TitleID 
	JOIN DASHBOARD.Calendar_Dept_Access DA WITH(NOLOCK) ON DA.EMSGrpID = E.GrpID
WHERE EXISTS (Select 1 From EMS.V_CurrentEmpInfo EMS
	WHERE EMS.EmployeeID = @UserID AND EMS.GrpID = E.GrpID)
	AND Not Exists (Select 1 From @EmpTable T WHERE T.EmployeeID = E.EmployeeID)
*/
--Modified:Han(9/23/22) - Added CG alias, MISQ#:59898
SearchByFilters:
	INSERT INTO @EmpTable
	Select 1, E.EmployeeID, E.NickName + ' ' + E.LastName, E.TitleID, T.TitleShort, T.TitleName
	From EMS.V_CurrentEmpInfo E
		JOIN EMS.dbo.ADP_TitleTable T WITH(NOLOCK) ON T.TitleID = E.TitleID 
	WHERE @UserID = '99999' 
		AND (@OfficeID = 0 OR E.LocID = @OfficeID) 
		AND (@SalesLineID = 0 OR E.SFASalesLineID = @SalesLineID) 
		AND (@TitleID = 0 OR E.TitleID = @TitleID) 
		AND (@GroupID = 0 
			OR E.GrpID = @GroupID
			OR Exists (Select 1 From DASHBOARD.KeyCalendar_Group CG WITH(NOLOCK) WHERE CG.EMSCalendarGrpID = @GroupID AND CG.EMSGrpID = E.GrpID)
			OR Exists (Select 1 From DASHBOARD.KeyCalendar_Group CG WITH(NOLOCK) WHERE CG.EMSGrpID = @GroupID AND CG.EMSCalendarGrpID = E.GrpID) ) 
		AND (@EmpTypeID = 0 OR E.EmpTypeID = @EmpTypeID)

--Modified:Han(6/23/21) - Added UploadDate
DECLARE @UploadDate Varchar(30) = ''
Select Top 1 @UploadDate = '<br/>Loaded on ' + FORMAT(UploadDate,'MM/dd/yy hh:mm') From ems.dbo.Card_SFUpload

--Temp table to save
IF OBJECT_ID(N'tempdb..#TempCalendarEvent') IS NOT NULL DROP TABLE #TempCalendarEvent
--Modified:Han(9/14/22) - Added MType
Create table #TempCalendarEvent (
  Event_ID Integer, Description Varchar(200), Title Varchar(100), 
  Event_Start DateTime, Event_End DateTime, All_Day smallint, 
	BackgroundColor varchar(10), CalendarGroup varchar(30),
	ResourceID varchar(10), EmployeeName varchar(100), 
	CalType varchar(20), StartTime varchar(10), EndTime Varchar(10),
	EventStartDate Date, EventEndDate Date, MType Varchar(10)) 

--Modified:Han(6/3/19) - Title updated without [DO] or Hour info. to save the space
--Modified:Han(5/1/19) - Removed the MIS admin feature, MISQ#:25727
--Modified:Han(8/14/18) - Added @TitleID
--Modified:Han(7/26/18) - Updated the condition of OfficeID with LocID
--Modified:Han(7/25/18) - Updated with new parameters, @OfficeID and @SalesLineID
--Modified:Han(7/19/18) - Updated with Calendar table and replaced with view, [EMS.V_ADP_Calendar_ByCalendarDateEmployee]
--Modified:Han(9/10/19) - Applied the same filters for "Show Emp." filter, MISQ#:29743
--Modified:Han(6/23/21) - Added @UploadDate
--Modified:Han(6/25/21) - Added WFH condition, Cal.EarningsCode


--Code changes included for Travel--
INSERT INTO #TempCalendarEvent
SELECT ROW_NUMBER() OVER (Order By Cal.CalendarDate, E.EmployeeName) event_id, 
	IsNull(ET.DisplayName,'N/A') + ' Trv' END description, 
	'Trv' END title, 

	Cal2.WeeklyStartDateTime event_start, Cal2.WeeklyEndDateTime event_end,

	--CASE Cal.TimeOffHours WHEN 8 THEN 1 ELSE 0 END all_day, 
	1 all_day,
	'Blue' backgroundColor,
	 'Trv'  calendarGroup,
	E.EmployeeID resourceId, 
	E.EmployeeName EmployeeName, 
	'TRV'  calType,
	FORMAT(Cal.CalendarStartDateTime,'HH:mm') startTime, FORMAT(Cal.CalendarEndDateTime,'HH:mm') endTime
	,Cal2.FinalStartDate EventStartDate, Cal2.FinalEndDate EventEndDate, ''
--FROM EMS.dbo.ADP_Calendar Cal WITH(NOLOCK)
FROM EMS.V_ADP_Calendar_ByCalendarDateEmployee Cal
	JOIN V_EmployeeDepartmentList E ON E.EmployeeID = CAST(Cal.EmployeeID AS VARCHAR(10)) 
	JOIN @EmpTable EMP ON EMP.EmployeeID = E.EmployeeID
	inner join (select distinct EA.EmployeeID,EA.TravelStartDate,EA.TravelEndDate from [EXP].[Egencia_AirBookingsDetail_Trans]  EA
where EA.TransactionType <>'Air cancel') as EA on EMP.EmployeeID=EA.EmployeeID 
	LEFT JOIN DASHBOARD.KeyCalendar_Event_Type ET WITH(NOLOCK) ON ET.TypeCd = Cal.EarningsCode
	CROSS APPLY  [DASHBOARD].[func_Parse_Keyence_Calendar_Range_WithAMPM](Cal.CalendarStartDateTime, Cal.CalendarEndDateTime) Cal2
WHERE 
	Cal.CalendarDate >= CAST(@StartDate as Date) AND Cal.CalendarDate < CAST(@EndDate as Date)
	and Cal.CalendarDate  between  EA.Travelstartdate and EA.TravelEndDate;
	
--code changes end for travel --


--Modified:Han(9/2/22) - Added table alias, ET
--Modified:Han(9/12/22) - Added Cal2 alias
--Modified:Han(9/13/22) - Replaced whole SQL with new one below along with Cal2 alias
--Modified:Han(12/13/22) - Moved time-off before SC to override SC, MISQ#:62618
INSERT INTO #TempCalendarEvent
SELECT ROW_NUMBER() OVER (Order By Cal.CalendarDate, E.EmployeeName) event_id, 
	CASE WHEN Cal.TimeOffHours < 8 THEN CAST(Cal2.EventHr as Varchar(5)) + IsNull(ET.DisplayName,'N/A') ELSE IsNull(ET.DisplayNameAllDay,'N/A') END description, 
	CASE WHEN Cal.TimeOffHours < 8 THEN CAST(Cal2.EventHr As Varchar(5)) + IsNull(ET.DisplayName,'N/A') ELSE IsNull(ET.DisplayNameAllDay,'N/A') END title, 

	Cal2.WeeklyStartDateTime event_start, Cal2.WeeklyEndDateTime event_end,

	--CASE Cal.TimeOffHours WHEN 8 THEN 1 ELSE 0 END all_day, 
	0 all_day,
	CASE WHEN Cal.TimeOffHours < 8 THEN IsNull(ET.BGColor,'#000000') ELSE IsNull(ET.BGColorAllDay,'#000000') END backgroundColor,
	CASE WHEN Cal.EarningsCode IN ('WFH','T2XWFH','ACCWFH') THEN 'WFH' WHEN Cal.TimeOffHours < 8 THEN 'Hr-Off' ELSE 'Day-Off' END calendarGroup,
	E.EmployeeID resourceId, 
	E.EmployeeName EmployeeName, 
	CASE WHEN Cal.EarningsCode IN ('WFH','T2XWFH','ACCWFH') THEN 'WFH' WHEN Cal.TimeOffHours < 8 THEN Cal.TimeOffHours + 'HrOff' ELSE 'DOff' END calType,
	FORMAT(Cal.CalendarStartDateTime,'HH:mm') startTime, FORMAT(Cal.CalendarEndDateTime,'HH:mm') endTime
	,Cal2.FinalStartDate EventStartDate, Cal2.FinalEndDate EventEndDate, Cal2.MType
--FROM EMS.dbo.ADP_Calendar Cal WITH(NOLOCK)
FROM EMS.V_ADP_Calendar_ByCalendarDateEmployee Cal
	JOIN V_EmployeeDepartmentList E ON E.EmployeeID = CAST(Cal.EmployeeID AS VARCHAR(10)) 
	JOIN @EmpTable EMP ON EMP.EmployeeID = E.EmployeeID
	LEFT JOIN DASHBOARD.KeyCalendar_Event_Type ET WITH(NOLOCK) ON ET.TypeCd = Cal.EarningsCode
	CROSS APPLY  [DASHBOARD].[func_Parse_Keyence_Calendar_Range_WithAMPM](Cal.CalendarStartDateTime, Cal.CalendarEndDateTime) Cal2
WHERE 
	Cal.CalendarDate >= CAST(@StartDate as Date) AND Cal.CalendarDate < CAST(@EndDate as Date)
	AND (@TimeOffStatusCd = 0 OR (@TimeOffStatusCd = 2 AND Cal.TimeOffHours = 8) OR (@TimeOffStatusCd = 3 AND Cal.TimeOffHours < 8) OR (@TimeOffStatusCd = 4 AND Cal.EarningsCode IN ('WFH','T2XWFH','ACCWFH')))
	AND Not Exists (Select 1 From #TempCalendarEvent T WHERE T.ResourceID = E.EmployeeID 
		AND (T.EventStartDate = Cal.CalendarDate OR T.EventEndDate = Cal.CalendarDate)  )	

--Modified:Han(12/13/22) - Added condition, NOT EXISTS to remove SC for time-off requests, MISQ#:62618
INSERT INTO #TempCalendarEvent
SELECT MAX(A.ActivityID) event_id, 
	'Sales Call' description, 
	VE.EmployeeName title,
	Cal2.WeeklyStartDateTime event_start,
	Cal2.WeeklyEndDateTime event_end, 
	 0 all_day, 
	'#006400' backgroundColor, 'SC(Sales Call)' calendarGroup, MAX(S.EmployeeID) resourceId,
	VE.EmployeeName EmployeeName, 
	'SC' calType,
	'00:00' startTime, '23:00' endTime 
	, MAX(Cal2.FinalStartDate) EventStartDate, MAX(Cal2.FinalEndDate) EventEndDate, MAX(Cal2.MType) MType
From Direct20KA_DEV.dbo.KA_ACT_ActivityTable_forCAL A WITH(NOLOCK)
	--Direct20KA_Dev.dbo.ACT_ActivityTable A WITH(NOLOCK) 
	JOIN Direct20KA_Dev.dbo.MST_CompanyTable C WITH(NOLOCK) ON A.CompanyID = C.CompanyID 
		AND A.ActivityTypeID = 1 AND A.ActivityDuplicationFlag = '0' AND A.DeleteFlag<> '1'
	JOIN Direct20KA_Dev.dbo.MST_SalesPersonTable S WITH(NOLOCK) ON (S.SalesPersonID = A.SalesPersonID OR S.SalesPersonID = A.JointCallSalesPersonID) AND S.DeleteFlag<>'1'
	JOIN @EmpTable EU ON EU.EmployeeID = S.EmployeeID
	JOIN V_Employeedepartmentlist VE ON VE.EmployeeID = S.EmployeeID
	CROSS APPLY DASHBOARD.func_Parse_Keyence_Calendar_Range_WithAMPM(A.ActivityExpDate, A.ActivityExpDateEnd) Cal2
	LEFT JOIN Direct20KA_Dev.dbo.MST_ContactTable CT WITH(NOLOCK) ON A.ContactID=CT.ContactID
WHERE A.ActivityExpDate Between CAST(@StartDate as DATETime) and CAST(@EndDate as DateTime) 
	AND Not Exists (Select 1 From #TempCalendarEvent T WHERE T.ResourceID = S.EmployeeID
		AND (T.EventStartDate = Cal2.FinalStartDate OR T.EventEndDate = Cal2.FinalStartDate)  )	
Group By VE.EmployeeName, Cal2.WeeklyStartDateTime, Cal2.WeeklyEndDateTime
/* Modified:Han(9/14/22) - Replaced with SQL above
SELECT MAX(A.ActivityID) event_id, 
	'[' + CAST(MAX(A.ActivityID) as Varchar(20)) + '] ' + MAX(C.CompanyName1) + ':' + MAX(CT.FirstName) + ', ' + MAX(CT.LastName) description, 
	--CASE WHEN Cal.TimeOffHours < 8 THEN '[' + Cal.TimeOffHours + ' Hr] ' ELSE '[DO] ' END + EmployeeName title, 
	--C.CompanyName1 title, 
	VE.EmployeeName title,
	--A.ActivityDate event_start, 
	CASE FORMAT(A.ActivityDate,'tt') WHEN 'AM' THEN CAST(FORMAT(A.ActivityDate,'yyyy-MM-dd 00:00:00') AS DateTime)
		ELSE CAST(FORMAT(A.ActivityDate,'yyyy-MM-dd 12:00:00') AS DateTime) END event_start, 
	--A.ActivityDateEnd event_end, 
	--CASE FORMAT(A.ActivityDate,'tt') WHEN 'AM' THEN CAST(FORMAT(A.ActivityDate,'yyyy-MM-dd') + ' 12:00:00' AS DateTime)
	 CASE FORMAT(A.ActivityDate,'tt') WHEN 'AM' THEN CAST(FORMAT(A.ActivityDate,'yyyy-MM-dd 11:59:59') AS DateTime)
		ELSE CAST(FORMAT(A.ActivityDate,'yyyy-MM-dd 23:59:59') AS DateTime) END event_end, 
	 --0 all_day, 
	 CASE WHEN FORMAT(A.ActivityDate,'tt') <> FORMAT(A.ActivityDateEnd,'tt') THEN 1 ELSE 0 END all_day, 
	'#006400' backgroundColor, 'SC(Sales Call)' calendarGroup, MAX(S.EmployeeID) resourceId,
	MAX(CT.FirstName) + ', ' + MAX(CT.LastName) EmployeeName, 
	'SC' calType,
	FORMAT(A.ActivityDate,'hh:mm') startTime, 
	FORMAT(A.ActivityDateEnd,'hh:mm') endTime 
	, CAST(A.ActivityDate as Date) EventStartDate
	, CAST(A.ActivityDateEnd as Date) EventEndDate
From Direct20KA_DEV.dbo.KA_ACT_ActivityTable_forCAL A WITH(NOLOCK)
	--Direct20KA_Dev.dbo.ACT_ActivityTable A WITH(NOLOCK) 
	JOIN Direct20KA_Dev.dbo.MST_CompanyTable C WITH(NOLOCK) ON A.CompanyID = C.CompanyID
	JOIN Direct20KA_Dev.dbo.MST_SalesPersonTable S WITH(NOLOCK) ON (S.SalesPersonID = A.SalesPersonID OR S.SalesPersonID = A.JointCallSalesPersonID) AND S.DeleteFlag<>'1'
	JOIN @EmpTable EU ON EU.EmployeeID = S.EmployeeID
	JOIN V_Employeedepartmentlist VE ON VE.EmployeeID = S.EmployeeID
	LEFT JOIN Direct20KA_Dev.dbo.MST_ContactTable CT WITH(NOLOCK) ON A.ContactID=CT.ContactID
WHERE A.ActivityExpDate Between CAST(@StartDate as DATETime) and CAST(@EndDate as DateTime) AND A.ActivityTypeID = 1
	AND A.ActivityDuplicationFlag = '0' AND A.DeleteFlag<> '1'
	--AND (@UserID = '99999' Or Exists (Select 1 From @EmpTable EU WHERE EU.EmployeeID = S.EmployeeID) )
	AND @TimeOffStatusCd In (0,1) 
	 /*
	 AND (@EmpTypeID = 0 OR EXISTS (Select 1 From EMS.V_CurrentEmpInfo CE WHERE CE.EmployeeID = S.EmployeeID AND CE.EmpTypeID = @EmpTypeID)) 
	 AND (@OfficeID = 0 OR Exists (Select 1 From EMS.V_CurrentEmpInfo CE WHERE CE.EmployeeID = S.EmployeeID AND CE.LocID = @OfficeID))
     AND (@SalesLineID = 0 OR Exists (Select 1 From EMS.V_CurrentEmpInfo CE WHERE CE.EmployeeID = S.EmployeeID AND CE.SFASalesLineID = @SalesLineID))
	 AND (@TitleID = 0 OR Exists (Select 1 From EMS.V_CurrentEmpInfo CE WHERE CE.EmployeeID = S.EmployeeID AND CE.TitleID = @TitleID))
	 AND (@GroupID = 0 OR Exists (Select 1 From EMS.V_CurrentEmpInfo CEG WHERE CEG.EmployeeID = S.EmployeeID AND CEG.GrpID = @GroupID))
	 */
Group By VE.EmployeeName, A.ActivityDate, A.ActivityDateEnd
*/

/* Modified:Han(9/13/22) - Replaced with SQL above
SELECT ROW_NUMBER() OVER (Order By Cal.CalendarDate, E.EmployeeName) event_id, 
	--CASE WHEN Cal.TimeOffHours < 8 THEN Cal.TimeOffHours + ' Hour-Off' ELSE 'Day-Off' END + ' schedule by '  + E.EmployeeName description,
	--CASE WHEN Cal.EarningsCode = 'T2XWFH' THEN 'WFH' WHEN Cal.TimeOffHours < 8 THEN Cal.TimeOffHours + ' Hour-Off' ELSE 'Day-Off' END + ' schedule by '  + E.EmployeeName + @UploadDate description, 
	--CASE WHEN Cal.EarningsCode IN ('WFH','T2XWFH','ACCWFH') THEN 'WFH' WHEN Cal.TimeOffHours < 8 THEN Cal.TimeOffHours + ' Hr-Off' ELSE 'Day-Off' END description, 
	CASE WHEN Cal.TimeOffHours < 8 THEN Cal.TimeOffHours + IsNull(ET.DisplayName,'N/A') ELSE IsNull(ET.DisplayNameAllDay,'N/A') END description, 
	--CASE WHEN Cal.TimeOffHours < 8 THEN Cast(Cal2.EventHr as Varchar(10)) + IsNull(ET.DisplayName,'N/A') ELSE IsNull(ET.DisplayNameAllDay,'N/A') END description, 
	--CASE WHEN Cal.TimeOffHours < 8 THEN '[' + Cal.TimeOffHours + ' Hr] ' ELSE '[DO] ' END + EmployeeName title, 
	--E.EmployeeName title, 
	--CASE WHEN Cal.EarningsCode IN ('WFH','T2XWFH','ACCWFH') THEN 'WFH' WHEN Cal.TimeOffHours < 8 THEN Cal.TimeOffHours + ' Hr-Off' ELSE 'Day-Off' END title, 
	CASE WHEN Cal.TimeOffHours < 8 THEN Cal.TimeOffHours + IsNull(ET.DisplayName,'N/A') ELSE IsNull(ET.DisplayNameAllDay,'N/A') END title, 
	
	--CAST(Convert(Varchar(10),Cal.CalendarDate,112) + ' ' + Cal.TimeOffIn as DateTime) event_start, 
	CASE Right(Cal.TimeOffIn,2) WHEN 'AM' THEN CAST(Convert(Varchar(10),Cal.CalendarDate,112) + ' 00:00:00' as DateTime) ELSE
		CAST(Convert(Varchar(10),Cal.CalendarDate,112) + ' 12:00:00' as DateTime) END event_start, 
	--DateAdd(HH, CAST(Cal.TimeOffHours as Integer), CAST(Convert(Varchar(10),Cal.CalendarDate,112) + ' ' + Cal.TimeOffIn as DateTime)) event_end, 
	CASE Right(Cal.TimeOffIn,2) WHEN 'AM' THEN CAST(Convert(Varchar(10),Cal.CalendarDate,112) + ' 12:00:00' as DateTime) ELSE
		CAST(Convert(Varchar(10),Cal.CalendarDate,112) + ' 23:59:59' as DateTime) END event_end,
	
	--Cal2.DisplayStartDateTime event_start, Cal2.DisplayEndDateTime event_end,
	CASE Cal.TimeOffHours WHEN 8 THEN 1 ELSE 0 END all_day, 
	--CASE WHEN Cal.EarningsCode IN ('WFH','T2XWFH','ACCWFH') THEN '#9c51b5' WHEN Cal.TimeOffHours < 8 THEN '#FFA500' ELSE '#FF0000' END backgroundColor,
	CASE WHEN Cal.TimeOffHours < 8 THEN IsNull(ET.BGColor,'#000000') ELSE IsNull(ET.BGColorAllDay,'#000000') END backgroundColor,
	CASE WHEN Cal.EarningsCode IN ('WFH','T2XWFH','ACCWFH') THEN 'WFH' WHEN Cal.TimeOffHours < 8 THEN 'Hr-Off' ELSE 'Day-Off' END calendarGroup,
	E.EmployeeID resourceId, 
	E.EmployeeName EmployeeName, 
	CASE WHEN Cal.EarningsCode IN ('WFH','T2XWFH','ACCWFH') THEN 'WFH' WHEN Cal.TimeOffHours < 8 THEN Cal.TimeOffHours + 'HrOff' ELSE 'DOff' END calType,
	FORMAT(CAST(Convert(Varchar(10),Cal.CalendarDate,112) + ' ' + Cal.TimeOffIn as DateTime),'hh:mm') startTime, 
	FORMAT(DateAdd(HH, CAST(Cal.TimeOffHours as Integer), CAST(Convert(Varchar(10),Cal.CalendarDate,112) + ' ' + Cal.TimeOffIn as DateTime)),'hh:mm') endTime
	, CAST(Convert(Varchar(10),Cal.CalendarDate,112) + ' ' + Cal.TimeOffIn as Date) EventStartDate
	, DateAdd(HH, CAST(Cal.TimeOffHours as Integer), CAST(Convert(Varchar(10),Cal.CalendarDate,112) + ' ' + Cal.TimeOffIn as DateTime)) EventEndDate
--FROM EMS.dbo.ADP_Calendar Cal WITH(NOLOCK)
FROM EMS.V_ADP_Calendar_ByCalendarDateEmployee Cal
	JOIN V_EmployeeDepartmentList E ON E.EmployeeID = CAST(Cal.EmployeeID AS VARCHAR(10)) 
	JOIN @EmpTable EMP ON EMP.EmployeeID = E.EmployeeID
	--CROSS APPLY DASHBOARD.func_Parse_Keyence_Calendar_Range_WithAMPM(CAST(FORMAT(Cal.CalendarDate,'MM/dd/yyyy ') + Cal.TimeOffIn AS DateTime),
	--	DATEADD(Hour, CAST(Cal.TimeOffHours as Integer), CAST(FORMAT(Cal.CalendarDate,'MM/dd/yyyy ') + Cal.TimeOffIn AS DateTime)))  Cal2
	LEFT JOIN DASHBOARD.KeyCalendar_Event_Type ET WITH(NOLOCK) ON ET.TypeCd = Cal.EarningsCode
		--AND (E.DepartmentGroup<>'MIS' OR E.DepartmentGroup Is Null) -- MISQ#:25727
	--LEFT JOIN ems.dbo.Card_SFUpload UPL WITH(NOLOCK) ON UPL.DateOff = Cal.CalendarDate AND UPL.EmployeeID = CAL.EmployeeID
WHERE 
	--(@UserID = '99999' OR Exists (Select 1 From @EmpTable EMP WHERE EMP.EmployeeID = E.EmployeeID)) AND
	Cal.CalendarDate >= CAST(@StartDate as Date) AND Cal.CalendarDate < CAST(@EndDate as Date)
	AND (@TimeOffStatusCd = 0 OR (@TimeOffStatusCd = 2 AND Cal.TimeOffHours = 8) OR (@TimeOffStatusCd = 3 AND Cal.TimeOffHours < 8) OR (@TimeOffStatusCd = 4 AND Cal.EarningsCode IN ('WFH','T2XWFH','ACCWFH')))
	AND Not Exists (Select 1 From #TempCalendarEvent T WHERE T.ResourceID = E.EmployeeID 
		AND (T.EventStartDate = Cal.CalendarDate OR T.EventEndDate = Cal.CalendarDate)  )	
*/

	/*
	AND (@EmpTypeID = 0 OR EXISTS (Select 1 From EMS.V_CurrentEmpInfo CE WHERE CE.EmployeeID = Cal.EmployeeID AND CE.EmpTypeID = @EmpTypeID))
	AND 
	( (@OfficeID = 0 OR Exists (Select 1 From EMS.V_CurrentEmpInfo CE WHERE CE.EmployeeID = E.EmployeeID AND CE.LocID = @OfficeID))
      AND (@SalesLineID = 0 OR Exists (Select 1 From EMS.V_CurrentEmpInfo CE WHERE CE.EmployeeID = E.EmployeeID AND CE.SFASalesLineID = @SalesLineID))
	  AND (@TitleID = 0 OR Exists (Select 1 From EMS.V_CurrentEmpInfo CE WHERE CE.EmployeeID = E.EmployeeID AND CE.TitleID = @TitleID))
	  AND (@GroupID = 0 OR Exists (Select 1 From EMS.V_CurrentEmpInfo CEG WHERE CEG.EmployeeID = E.EmployeeID AND CEG.GrpID = @GroupID))
	 )
	 */

--Modified:Han(11/8/19) - Added @AdminEmpTab
--Modified:Han(6/3/19) - Added Sales Calls, Only when @UserID is Sales
--Modified:Han(9/10/19) - Applied the same filters regardless of "Show All" or "Show Emp.", MISQ#:29743
--Modified:Han(8/31/22) - Updates on 12:00:00 -> 11:59:59 for event_end
--Modified:Han(8/31/22) - Updates with new table, Direct20KA_DEV.dbo.KA_ACT_ActivityTable_forCAL


--Modified:Han(8/22/22) - Added Time-Punch
/* Modified:Han(8/30/22) - Disabled based on the meeting on 8/30/22 with Shinji
INSERT INTO #TempCalendarEvent( Event_ID , Description , Title ,   Event_Start , Event_End , All_Day , 
	BackgroundColor , CalendarGroup , 	ResourceID , EmployeeName , CalType , StartTime , EndTime, EventStartDate, EventEndDate)
SELECT ROW_NUMBER() OVER (Order BY P.EmployeeID, P.PunchDate) + 20000 event_id, 
	'Time-Punch: ' + FORMAT(P.PunchStartTime,'hh:mmtt') + '-' + FORMAT(P.PunchEndTime,'hh:mmtt') description, 
	--EP.FirstName + ' ' + EP.LastName title,
	'TP' title,
	--P.PunchStartTime event_start, 
	CASE FORMAT(P.PunchStartTime,'tt') WHEN 'AM' THEN CAST(FORMAT(P.PunchStartTime,'yyyy-MM-dd') + ' 00:00:00' AS DateTime)
		ELSE CAST(FORMAT(P.PunchStartTime,'yyyy-MM-dd') + ' 12:00:00' AS DateTime) END event_start, 
	--P.PunchEndTime event_end, 
	CASE FORMAT(P.PunchStartTime,'tt') WHEN 'AM' THEN CAST(FORMAT(P.PunchStartTime,'yyyy-MM-dd') + ' 12:00:00' AS DateTime)
		ELSE CAST(FORMAT(P.PunchStartTime,'yyyy-MM-dd') + ' 23:59:59' AS DateTime) END event_end, 
	0 all_day, 
	'#006464' backgroundColor, 'TP(Time Punch)' calendarGroup, P.EmployeeID resourceId,
	EP.FirstName + ', ' + EP.LastName EmployeeName, 
	'TP' calType,
	FORMAT(P.PunchStartTime,'hh:mm') startTime, 
	FORMAT(P.PunchEndTime,'hh:mm') endTime 
	, P.PunchDate EventStartDate
	, P.PunchDate EventEndDate

From DASHBOARD.vw_Card_ADPPunch_StartTime P
	JOIN EMS.V_CurrentEmpInfo EP ON EP.EmployeeID = P.EmployeeID AND EP.EmpTypeID <> 2 
	JOIN @EmpTable EMP ON EMP.EmployeeID = EP.EmployeeID
WHERE 
	 --Not Exists (Select 1 From #TempCalendarEvent T WHERE T.ResourceID = EP.EmployeeID AND P.PunchDate <= CAST(T.Event_Start AS Date) AND
	-- (@UserID = '99999' OR Exists (Select 1 From @EmpTable EMP WHERE EMP.EmployeeID = EP.EmployeeID)) AND
	 P.PunchDate >= CAST(@StartDate as Date) AND P.PunchDate < CAST(@EndDate as Date)
	 AND Not Exists (Select 1 From #TempCalendarEvent Cal WHERE Cal.ResourceID = EP.EmployeeID AND Cal.All_Day = 1 
		AND (Cal.EventStartDate = P.PunchDate OR Cal.EventEndDate = P.PunchDate) )
	--AND (@TimeOffStatusCd = 0 OR (@TimeOffStatusCd = 2 AND Cal.TimeOffHours = 8) OR (@TimeOffStatusCd = 3 AND Cal.TimeOffHours < 8) OR (@TimeOffStatusCd = 4 AND Cal.EarningsCode IN ('WFH','T2XWFH','ACCWFH')))
	--AND (@EmpTypeID = 0 OR EXISTS (Select 1 From EMS.V_CurrentEmpInfo CE WHERE CE.EmployeeID = Cal.EmployeeID AND CE.EmpTypeID = @EmpTypeID))
	/*
	AND 
	( (@OfficeID = 0 OR Exists (Select 1 From EMS.V_CurrentEmpInfo CE WHERE CE.EmployeeID = EP.EmployeeID AND CE.LocID = @OfficeID))
      AND (@SalesLineID = 0 OR Exists (Select 1 From EMS.V_CurrentEmpInfo CE WHERE CE.EmployeeID = EP.EmployeeID AND CE.SFASalesLineID = @SalesLineID))
	  AND (@TitleID = 0 OR Exists (Select 1 From EMS.V_CurrentEmpInfo CE WHERE CE.EmployeeID = EP.EmployeeID AND CE.TitleID = @TitleID))
	  AND (@GroupID = 0 OR Exists (Select 1 From EMS.V_CurrentEmpInfo CEG WHERE CEG.EmployeeID = EP.EmployeeID AND CEG.GrpID = @GroupID))
	 )
	 */
--Modified:Han(8/22/22) - Moved after Time-Punch info
*/
--Modified:Han(8/30/22) - Added [EC.TitleID <> 19] to exclude NPSD
--UOD (Sales)
INSERT INTO #TempCalendarEvent( Event_ID , Description , Title ,   Event_Start , Event_End , All_Day , 
	BackgroundColor , CalendarGroup , 	ResourceID , EmployeeName , CalType , StartTime , EndTime, EventStartDate, EventEndDate, MType)
Select ROW_NUMBER() OVER (Order By C.CalendarDate)+10000 Event_ID , 'UOD' Description, E.EmployeeName Title , 
	Cal2.WeeklyStartDateTime Event_Start , Cal2.WeeklyEndDateTime Event_End , 0 All_Day , 
	'#3CB043' BackgroundColor, 'UOD' CalendarGroup , E.EmployeeID ResourceID, E.EmployeeName EmployeeName, 'UOD' CalType , '08:00' StartTime, '17:00' EndTime
	, C.CalendarDate EventStartDate, C.CalendarDate EventEndDate, Cal2.MType
From Direct20KA_Report.dbo.DateConvertAddedInfoTable C WITH(NOLOCK)
	JOIN @EmpTable E ON 1 = 1
	JOIN EMS.V_CurrentEmpInfo EC ON EC.EmployeeID = E.EmployeeID AND EC.EmpTypeID = 2 AND EC.TitleID <> 19
	CROSS APPLY DASHBOARD.func_Parse_Keyence_Calendar_Range_WithAMPM(C.CalendarDate, FORMAT(C.CalendarDate,'MM/dd/yyyy 17:00')) Cal2
Where C.Calendardate >= CAST(@StartDate as Date) AND C.CalendarDate < CAST(@EndDate as Date)
	AND Not Exists (Select 1 From #TempCalendarEvent C WHERE C.ResourceID = EC.EmployeeID AND C.MType = Cal2.MType AND C.EventStartDate = Cal2.FinalStartDate)
/*Modified:Han(9/14/22) - Repalced with SQL above
Select ROW_NUMBER() OVER (Order By C.CalendarDate)+10000 Event_ID , 'UOD' Description, E.EmployeeName Title , C.CalendarDate  Event_Start , C.CalendarDate Event_End , 1 All_Day , 
	'#3CB043' BackgroundColor, 'UOD' CalendarGroup , E.EmployeeID ResourceID, E.EmployeeName EmployeeName, 'UOD' CalType , '08:00' StartTime, '17:00' EndTime
	,C.CalendarDate EventStartDate, C.CalendarDate EventEndDate
From Direct20KA_Report.dbo.DateConvertAddedInfoTable C WITH(NOLOCK)
	JOIN @EmpTable E ON 1 = 1
	JOIN EMS.V_CurrentEmpInfo EC ON EC.EmployeeID = E.EmployeeID AND EC.EmpTypeID = 2 AND EC.TitleID <> 19
Where C.Calendardate >= CAST(@StartDate as Date) AND C.CalendarDate < CAST(@EndDate as Date)
	AND Not Exists (Select 1 From #TempCalendarEvent Cal WHERE Cal.ResourceID = E.EmployeeID 
		AND (Cal.EventStartDate = C.CalendarDate OR Cal.EventEndDate = C.CalendarDate)  )
*/


--Modified:Han(8/25/22) - Added custom entry through the Keyence Calendar
--Modified:Han(9/1/22) - Updates on event type and moved before OFFICE/WFH following
--Modified:Han(9/1/22) - New type, OFFICE[OFC]
--Modified:Han(9/8/22) - Added Cal for multiple days
--Modified:Han(9/12/22) - Updated with new SQL below, MISQ#:59998
INSERT INTO #TempCalendarEvent( Event_ID , Description , Title ,   Event_Start , Event_End , All_Day , 
	BackgroundColor , CalendarGroup , 	ResourceID , EmployeeName , CalType , StartTime , EndTime, EventStartDate, EventEndDate, MType)
Select ROW_NUMBER() OVER (Order By E.EventStart) + 40000, 
	CASE E.EventType WHEN 'OFC' THEN 'OFFICE' ELSE '[' + E.EventType + '] ' + E.EventTitle END , E.EventTitle, 
	Cal2.WeeklyStartDateTime Event_Start, Cal2.WeeklyEndDateTime Event_End, Cal2.IsAllDay,
    CASE WHEN DATEDIFF(hour,EventStart, EventEnd) < 8 THEN ET.BGColor ELSE ET.BGColorAllDay END, 'CUSTOM', E.EmployeeID, EE.EmployeeName, E.EventType, 
		FORMAT(Cal2.FinalStartDateTime,'hh:mm'), FORMAT(Cal2.FinalEndDateTime,'hh:mm'),
	Cal2.FinalStartDate, Cal2.FinalEndDate, CAl2.MType
From DASHBOARD.KeyCalendar_Event E WITH(NOLOCK)
	JOIN DASHBOARD.KeyCalendar_Event_Type ET WITH(NOLOCK) ON ET.TypeCd = E.EventType AND E.IsValid = 1
	JOIN V_Employeedepartmentlist EE ON EE.EmployeeID = E.EmployeeID
	JOIN @EmpTable EMP ON EMP.EmployeeID = EE.EmployeeID
	CROSS APPLY DASHBOARD.func_Parse_Keyence_Calendar_Range_WithAMPM(E.EventStart, E.EventEnd) Cal2
WHERE E.EventStartDate >= CAST(@StartDate as DATE) AND E.EventEndDate <= CAST(@EndDate as Date)
	--AND Exists (Select 1 From @EmpTable EMP WHERE EMP.EmployeeID = E.EmployeeID)
/*
INSERT INTO #TempCalendarEvent( Event_ID , Description , Title ,   Event_Start , Event_End , All_Day , 
	BackgroundColor , CalendarGroup , 	ResourceID , EmployeeName , CalType , StartTime , EndTime, EventStartDate, EventEndDate)
Select ROW_NUMBER() OVER (Order By E.EventStart) + 40000, 
	CASE E.EventType WHEN 'OFC' THEN 'OFFICE' ELSE '[' + E.EventType + '] ' + E.EventTitle END , E.EventTitle, 
	--EventStart, EventEnd, 
	CASE FORMAT(Cal.CalendarDate,'tt') WHEN 'AM' THEN CAST(FORMAT(Cal.CalendarDate,'yyyy-MM-dd') + ' 00:00:00' AS DateTime)
		ELSE CAST(FORMAT(Cal.CalendarDate,'yyyy-MM-dd') + ' 12:00:00' AS DateTime) END Event_Start, 
	CASE FORMAT(Cal.CalendarDate,'tt') WHEN 'AM' THEN CAST(FORMAT(Cal.CalendarDate,'yyyy-MM-dd') + ' 12:00:00' AS DateTime)
		ELSE CAST(FORMAT(Cal.CalendarDate,'yyyy-MM-dd') + ' 23:59:59' AS DateTime) END Event_End, 
	IsAllDay,
    CASE WHEN DATEDIFF(hour,EventStart, EventEnd) < 8 THEN ET.BGColor ELSE ET.BGColorAllDay END, 'CUSTOM', E.EmployeeID, EE.EmployeeName, E.EventType, FORMAT(E.EventStart,'hh:mm'), FORMAT(E.EventEnd,'hh:mm'),
	--CAST(E.EventStart As Date), CAST(E.EventEnd AS Date)
	E.EventStartDate, E.EventEndDate
From DASHBOARD.KeyCalendar_Event E WITH(NOLOCK)
	JOIN DASHBOARD.KeyCalendar_Event_Type ET WITH(NOLOCK) ON ET.TypeCd = E.EventType AND E.IsValid = 1
	JOIN V_Employeedepartmentlist EE ON EE.EmployeeID = E.EmployeeID
	JOIN Direct20KA_Dev.dbo.SYS_CalendarTable Cal WITH(NOLOCK) ON Cal.CalendarDate >= E.EventStartDate AND Cal.CalendarDate <= E.EventEndDate
	--JOIN Direct20KA_Dev.dbo.SYS_CalendarTable Cal WITH(NOLOCK) ON Cal.CalendarDate >= E.EventStart AND Cal.CalendarDate <= E.EventEnd
WHERE Exists (Select 1 From @EmpTable EMP WHERE EMP.EmployeeID = E.EmployeeID)
	--E.EventEnd Between CAST(@StartDate as DATETime) and CAST(@EndDate as DateTime)
	--AND Exists (Select 1 From @EmpTable EMP WHERE EMP.EmployeeID = E.EmployeeID)
*/

--Modified:Han(10/6/22) - Added using Card Swipe data to show as Office, If swiped in AM => Full Day. If not, PM Only
INSERT INTO #TempCalendarEvent( Event_ID , Description , Title ,   Event_Start , Event_End , All_Day , 
	BackgroundColor , CalendarGroup , 	ResourceID , EmployeeName , CalType , StartTime , EndTime, EventStartDate, EventEndDate, MType)
Select ROW_NUMBER() OVER (Order By C.FirstSwipeDateTimeWithTZ) + 50000 Event_ID, 
	EOFC.DisplayNameAllDay [Description], 'Card-Swipe' Title, 
	Cal2.WeeklyStartDateTime Event_Start, Cal2.WeeklyEndDateTime Event_End, 0 All_Day,
    CASE C.IsAllDay WHEN 1 THEN EOFC.BGColorAllDay ELSE EOFC.BGColor END BackgroundColor, 'CUSTOM' CalendarGroup, E.EmployeeID ResourceID, E.NickName + ' ' + E.LastName EmployeeName, 
	'OFFICE' CalType, FORMAT(Cal2.FinalStartDateTime,'hh:mm') StartTime, FORMAT(Cal2.FinalEndDateTime,'hh:mm') EndTime,
	Cal2.FinalStartDate EventStartDate, Cal2.FinalEndDate EventEndDate, CAl2.MType MType
From EMS.V_CurrentEmpInfo E
	JOIN DASHBOARD.KeyCalendar_Event_Type EOFC WITH(NOLOCK) ON EOFC.TypeCd = 'OFC'
	JOIN DASHBOARD.vw_Card_FirstSwipeInfo_ByEmployeeDate C ON C.EmployeeID = E.EmployeeID AND 
		--C.SwipeDate >= CAST('2022-10-06' As Date) AND C.SwipeDate < CAST(DateAdd(day, 1,GetDate()) As Date)
		C.SwipeDate >= @StartDate AND C.SwipeDate < @EndDate
	CROSS APPLY [DASHBOARD].[func_Parse_Keyence_Calendar_Range_WithAMPM](C.FirstSwipeDateTimeWithTZ, 
		CASE C.IsAllDay WHEN 1 THEN FORMAT(C.FirstSwipeDateTimeWithTZ,'yyyy-MM-dd 12:01:00') ELSE DateAdd(minute,30, C.FirstSwipeDateTimeWithTZ) END) Cal2
Where E.EmpTypeID = 2 
	AND Exists (Select 1 From @EmpTable EE WHERE EE.EmployeeID = E.EmployeeID)
	AND Not Exists (Select 1 From #TempCalendarEvent C WHERE C.ResourceID = E.EmployeeID AND C.MType = Cal2.MType AND C.EventStartDate = Cal2.FinalStartDate)

--Modified:Han(8/30/22) - Added [EC.TitleID <> 19] to exclude NPSD
--Modified:Han(8/31/22) - OFFICE for SE1 title 
--Modified:Han(8/23/22) - Added for sales with 1) No SC, 2) No PTO, 3) No UOD
--Modified:Han(9/14/22) - Added 440(Sales Director) to exclude SD
--Modified:Han(9/14/22) - Added MType
INSERT INTO #TempCalendarEvent( Event_ID , Description , Title ,   Event_Start , Event_End , All_Day , 
	BackgroundColor , CalendarGroup , 	ResourceID , EmployeeName , CalType , StartTime , EndTime, EventStartDate, EventEndDate, MType)
Select ROW_NUMBER() OVER (Order By Cal2.FinalStartDateTime)+30000 Event_ID , 
	CASE WHEN EC.TitleID In (24,19,440) OR EC.EmpTypeID <> 2 THEN EOFC.DisplayNameAllDay ELSE EWFH.DisplayNameAllDay END Description, 
	E.EmployeeName Title , Cal2.WeeklyStartDateTime  Event_Start , Cal2.WeeklyEndDateTime Event_End , 0 All_Day , 
	CASE WHEN EC.TitleID In (24,19,440) OR EC.EmpTypeID <> 2 THEN EOFC.BGColorAllDay ELSE EWFH.BGColorAllDay END BackgroundColor, 
	'WFH' CalendarGroup , E.EmployeeID ResourceID, E.EmployeeName EmployeeName, 'WFH' CalType , '00:00' StartTime, '24:00' EndTime
	,Cal2.FinalStartDate EventStartDate, Cal2.FinalEndDate EventEndDate, Cal2.MType
From @EmpTable E
	JOIN EMS.V_CurrentEmpInfo EC ON EC.EmployeeID = E.EmployeeID 
	JOIN DASHBOARD.KeyCalendar_Event_Type EOFC WITH(NOLOCK) ON EOFC.TypeCd = 'OFC'
	JOIN DASHBOARD.KeyCalendar_Event_Type EWFH WITH(NOLOCK) ON EWFH.TypeCd = 'WFH'
	CROSS APPLY DASHBOARD.func_Parse_Keyence_Calendar_Range_WithAMPM(CAST(@StartDate as DateTime), CAST(@EndDate as DateTime)) Cal2
WHERE (@TimeOffStatusCd = 0 Or @TimeOffStatusCd = 4) AND
		Not Exists (Select 1 From #TempCalendarEvent C WHERE C.ResourceID = EC.EmployeeID AND C.MType = Cal2.MType AND C.EventStartDate = Cal2.FinalStartDate)
/* Modified:Han(9/14/22) - Repalced with SQL above
Select ROW_NUMBER() OVER (Order By Cal.CalendarDate)+30000 Event_ID , 
	--CASE WHEN EC.TitleID In (24,19) OR EC.EmpTypeID <> 2 THEN 'OFFICE' ELSE 'WFH' END Description,
	CASE WHEN EC.TitleID In (24,19,440) OR EC.EmpTypeID <> 2 THEN EOFC.DisplayNameAllDay ELSE EWFH.DisplayNameAllDay END Description, 
	E.EmployeeName Title , Cal.CalendarDate  Event_Start , Cal.CalendarDate Event_End , 1 All_Day , 
	--CASE WHEN EC.TitleID In (24,19) OR EC.EmpTypeID <> 2 THEN '#c4d4a4' ELSE '#9c51b5' END BackgroundColor, 
	CASE WHEN EC.TitleID In (24,19,440) OR EC.EmpTypeID <> 2 THEN EOFC.BGColorAllDay ELSE EWFH.BGColorAllDay END BackgroundColor, 
	'WFH' CalendarGroup , E.EmployeeID ResourceID, E.EmployeeName EmployeeName, 'WFH' CalType , '00:00' StartTime, '24:00' EndTime
	,Cal.CalendarDate EventStartDate, Cal.CalendarDate EventEndDate
From @EmpTable E
	JOIN EMS.V_CurrentEmpInfo EC ON EC.EmployeeID = E.EmployeeID 
	JOIN DASHBOARD.KeyCalendar_Event_Type EOFC WITH(NOLOCK) ON EOFC.TypeCd = 'OFC'
	JOIN DASHBOARD.KeyCalendar_Event_Type EWFH WITH(NOLOCK) ON EWFH.TypeCd = 'WFH'
		--AND EC.EmpTypeID = 2 AND EC.TitleID <> 19
	JOIN Direct20KA_Dev.dbo.SYS_CalendarTable Cal WITH(NOLOCK) ON Cal.CalendarDate >= CAST(@StartDate as Date) AND Cal.CalendarDate < CAST(@EndDate as Date) AND Cal.WorkDayFlag = 1
WHERE (@TimeOffStatusCd = 0 Or @TimeOffStatusCd = 4)
	AND Not Exists (Select 1 From #TempCalendarEvent C 
			WHERE C.ResourceID = EC.EmployeeID AND (C.EventStartDate = Cal.CalendarDate OR C.EventEndDate = Cal.CalendarDate) )
*/

/*
--Modified:Han(9/9/22) - Added for those admin/mkt empty in AM or PM section ===========================
DECLARE @EventByEmpMeridiemType TABLE (EmployeeID Varchar(10), EventStartDate Date, MeridiemType CHAR(2))

INSERT INTO @EventByEmpMeridiemType
SELECT E.ResourceID, E.EventStartDate, T.MType
FROM #TempCalendarEvent E
	JOIN (Select 'AM' MType UNION ALL Select 'PM') T On 1 = 1
	JOIN EMS.V_CurrentEmpInfo EMSE ON E.All_Day = 0 AND EMSE.EmployeeID = E.ResourceID AND (EMSE.EmpTypeID <> 2 OR EMSE.TitleID In (19,24,440)) 
GROUP By E.ResourceID, E.EventStartDate, T.MType
--Modified:Han(9/14/22) - Added MType
INSERT INTO #TempCalendarEvent( Event_ID , Description , Title ,   Event_Start , Event_End , All_Day , 
	BackgroundColor , CalendarGroup , 	ResourceID , EmployeeName , CalType , StartTime , EndTime, EventStartDate, EventEndDate, MType)
Select ROW_NUMBER() OVER (Order By E.EventStartDate)+50000 Event_ID , 
	EOFC.DisplayNameAllDay Description, EC.EmployeeName Title , 
	CASE E.MeridiemType WHEN 'AM' THEN CAST(FORMAT(E.EventStartDate,'MM/dd/yyyy 06:00:00') AS DateTime)
		ELSE CAST(FORMAT(E.EventStartDate,'MM/dd/yyyy 12:00:00') AS DateTime) END Event_Start, 
	CASE E.MeridiemType WHEN 'AM' THEN CAST(FORMAT(E.EventStartDate,'MM/dd/yyyy 11:59:59') AS DateTime) 
		ELSE CAST(FORMAT(E.EventStartDate,'MM/dd/yyyy 23:59:59') AS DateTime) END Event_End , 
	0 All_Day , 
	 EOFC.BGColorAllDay BackgroundColor, 
	'OFC' CalendarGroup , E.EmployeeID ResourceID, EC.EmployeeName EmployeeName, 'OFC' CalType , '00:00' StartTime, '24:00' EndTime
	, E.EventStartDate EventStartDate, E.EventStartDate EventEndDate, E.MeridiemType
From @EventByEmpMeridiemType E
	JOIN V_Employeedepartmentlist EC ON EC.EmployeeID = E.EmployeeID
	--JOIN EMS.V_CurrentEmpInfo EMSE ON EMSE.EmployeeID = E.employeeID AND (EMSE.EmpTypeID <> 2 OR EMSE.TitleID In (19,24))
	JOIN DASHBOARD.KeyCalendar_Event_Type EOFC WITH(NOLOCK) ON EOFC.TypeCd = 'OFC' 
WHERE (@TimeOffStatusCd = 0 Or @TimeOffStatusCd = 4)
	AND Not Exists (Select 1 From #TempCalendarEvent C 
			WHERE C.ResourceID = E.EmployeeID AND C.EventStartDate = E.EventStartDate AND C.All_Day = 0 AND FORMAT(C.Event_Start,'tt') = E.MeridiemType )
--========================= End of mkt/admin to fill empty AM or PM with OFFICE =======================================
*/

--Return 
/*
Select Event_ID , Description , Title ,   Event_Start , Event_End , All_Day , 
	BackgroundColor , CalendarGroup , 	ResourceID , EmployeeName , CalType , StartTime , EndTime 
FRom #TempCalendarEvent
*/

--Return grouping by type
--Modified:Han(9/7/22) - Added CustomEventID, EventStartInFormat, EventEndInFormat, CustomEventComment
Select MAX(Event_ID) Event_ID,'SC' Description , MAX(Title) Title, 
	CASE FORMAT(MIN(Event_Start),'tt') WHEN 'AM' THEN CAST(FORMAT(MIN(Event_Start),'yyyy-MM-dd 00:00:00') AS DateTime)
		ELSE CAST(FORMAT(MIN(Event_Start),'yyyy-MM-dd 12:00:00') AS DateTime) END Event_Start, 
	CASE FORMAT(MAX(Event_End),'tt') WHEN 'AM' THEN CAST(FORMAT(MAX(Event_End),'yyyy-MM-dd 12:00:00') AS DateTime)
		ELSE CAST(FORMAT(MAX(Event_End),'yyyy-MM-dd 23:59:59') AS DateTime) END Event_End , 
    	CASE WHEN FORMAT(MIN(Event_Start),'tt') = FORMAT(MAX(Event_End),'tt') THEN 0 ELSE 1 END All_Day, 
	MAX(BackgroundColor) BackgroundColor, 'SC' CalendarGroup , ResourceID , MAX(EmployeeName) EmployeeName, 'SC' CalType , '' StartTime , '' EndTime 
	,0 CustomEventID, FORMAT(MIN(Event_Start),'MM/dd/yyyy HH:mm') EventStartInFormat, FORMAT(MAX(Event_End),'MM/dd/yyyy HH:mm') EventEndInFormat, '' CustomEventComment
From #TempCalendarEvent
WHERE CalType = 'SC'
GROUP BY ResourceID, EventStartDate, EventEndDate
UNION ALL
Select Event_ID , Description , Title ,   Event_Start , Event_End , All_Day , 
	BackgroundColor , CalendarGroup , 	ResourceID , EmployeeName , CalType , StartTime , EndTime 
	,0 CustomEventID, FORMAT(Event_Start,'MM/dd/yyyy HH:mm') EventStartInFormat, FORMAT(Event_End,'MM/dd/yyyy HH:mm') EventEndInFormat, '' CustomEventComment
FRom #TempCalendarEvent
WHERE CalType <> 'SC'
--ORder By 10,4

END