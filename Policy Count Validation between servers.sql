-- Total policy counts per server
-- Count from MS-ACT01
SELECT COUNT(*) AS total_policies, 'MS-ACT01' AS Source
FROM [MS-ACT01].[Evolve].[dbo].[Policy]
WHERE POL_CreateDate < '2025-08-01';				------------->Update

-- Count from UPP
SELECT COUNT(*) AS total_policies, 'UPP' AS Source
FROM [MS-ACT01].[UPP].[dbo].[SAW_UPP_202506_Test];				------------->Update

-- Count from EVPRODREP01
SELECT COUNT(*) AS total_policies, 'EVPRODREP01' AS Source
FROM [EVPRODREP01].[Evolve].[dbo].[Policy]
WHERE POL_CreateDate < '2025-08-01';				------------->Update

-- Count from EVPRODSQL02
SELECT COUNT(*) AS total_policies, 'EVPRODSQL02' AS Source
FROM [EVPRODSQL02].[Evolve].[dbo].[Policy]
WHERE POL_CreateDate < '2025-08-01';				------------->Update

-- From EVPRODREP01 --> Missing in MS-ACT01
SELECT 
    'Missing from MS-ACT01 (found in EVPRODREP01)' AS Source,
    p2.POL_PolicyNumber,
    p2.POL_StartDate,
    p2.POL_SoldDate
FROM [EVPRODREP01].[Evolve].[dbo].[Policy] p2
LEFT JOIN [MS-ACT01].[Evolve].[dbo].[Policy] p1 
    ON p2.POL_PolicyNumber = p1.POL_PolicyNumber
WHERE p1.POL_PolicyNumber IS NULL
  AND (p2.POL_PolicyNumber LIKE 'Q%' OR p2.POL_PolicyNumber LIKE 'H%')
  AND p2.POL_CreateDate < '2025-08-01'				------------->Update
ORDER BY p2.POL_PolicyNumber ASC, p2.POL_StartDate DESC;

-- From UPP --> Missing in MS-ACT01, with frequency
SELECT 
    'Missing from UPP (found in EVPRODREP01)' AS Source,
    p3.POL_PolicyNumber,
    p3.POL_StartDate,
    p3.POL_EndDate,
    p3.POL_SoldDate,
    RTF.RTF_Description AS [POLICY FREQUENCY],
    POS.POS_Description AS [POLICY STATUS]
FROM [EVPRODREP01].[Evolve].[dbo].[Policy] p3
LEFT JOIN [MS-ACT01].[UPP].[dbo].[SAW_UPP_202506_Test] p1				------------->Update
    ON p3.POL_PolicyNumber = p1.POL_PolicyNumber

-- Frequency join
LEFT JOIN [EVPRODREP01].[Evolve].[dbo].[ReferenceTermFrequency] RTF 
    ON RTF.TermFrequency_Id = p3.POL_ProductTerm_ID

-- Status join
LEFT JOIN [EVPRODREP01].[Evolve].[dbo].[ReferencePolicyStatus] POS 
    ON POS.PolicyStatus_ID = p3.POL_Status

WHERE p1.POL_PolicyNumber IS NULL
  AND (p3.POL_PolicyNumber LIKE 'Q%' OR p3.POL_PolicyNumber LIKE 'H%')
  AND p3.POL_CreateDate < '2025-08-01'				------------->Update
  AND p3.POL_EndDate > '2025-08-01'				------------->Update
  AND RTF.RTF_Description <> 'Monthly'
  AND POS.POS_Description = 'In Force'
ORDER BY p3.POL_PolicyNumber ASC, p3.POL_StartDate DESC;

-- From EVPRODSQL02 --> Missing in MS-ACT01
SELECT 
    'Missing from MS-ACT01 (found in EVPRODSQL02)' AS Source,
    p4.POL_PolicyNumber,
    p4.POL_StartDate,
    p4.POL_SoldDate
FROM [EVPRODSQL02].[Evolve].[dbo].[Policy] p4
LEFT JOIN [MS-ACT01].[Evolve].[dbo].[Policy] p1 
    ON p4.POL_PolicyNumber = p1.POL_PolicyNumber
WHERE p1.POL_PolicyNumber IS NULL
  AND (p4.POL_PolicyNumber LIKE 'Q%' OR p4.POL_PolicyNumber LIKE 'H%')
  AND p4.POL_CreateDate < '2025-08-01'
ORDER BY p4.POL_PolicyNumber ASC, p4.POL_StartDate DESC;
