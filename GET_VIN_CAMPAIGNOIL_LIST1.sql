CREATE PROCEDURE [dbo].[SP_GET_VIN_CAMPAIGN_OIL_LIST1]
AS BEGIN
  SET NOCOUNT ON;
	DECLARE @YearApplied INT= 2023
	DECLARE @ValidFrom Datetime = '2025-01-01'
	DECLARE @ValidTo Datetime = '2025-06-30'
	DECLARE @Source nvarchar(300)= 'CAMPAIGN-OIL'
	DECLARE @CampaignName nvarchar(300)= N'Miễn phí thay thế dầu máy 1 lần (NSX hỗ trợ chi phí dầu, Đại lý hỗ trợ phí công lao động)'
	DECLARE @RMprefix nvarchar(300)=N'Khách hàng được miễn phí dầu máy 1 lần tại hệ thống đại lý toàn quốc, mã KM: '
	DECLARE @RMsuffix nvarchar(300)=N' sử dụng trước ngày 01/07/2025 theo chương trình KH Diamon 2023'
	DECLARE @Coupon nvarchar(100)=''
	DECLARE @STT int

/*Process 1 : insert LIST#1 to CampaignByVin*/ 
-- Create #Temp 
CREATE TABLE #NoshowVin1 (
STT int unique NOT NULL
,Vin nvarchar(50) unique NOT NULL
,saledate datetime2(7) NOT NULL
,Salesdlr nvarchar(256) 
,status bit)

-- Insert List of Vin into #Temp
INSERT INTO #NoshowVin1 (Vin, STT,saledate,Salesdlr,status)
SELECT A.VinNo,ROW_NUMBER() OVER(ORDER BY A.VinNo) AS [STT],A.SaleDate,A.DealerCode,A.Status
FROM (
	SELECT DISTINCT s.VinNo,s.SaleDate,s.DealerCode,0 as Status
	FROM SrvCampaignByVin t
	RIGHT JOIN (
		SELECT c.* 
		FROM (
			SELECT a.VinNo,a.DealerCode,c.TenancyName, a.SaleDate, b.CloseRoDate, datediff(day, b.CloseRoDate,GETDATE()) as SoNgay, b.RegisterNo														
			,b.Model,ROW_NUMBER() OVER (PARTITION BY a.VinNo ORDER BY b.CloseRoDate desc) as rownum														
			FROM SrvQuoSoldVehicle a
			join crmKPIRO b on a.VinNo = b.Vin
			join AbpTenants c on c.TenantCode=A.DealerCode
			WHERE lower(a.CarModel) !='lexus' and YEAR(a.SaleDate) = @YearApplied and a.IsDeleted=0 and (b.repairMaintenanceId > 0 or  b.repairId > 0 or  b.bodyPaintId > 0 or  b.beautySalonId > 0)
		) c
		WHERE c.rownum = 1 and datediff(day, c.CloseRoDate,GETDATE() ) > 365 
	) s ON t.Vin = s.VinNo 
	WHERE t.Vin IS NULL 
		OR NOT EXISTS (SELECT 1 FROM SrvCampaignByVin WHERE Vin = s.VinNo AND Source = @Source)
) As A

--START A PROCESS OF GENERATING COUPON & INSERTING DATA TO TABLE
SET @STT=1
WHILE (SELECT COUNT(*) FROM #NoshowVin1 WHERE status=0)>0 -- if no more VIN needed to update , stop while loop
BEGIN
	
	-- Generate the coupon code
	WHILE 
		EXISTS (SELECT 1 FROM SrvCampaignByVin WHERE Source = @SOURCE AND Coupon = @COUPON)
		OR @COUPON = ''
	-- Exit WHILE LOOP IF Coupon is null or duplication of key "Source & Coupon"
	BEGIN
		SET @Coupon= [dbo].[fn_GenRandomPhrase](8,1);
	END
	-- Start inserting data into table 1 by 1
	INSERT INTO CampaignByVin (
		CreationTime,
	    CreatorUserId,
	    IsDeleted,
	    Vin,
	    Coupon,
	    Discount,
	    DiscountPercent,
	    EffectFrom,
	    EffectTo,
	    Source,
	    SalesDate,
	    SalesDlr,
	    IsOneTimeOnly,
	    CampaignName,
	    Remark
	) VALUES
	(   GETDATE() 
	    ,-1   
	    ,0    
		,(SELECT Vin FROM #NoshowVin1 WHERE STT=@STT) 
		,@Coupon 
		,0	
		,100	
		,@ValidFrom 
		,@ValidTo	
		,@Source 
		,(SELECT saledate FROM #NoshowVin1 WHERE STT=@STT)	
		,(SELECT Salesdlr FROM #NoshowVin1 WHERE STT=@STT) 
		,1	
		,@CampaignName 
		,Concat (@RMprefix,@Coupon,@RMsuffix) 
	);
	--Update Status: 0 => 1 for selected VIN and mark STT to process next Vin
	UPDATE #NoshowVin1 SET status=1 WHERE STT=@STT
	SET @STT = @STT +1;

END -- Terminate WHILE LOOP if no condition is met
DROP TABLE #NoshowVin1

END 
