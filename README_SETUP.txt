====================================================================
UPP MONTHLY ROLL FORWARD - STORED PROCEDURE SETUP INSTRUCTIONS
====================================================================

OVERVIEW:
This setup converts your monthly UPP Roll Forward scripts into stored 
procedures for easy, one-click execution each month.

====================================================================
ONE-TIME SETUP (Do this once)
====================================================================

STEP 1: Create the Non-Booster Stored Procedure
------------------------------------------------
1. Open file: SP_01_Create_RunWarrantyUPPNonBooster.sql
2. Copy the ENTIRE contents of "2.1 RunWarrantyUPPNonBooster.sql"
   starting from line 15 (Drop table if exists #t1) to line 854
3. Paste it into SP_01_Create_RunWarrantyUPPNonBooster.sql where 
   it says "PASTE THE ENTIRE CONTENTS HERE"
4. Make these changes in the pasted code:
   a) DELETE these lines:
      - Declare @ValuationMonth date = '2025-09-30';
      - Declare @Commission float = 0.125;
      - Declare @ClaimsBinder float = 4 * 1.0000000 / 9;
      - Declare @Binder float = 0.09;
   
   b) FIND this section at the end (around line 850):
      Into [UPP].[dbo].[SAW_UPP_202509_NonBooster]
      
      REPLACE with:
      -- Remove the INTO clause, we'll use dynamic SQL
   
   c) UNCOMMENT the line: -- EXEC sp_executesql @SQL;
      (Remove the -- at the beginning)

5. Execute the entire SP_01 script in SSMS to create the procedure

STEP 2: Create the Booster Stored Procedure
--------------------------------------------
1. Open file: SP_02_Create_RunWarrantyUPPBooster.sql
2. Copy the ENTIRE contents of "2.2 RunWarrantyUPPBoosterWith BinderCurve.sql"
   starting from line 13 (Drop table if exists #t1) to the end
3. Paste it into SP_02_Create_RunWarrantyUPPBooster.sql where 
   it says "PASTE THE ENTIRE CONTENTS HERE"
4. Make the same changes as in STEP 1 (remove DECLARE statements,
   update the final INSERT INTO, uncomment EXEC)
5. Execute the entire SP_02 script in SSMS to create the procedure

====================================================================
MONTHLY EXECUTION (Do this every month)
====================================================================

STEP 1: Update Parameters
--------------------------
Open: 00_MASTER_RUN_ALL.sql

Find this section and update the dates/table names:

    DECLARE @ValuationMonth DATE = '2025-10-31';  -- Change month
    DECLARE @OutputTable1 VARCHAR(100) = 'SAW_UPP_202510_NonBooster';
    DECLARE @OutputTable2 VARCHAR(100) = 'SAW_UPP_202510_Booster';
    DECLARE @OutputTableFinal VARCHAR(100) = 'SAW_UPP_202510';

STEP 2: Execute
---------------
1. Press F5 (or click Execute)
2. Wait approximately 60 minutes
3. Monitor the output window for progress
4. Review the final verification summary

STEP 3: Verify Results
----------------------
The script will automatically display:
- Record counts for each table
- Number of duplicates removed
- Total execution time
- Match status (should say "YES ✓")

====================================================================
FILES IN THIS FOLDER:
====================================================================

ONE-TIME SETUP FILES:
- SP_01_Create_RunWarrantyUPPNonBooster.sql  (Run once to create SP)
- SP_02_Create_RunWarrantyUPPBooster.sql     (Run once to create SP)
- README_SETUP.txt                           (This file)

MONTHLY EXECUTION:
- 00_MASTER_RUN_ALL.sql                      (Run monthly - main script)

ORIGINAL SCRIPTS (Keep for reference):
- 2.1 RunWarrantyUPPNonBooster.sql
- 2.2 RunWarrantyUPPBoosterWith BinderCurve.sql
- 2.3 Merge Tables.sql
- 2.4 Check and Remove duplicates.sql

====================================================================
BENEFITS OF THIS APPROACH:
====================================================================

✓ One file to edit (00_MASTER_RUN_ALL.sql)
✓ One click to run everything
✓ Automatic progress tracking
✓ Automatic verification
✓ Consistent execution every month
✓ Easy to maintain and update
✓ Stored procedures can be called from other scripts

====================================================================
TROUBLESHOOTING:
====================================================================

Q: Error "Could not find stored procedure 'sp_RunWarrantyUPPNonBooster'"
A: You need to complete the ONE-TIME SETUP steps above

Q: Script fails at merge step
A: Check that both output tables were created successfully

Q: Duplicate count doesn't match
A: This is normal - the script removes duplicates automatically

Q: Takes longer than expected
A: Check server load, database size, and ensure indexes are created

====================================================================
SUPPORT:
====================================================================

For issues or questions, contact your database administrator or
the actuarial team lead.

Last Updated: October 2025
====================================================================
