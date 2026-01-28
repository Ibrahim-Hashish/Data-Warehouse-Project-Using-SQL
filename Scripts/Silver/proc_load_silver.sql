
/*
    ==================================
    Inserting Data into Silver Layer
    ==================================
    This script inserts data into tables of the bronze layer. First, tables are truncated, then filled with data.
    A stored procedure "load_silver" is used to do all of that.
    Parameters: None.
    Usage: EXEC Silver.load_silver;
*/

/*
	============================================================================
	Cleaning and Transforming Bronze Layer and Pushing it into Silver Layer
	============================================================================
*/


/*
	=======================================
	Bronze.crm_cust_info
	=======================================
*/

CREATE OR ALTER PROCEDURE Silver.load_silver AS 
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    SET @batch_start_time = GETDATE();

	BEGIN TRY
		PRINT '=======================================';
        PRINT 'Loading Bronze Layer';
        PRINT '=======================================';

        PRINT '---------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '---------------------------------------';

        SET @start_time = GETDATE();
		-- Inserting data into Silver.crm_cust_info
		PRINT 'Truncating table: Silver.crm_cust_info'
		TRUNCATE TABLE Silver.crm_cust_info
		PRINT 'Inserting into table: Silver.crm_cust_info'
		INSERT INTO Silver.crm_cust_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
		SELECT
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname, -- Dealing with unwanted spaces in cst_firstname
			TRIM(cst_lastname) AS cst_lastname, -- Dealing with unwanted spaces in cst_lastname
			CASE 
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				ELSE 'Unknown'
			END AS cst_marital_status, -- Giving meaning values to cst_marital_status
			CASE 
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				ELSE 'Unknown'
			END AS cst_gndr, -- Giving meaning values to cst_gndr
			cst_create_date
		FROM (
				SELECT
					*,
					ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS ranking
				FROM Bronze.crm_cust_info
			) AS t
		WHERE ranking = 1 -- Dealing with duplicates
				AND cst_id IS NOT NULL; -- Dealing with NULLs in cst_id

		---------------------------------------------------------

		/*
			=======================================
			Bronze.crm_cust_info
			=======================================
		*/

		SET @start_time = GETDATE();
		-- Inserting data into Silver.crm_prd_info
		PRINT 'Truncating table: Silver.crm_prd_info'
		TRUNCATE TABLE Silver.crm_prd_info
		PRINT 'Inserting into table: Silver.crm_prd_info'
		INSERT INTO Silver.crm_prd_info (prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
		SELECT
			prd_id,
			-- Extracting Category ID from prd_key (First 5 Characters)
			REPLACE(LEFT(prd_key, 5), '-', '_') AS cat_id, -- Replacing - with _ to match the cat_id in bronze.erp_px_cat_g1v2
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, -- Extracting this part to match with sls_prd_key from bronze.crm_sales_details
			prd_nm,
			ISNULL(prd_cost, 0) AS prd_cost, -- Replacing NULLs with 0 as stated by the senior data architect
			CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'Unknown'
			END AS prd_line, -- Giving meaningful values to prd_line
			CAST(prd_start_dt AS DATE) AS prd_start_dt, -- Converting prd_start_dt into DATE as it doesn't have time.
			DATEADD(
					DAY,
					-1,
					prd_end_dt_test
				) AS prd_end_dt -- Subtracting 1 day from prd_end_dt_test to make exclusive boundaries
		FROM (
				SELECT
					*,
					LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt ASC) AS prd_end_dt_test
				FROM Bronze.crm_prd_info
			) AS t;  -- Getting the next date for each product to be treated as the end date.
		SET @end_time = GETDATE();
        PRINT 'Time Taken to Load: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' Seconds';
        PRINT '------------------';

		-- Now we have completed the transformation for bronze.crm_prd_info and it's ready to be pushed into the
		-- silver.crm_prd_info, but wait! Let's see the resulting columns:
		-- prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
		-- and columns of silver.crm_prd_info are:
		-- prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt, dwh_create_dt
		-- The column cat_id doesn't exist in the silver.crm_prod_info, so we will add it and we have changed the data type of prd_start_dt
		-- and prd_end_dt to DATE instead of DATETIME2

		-------------------------------------------------------

		/*
			=======================================
			Bronze.crm_sales_details
			=======================================
		*/

		SET @start_time = GETDATE();
		PRINT 'Truncating table: Silver.crm_sales_details'
		TRUNCATE TABLE Silver.crm_sales_details
		PRINT 'Inserting into table: Silver.crm_sales_details'
		INSERT INTO Silver.crm_sales_details
		(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE
				WHEN 
						sls_order_dt IS NULL
						OR LEN(sls_order_dt) != 8
						OR sls_order_dt <= 0
						OR sls_order_dt > 20260128
						OR sls_order_dt < 19000101
				THEN NULL
				ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) -- Changing data type from INT to VARCHAR then to DATE
			END AS sls_order_dt, -- Checking for invalid dates and replace them with NULL then cast as date
			CASE
				WHEN 
						sls_ship_dt IS NULL
						OR LEN(sls_ship_dt) != 8
						OR sls_ship_dt <= 0
						OR sls_ship_dt > 20260128
						OR sls_ship_dt < 19000101
				THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) -- Changing data type from INT to VARCHAR then to DATE
			END AS sls_ship_dt, -- Checking for invalid dates and replace them with NULL then cast as date
			CASE
				WHEN 
						sls_due_dt IS NULL
						OR LEN(sls_due_dt) != 8
						OR sls_due_dt <= 0
						OR sls_due_dt > 20260128
						OR sls_due_dt < 19000101
				THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) -- Changing data type from INT to VARCHAR then to DATE
			END AS sls_due_dt, -- Checking for invalid dates and replace them with NULL then cast as date
			CASE
				WHEN
					sls_sales IS NULL -- Checking if sales is NULL
					OR sls_sales <= 0 -- Checking if sales is negative or zero
					OR sls_price IS NOT NULL -- Checking if price is NULL
					OR sls_sales != sls_quantity * ABS(sls_price) -- Checking if formula not correct
				THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
			END AS sls_sales,
			sls_quantity,
			CASE
				WHEN
					sls_price IS NULL
					OR sls_price <= 0
					OR sls_sales IS NOT NULL
					OR sls_price != CAST(
											(
												CAST(ABS(sls_sales) AS FLOAT) 
												/ NULLIF(sls_quantity, 0)
											)
										AS INT)
				THEN CAST((CAST(ABS(sls_sales) AS FLOAT) / NULLIF(sls_quantity, 0)) AS INT) -- Casting to be FLOAT for correct calculations
				ELSE sls_price
			END AS sls_price

		FROM Bronze.crm_sales_details;

		SET @end_time = GETDATE();
        PRINT 'Time Taken to Load: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' Seconds';
        PRINT '------------------';
		-- Now we are ready to push data into Silver.crm_sales_details. But first we need to change the data type of
		-- sls_order_dt, sls_ship_dt, and sls_due_dt (I have already done that in the ddl_silver)

		----------------------------------------------------------------------------------------------

		/*
			=======================================
			Bronze.erp_cust_az12
			=======================================
		*/

		SET @start_time = GETDATE();
		PRINT 'Truncating table: Silver.erp_cust_az12'
		TRUNCATE TABLE Silver.erp_cust_az12
		PRINT 'Inserting into table: Silver.erp_cust_az12'
		INSERT INTO Silver.erp_cust_az12 (cid, bdate, gen)
		SELECT
			CASE
				WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Matching values of erp_cust_az12(cid) with crm_cust_info(cst_id)
				ELSE cid
			END AS cid,
			CASE
				WHEN bdate < '1900-01-01' OR bdate > GETDATE() THEN NULL -- NULLing out-of-range dates
				ELSE bdate
			END AS bdate,
			CASE
				WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
				ELSE 'Unknown'
			END AS gen
		FROM Bronze.erp_cust_az12;

		SET @end_time = GETDATE();
        PRINT 'Time Taken to Load: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' Seconds';
        PRINT '------------------';
		-------------------------------------------------------------

		/*
			=======================================
			Bronze.erp_loc_a101
			=======================================
		*/

		SET @start_time = GETDATE();
		PRINT 'Truncating table: Silver.erp_loc_a101'
		TRUNCATE TABLE Silver.erp_loc_a101
		PRINT 'Inserting into table: Silver.erp_loc_a101'
		INSERT INTO Silver.erp_loc_a101 (cid, cntry)
		SELECT
			REPLACE(cid, '-', '') AS cid, -- Make it match the cst_id from crm_cust_info and cid from erp_cust_az12
			CASE
				WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
				WHEN TRIM(cntry) = 'DE' THEN 'Germany'
				WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'Unknown'
				ELSE TRIM(cntry)
			END AS cntry -- Handling inconsistencies in cntry
		FROM Bronze.erp_loc_a101;

		SET @end_time = GETDATE();
        PRINT 'Time Taken to Load: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' Seconds';
        PRINT '------------------';
		-------------------------------------------------------------

		/*
			=======================================
			Bronze.erp_px_cat_g1v2
			=======================================
		*/

		SET @start_time = GETDATE();
		PRINT 'Truncating table: Silver.erp_px_cat_g1v2'
		TRUNCATE TABLE Silver.erp_px_cat_g1v2
		PRINT 'Inserting into table: Silver.erp_px_cat_g1v2'
		INSERT INTO Silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
		SELECT
			id,
			cat,
			subcat,
			maintenance
		FROM Bronze.erp_px_cat_g1v2;

		SET @end_time = GETDATE();
        PRINT 'Time Taken to Load: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' Seconds';
        PRINT '------------------';

		SET @batch_end_time = GETDATE();
        PRINT '==================================';
        PRINT 'Loading Bronze Layer is Complete';
        PRINT 'Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS VARCHAR) + ' Seconds';
        PRINT '==================================';

	END TRY
	BEGIN CATCH
        PRINT '==================================';
        PRINT 'Error Occurred During Loading Bronze Layer';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS VARCHAR);
        PRINT '==================================';
    END CATCH
END


EXEC Silver.load_silver;