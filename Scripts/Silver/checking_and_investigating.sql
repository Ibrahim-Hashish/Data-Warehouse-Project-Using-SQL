/*
	===================
	Detection problems
	===================
*/

/*
	=====================
	Bronze.crm_cust_info
	====================
*/

-- Detecting Duplicates
SELECT *
FROM Bronze.crm_cust_info
WHERE cst_id IN (
					SELECT cst_id
					FROM Bronze.crm_cust_info
					GROUP BY cst_id
					HAVING COUNT(cst_id) > 1
				);

-- Detecting NULLs in PRIMARY KEY (cst_id)
SELECT *
FROM Bronze.crm_cust_info
WHERE cst_id IS NULL;

-- Detecting unwanted spaces in all text columns (cst_firstname, cst_lastname, cst_marital_status, cst_gndr)

-- Yes
SELECT *
FROM Bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

-- Yes
SELECT *
FROM Bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- No
SELECT *
FROM Bronze.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status);

-- No
SELECT *
FROM Bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);

-- Data quality check in cst_marital_status and cst_gndr:
-- NULL, S => Single, M => Married
SELECT DISTINCT cst_marital_status
FROM Bronze.crm_cust_info;

-- NULL, F => Female, M => Male
SELECT DISTINCT cst_gndr
FROM Bronze.crm_cust_info;
-----------------------------------------------------------------------------

/*
	=====================
	Bronze.crm_prd_info
	====================
*/

-- Detecting duplicates or NULLs
-- No duplicates or NULLs
SELECT prd_id
FROM Bronze.crm_prd_info
WHERE prd_id IS NOT NULL
GROUP BY prd_id
HAVING COUNT(prd_id) > 1;

-- Checking for unwanted spaces in prd_key, prd_nm, and prd_line

-- No
SELECT *
FROM bronze.crm_prd_info
WHERE prd_key != TRIM(prd_key);

-- No
SELECT *
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- No
SELECT *
FROM bronze.crm_prd_info
WHERE prd_line != TRIM(prd_line);

-- Checking for NULLs or negative values in prd_cost
-- There are NULLs
SELECT *
FROM Bronze.crm_prd_info
WHERE prd_cost < 0
	OR prd_cost IS NULL;

-- Checking for quality and distinctness in prd_line
-- NULL => Unknown, M => Mountain, R => Road, S => Other Sales, T => Touring
SELECT DISTINCT prd_line
FROM Bronze.crm_prd_info;

-- Checking for dates:
SELECT *
FROM Bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt;
-- The start date is greater than end date, now we will check if it's true for the whole table.
SELECT COUNT(*) -- 200
FROM Bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

SELECT COUNT(*) -- 397
FROM Bronze.crm_prd_info;
-- It's true for only 200 rows out of 397, why is that? let's see
SELECT *
FROM Bronze.crm_prd_info
WHERE prd_start_dt IS NULL
	OR prd_end_dt IS NULL;

SELECT COUNT(*) -- 197
FROM Bronze.crm_prd_info
WHERE prd_start_dt IS NULL
	OR prd_end_dt IS NULL;
-- So, it happens because the prd_end_dt is NULL.
-- The quickest fix for this problem is that we switch prd_start_dt with prd_end_dt
SELECT
	prd_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_end_dt AS prd_start_dt,
	prd_start_dt AS prd_end_dt
FROM Bronze.crm_prd_info;
-- This approach is not correct, why? You will see that for prd_key AC-HE-HL-U509-R:
/*
	212	AC-HE-HL-U509-R	Sport-100 Helmet- Red	12	S 	2007-12-28	2011-07-01
	213	AC-HE-HL-U509-R	Sport-100 Helmet- Red	14	S 	2008-12-27	2012-07-01
	214	AC-HE-HL-U509-R	Sport-100 Helmet- Red	13	S 	NULL		2013-07-01
*/ 
-- There is overlapping intervals 2007:2011 and 2008:2012
-- After revising with the expert, he said that the best approach is to treat the prd_start_dt as it is and make
-- the prd_end_date = next(prd_start_dt) - 1

-----------------------------------------------------------------------------

/*
	========================
	Bronze.crm_sales_details
	========================
*/
SELECT * FROM Bronze.crm_sales_details;
-- Dealing with duplicates and NULLS in sls_ord_num
-- No duplicates, No NULLs
SELECT sls_ord_num
FROM Bronze.crm_sales_details
GROUP BY sls_ord_num
HAVING COUNT(*) > 1
	AND sls_ord_num IS NULL;

-- Checking if there is any sls_prd_key that is not in the Silver.crm_prd_info
-- No value, so all sls_prd_key exist in Silver.crm_prd_info
SELECT *
FROM Silver.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM Silver.crm_prd_info);

-- Checking if there is any sls_cust_id that is not in the Silver.crm_cust_info
-- No value, so all sls_cust_id exist in Silver.crm_cust_info
SELECT *
FROM Silver.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM Silver.crm_cust_info);

-- Checking invalid dates

-- sls_order_dt
-- Yes
SELECT *
FROM Bronze.crm_sales_details
WHERE sls_order_dt IS NULL
	OR LEN(sls_order_dt) != 8
	OR sls_order_dt <= 0
	OR sls_order_dt > 20260128
	OR sls_order_dt < 19000101;

-- sls_ship_dt
-- No
SELECT *
FROM Bronze.crm_sales_details
WHERE sls_ship_dt IS NULL
	OR LEN(sls_ship_dt) != 8
	OR sls_ship_dt <= 0
	OR sls_ship_dt > 20260128
	OR sls_ship_dt < 19000101;

-- sls_due_dt
-- No
SELECT *
FROM Bronze.crm_sales_details
WHERE sls_due_dt IS NULL
	OR LEN(sls_due_dt) != 8
	OR sls_due_dt <= 0
	OR sls_due_dt > 20260128
	OR sls_due_dt < 19000101;

-- Checking for negative values, NULLs, and bad results in sls_sales, sls_quantity, and sls_price
SELECT *
FROM Bronze.crm_sales_details
WHERE 
	(sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL)
	OR (sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0)
	OR (sls_sales != sls_quantity * sls_price)
ORDER BY sls_sales, sls_quantity, sls_price;
-- sls_sales has NULLs, negative values, and zero values
-- sls_quantity doesn't have NULLs or negative or zero values
-- sls_price has NULLs and negative values

--------------------------------------------------------------------

/*
	========================
	Bronze.erp_cust_az12
	========================
*/

SELECT *
FROM Bronze.erp_cust_az12;
-- Since this table will be connected to crm_cust_info(cst_key), we will check first the id from both tables
SELECT cid
FROM Bronze.erp_cust_az12;

SELECT cst_key
FROM Bronze.crm_cust_info;
-- In the cid, sometimes there are extra characters 'NAS' at the front of the id, so we need to remove them.

-- Checking NULLs or duplicates in cid
-- No NULLs, No duplicates
SELECT cid
FROM Bronze.erp_cust_az12
GROUP BY cid
HAVING COUNT(cid) > 1
	OR cid IS NULL;

-- Checking NULLs in bdate
-- No
SELECT *
FROM Bronze.erp_cust_az12
WHERE bdate IS NULL;

-- Checking out-of-range values in bdate
-- Yes
SELECT *
FROM Bronze.erp_cust_az12
WHERE bdate < '1900-01-01'
	OR bdate > GETDATE()
ORDER BY bdate ASC;

-- Checking NULLs in gen
-- Yes
SELECT *
FROM Bronze.erp_cust_az12
WHERE gen IS NULL;

-- Checking distinctness in gen
SELECT DISTINCT gen -- NULL, SPACE, F, M, FEMALE, and MALE
FROM Bronze.erp_cust_az12;
-------------------------------------------------------------

/*
	=======================================
	Bronze.erp_loc_a101
	=======================================
*/

SELECT *
FROM Bronze.erp_loc_a101;
-- Checking cid:
-- NULLs and duplicates
-- No
SELECT cid
FROM Bronze.erp_loc_a101
GROUP BY cid
HAVING COUNT(cid) > 1
	OR cid IS NULL;
-- cid must be like the cid in Silver.erp_cust_az12 and cst_key in Silver.crm_cust_info

-- Checking cntry:
SELECT DISTINCT cntry -- NULL, SPACE, DE, USA, US, Germany, United States, Australia, United Kingdom, Canada, and France
FROM Bronze.erp_loc_a101;

-------------------------------------------------------------

/*
	=======================================
	Bronze.erp_px_cat_g1v2
	=======================================
*/

-- Checking NULLs or duplicates in id
-- No NULLs, No duplicates and it matches the cat_id from crm_prd_info
SELECT id
FROM Bronze.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(id) > 1
	OR id IS NULL;

-- Checking NULLs in cat
-- No
SELECT *
FROM Bronze.erp_px_cat_g1v2
WHERE cat IS NULL;

-- Checking quality and domain of cat
-- There is no problems
SELECT DISTINCT cat
FROM Bronze.erp_px_cat_g1v2
WHERE cat = TRIM(cat);

-- Checking NULLs in subcat and quality issues
-- There is no problems
SELECT DISTINCT subcat
FROM Bronze.erp_px_cat_g1v2
WHERE subcat IS NULL
	OR subcat = TRIM(subcat);

-- Checking NULLs and quality issues in maintenance
-- There is no problems
SELECT DISTINCT maintenance
FROM Bronze.erp_px_cat_g1v2
WHERE maintenance IS NULL
	OR maintenance = TRIM(maintenance);











 


