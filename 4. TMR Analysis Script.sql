
Use Skynet;

-- Main query to fetch policy numbers with their respective tmr values for the given months
select				[Policy Number],
					--,ISNULL([202505], 0) [202505] 
				--	,ISNULL([202508], 0) [202508] 
				ISNULL([202509], 0) AS [202509] 
					,ISNULL([202510], 0) AS [202510] 
from (
		-- Subquery to get necessary fields
		select		[Policy Number]
					--,[202505]
					,[202509]
					,[202510]
		from (
				select	policy_no [Policy Number]
						,tmr
						,valuation_month
				from	NONTEMP_AA1_TMRHIST
				--select distinct valuation_month from	Skynet.dbo.NONTEMP_AA1_TMRHIST
				where	product = --Filter by product
								--	'Wty Booster'
									--'Wty Non-Booster'
									'Scratch n Dents'
									--'AdCover'
									--'Deposit Cover'
									--'LPP'
				and		valuation_month in ( 202509, 202510) -- Filter by the specified months
				) t

pivot	(
				sum(tmr) for valuation_month in ( [202509], [202510] )
		) r) n
;
