CREATE PROCEDURE [dbo].[SP_Consolidates_Formats_Data]
AS
-- Exec SP_Consolidates_Formats_Data
BEGIN
    SET NOCOUNT ON;

    DECLARE @cols NVARCHAR(MAX), @sql NVARCHAR(MAX);

    -- Step 1: Get distinct attribute names and build the pivot column list
	WITH CTE as (
	SELECT 
	   Top 100  OrderItemProductAttributes_ProductAttributeName
	FROM TABLE2
	GROUP BY 
		OrderItemProductAttributes_ProductAttributeName
	ORDER BY 
		MIN(ProductAttributeClasses_SortSeq)
		,MIN(ProductAttributes_SortSeq)
		,MIN(ProductAttributeName)
	)
	SELECT @cols = STRING_AGG(QUOTENAME(OrderItemProductAttributes_ProductAttributeName),',') FROM CTE

    -- Step 2: Build the dynamic SQL
    SET @sql = '
    WITH FixTable AS (
        SELECT 
			a.OrderID
			,a.EntryID
			,a.OrderDate
			,a.OrderStatus
			,a.Comments
			,a.CreateDateTime
			,a.EventName
			,a.EventDisplayName
			,a.CompanyName
			,a.CustomerFirstName
			,a.CustomerLastName
			,a.FirstName
			,a.LastName
			,a.BusAddress1a
			,a.BusAddress1b
			,a.BusCity
			,a.BusStateProvince
			,a.BusPostalCode
			,a.MailAddress1a
			,a.MailAddress1b
			,a.MailCity
			,a.MailStateProvince
			,a.MailPostalCode
			,a.BusPhone
			,a.MobilePhone
			,a.BusEmail1Address
			,a.PerEmail1Address
			,a.OrderItemGUID
			,a.ParentOrderItemGUID
			,a.ProductTypeGUID
			,a.ProductTypeName
			,a.ProductTypeDisplayName
			,a.ProductSKU
			,a.ProductName
			,a.EventProducts_SpaceDimensions
			,a.EventSpaces_SpaceDimensions
			,a.OrderItemStatus_StatusName
			,a.ItemQuantity
			,a.ItemDescription
			,a.ItemUnitPrice
			,a.ItemSubTotal
			,a.OrderItems_ProcessingFeeRate
			,a.OrderItem_ProcessingFeeTotal
			,a.Order_ProcessingFeeTotal
			,a.Order_ServiceFeesTotal
			,a.ItemFeeChargesTotal
			,a.RefundTotal
			,a.OrderSubTotal
			,a.OrderTotal
			,a.OrderNetTotal
			,a.TotalPayments
			,a.ItemTotal
			,b.OrderItemProductAttributes_OrderItemGUID
			,b.OrderItemProductAttributes_ProductAttributeName
			,b.OrderItemProductAttributes_UserInputValue
        FROM TABLE1 a
        LEFT JOIN TABLE2 b 
            ON a.OrderItemGUID = b.OrderItemProductAttributes_OrderItemGUID
    )
    SELECT
			OrderID
			,EntryID
			,OrderDate
			,OrderStatus
			,Comments
			,CreateDateTime
			,EventName
			,EventDisplayName
			,CompanyName
			,CustomerFirstName
			,CustomerLastName
			,FirstName
			,LastName
			,BusAddress1a
			,BusAddress1b
			,BusCity
			,BusStateProvince
			,BusPostalCode
			,MailAddress1a
			,MailAddress1b
			,MailCity
			,MailStateProvince
			,MailPostalCode
			,BusPhone
			,MobilePhone
			,BusEmail1Address
			,PerEmail1Address
			,OrderItemGUID
			,ParentOrderItemGUID
			,ProductTypeGUID
			,ProductTypeName
			,ProductTypeDisplayName
			,ProductSKU
			,ProductName
			,EventProducts_SpaceDimensions
			,EventSpaces_SpaceDimensions
			,OrderItemStatus_StatusName
			,ItemQuantity
			,ItemDescription
			,ItemUnitPrice
			,ItemSubTotal
			,OrderItems_ProcessingFeeRate
			,OrderItem_ProcessingFeeTotal
			,Order_ProcessingFeeTotal
			,Order_ServiceFeesTotal
			,ItemFeeChargesTotal
			,RefundTotal
			,OrderSubTotal
			,OrderTotal
			,OrderNetTotal
			,TotalPayments
			,ItemTotal
			,OrderItemProductAttributes_OrderItemGUID
			, ' + @cols + '
    FROM FixTable
    PIVOT (
        MAX(OrderItemProductAttributes_UserInputValue)
        FOR OrderItemProductAttributes_ProductAttributeName IN (' + @cols + ')
    ) AS pvt;';

    -- Step 3: Execute the dynamic SQL
    EXEC sp_executesql @sql;
END;

