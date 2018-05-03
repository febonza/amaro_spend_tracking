---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
-- #1 - Sessions transformations
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
truncate table manual_data_sources.ga_sessions;
INSERT INTO manual_data_sources.ga_sessions (date
       , traffic_type
       , group_channel
       , medium
       , source
       , campaign
       , adcontent
       , keyword
       , newusers
       , pageviews
       , sessions
       , percentnewsessions
       , transactions
       , bounces
)  
SELECT 
	date as date,
	null as traffic_type,
	null as group_channel,
	medium as medium,
	source as source,
	campaign as campaign,
	adcontent as adcontent,
	keyword as keyword,
	newusers as newusers,
	pageviews as pageviews,
	sessions as sessions,
	percentnewsessions as percentnewsessions,
	transactions as transactions,
	bounces as bounces
	--insert_ts
from
fact_ga_sessions.report 
where date >='2016-01-01'
;


----------------------------------------------
-- Google
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Paid',
	source='google',
	medium=CASE
  		WHEN campaign like 'Criteo%' then 'sem'
		WHEN campaign like 'Display%' then 'sem'
		WHEN campaign like 'Pesquisa%' then 'sem'
		WHEN campaign like 'Shopping%' then 'sem'
		WHEN campaign like 'Youtube%' then 'sem'
		WHEN campaign = '(not set)' then 'sem'
		ELSE 'others'
  		END,
	group_channel=CASE
  		WHEN campaign like 'Criteo%' then 'SEM'
		WHEN campaign like 'Display%' then 'Display'
		WHEN campaign like 'Pesquisa%' then 'SEM'
		WHEN campaign like 'Shopping%' then 'SEM'
		WHEN campaign like 'Youtube%' then 'SEM'
		WHEN campaign = '(not set)' then 'SEM'
		ELSE 'Others'
  		END,
	update_ts=current_timestamp
WHERE
	source = 'google'
	and medium in ('sem','cpc');

----------------------------------------------
-- Facebook / Paid Social
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Paid',
	source='facebook',
	medium='paid-social',
	group_channel='Paid Social',
	update_ts=current_timestamp,
	campaign=case when campaign = 'DPA' then 'dpa'
              when campaign = 'RET' then 'ret'
              when campaign = 'ACQ' then 'acq'
              when lower(campaign) = 'acquisition' then 'acq'
              when lower(campaign) = 'retention' then 'ret'
              when lower(campaign) = 'engagement' then 'eng'
              when lower(campaign) = 'branding' then 'bra'
              when campaign = 'RF_17A03_video' then 'bra'
              else campaign
              end
WHERE
	source = 'facebook'
	and medium in ('paid_social','cpc');

UPDATE manual_data_sources.ga_sessions 
SET traffic_type='Paid',
	group_channel='Paid Social',
	source='instagram',
	medium='paid-social',
	update_ts=current_timestamp
	from manual_data_sources.utm_sources_rules rls join manual_data_sources.ga_sessions ga
	on (ga.source || ' / ' || ga.medium) = rls.old_source_medium
	and rls.group_channel in ('Influencers')
	where ga.traffic_type is null;

----------------------------------------------
-- Bing
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Paid',
	source='bing',
	medium='cpc',
	group_channel='SEM',
	update_ts=current_timestamp
WHERE
	source = 'bing'
	and medium = 'cpc';

----------------------------------------------
-- Email
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Organic',
	group_channel=CASE
        WHEN medium in ('email-newsletter','email-automatic') THEN 'Email'
        WHEN medium = 'email-transactional' THEN 'Transactional Email'
        WHEN medium in ('push-blast','push-automatic') THEN 'Push'
        ELSE 'Email Others'
		END,
	update_ts=current_timestamp
WHERE
	medium in ('email-newsletter','email-automatic','email-transactional','push-blast','push-automatic');
	
UPDATE manual_data_sources.ga_sessions 
SET traffic_type='Organic',
	group_channel=rls.group_channel,
	source=rls.source,
	medium=rls.medium,
	update_ts=current_timestamp
	from manual_data_sources.utm_sources_rules rls join manual_data_sources.ga_sessions ga
	on (ga.source || ' / ' || ga.medium) = rls.old_source_medium
	and rls.group_channel in ('Email','Transactional Email','Push')
	where ga.traffic_type is null;


----------------------------------------------
-- SEO
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Organic',
	group_channel='SEO',
	update_ts=current_timestamp
WHERE
	medium like 'organic';
	
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Organic',
	group_channel='SEO',
	update_ts=current_timestamp
WHERE
	medium like 'referral' and source='google';

----------------------------------------------
-- Criteo
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Paid',
	group_channel='Retargeters',
	source='criteo',
	medium='retargeting',
	campaign=CASE
		WHEN campaign like '%low%' then 'lowerfunnel'
		WHEN campaign like '(not set)' then 'lowerfunnel'
		WHEN campaign like '%mid%' then 'midfunnel'
		WHEN campaign like '%logo%' then 'lowerfunnel'
		WHEN campaign like '%customeracquisition%' then 'customeracquisition'
		ELSE campaign
		END,
	update_ts=current_timestamp
WHERE
	(source || ' / ' || medium) like '%criteo%';

----------------------------------------------
-- RTBHouse
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Paid',
	group_channel='Retargeters',
	source='rtbhouse',
	medium='retargeting',
	update_ts=current_timestamp
WHERE
	source='rtbhouse';
	
----------------------------------------------
-- Outbrain
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Paid',
	group_channel='Display',
	source='outbrain',
	medium='display',
	update_ts=current_timestamp
WHERE
	source like '%outbrain%';
	
----------------------------------------------
-- Gemini
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Paid',
	group_channel='Display',
	source='gemini',
	update_ts=current_timestamp
WHERE
	source like '%gemini%';
	
----------------------------------------------
-- Direct Affiliates
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Paid',
	group_channel='Direct Affiliates',
	source=CASE
		WHEN (source || ' / ' || medium) like '%clooset%' THEN 'clooset'
		WHEN (source || ' / ' || medium) like '%ilove%' THEN 'ilovee'
		WHEN lower((source || ' / ' || medium)) like '%moda%it%' THEN 'modait'
		WHEN lower((source || ' / ' || medium)) like '%modait%' THEN 'modait'
		WHEN (source || ' / ' || medium) like '%muccashop%' THEN 'muccashop'
		WHEN lower((source || ' / ' || medium)) like '%steal%' THEN 'steal-the-look'
		WHEN (source || ' / ' || medium) like '%styight%' THEN 'styight'
		WHEN (source || ' / ' || medium) like '%um%so%lugar%' THEN 'um-so-lugar'
		WHEN (source || ' / ' || medium) like '%paraiso%' THEN 'paraiso-feminino'
		WHEN (source || ' / ' || medium) like '%uol%' THEN 'uol'
		ELSE source 
		end,
	medium='direct-affiliate',
	campaign='N/A',
	update_ts=current_timestamp
WHERE
	((source || ' / ' || medium) like '%clooset%' or
	(source || ' / ' || medium) like '%ilove%' or
	(source || ' / ' || medium) like '%muccashop%' or
	lower((source || ' / ' || medium)) like '%steal%' or
	(source || ' / ' || medium) like '%styight%' or
	(source || ' / ' || medium) like '%um%so%lugar%' or
	lower((source || ' / ' || medium)) like '%moda%it' or
	(source || ' / ' || medium) like '%modait' or
	source='modait' or
	(source || ' / ' || medium) like '%paraiso%');

----------------------------------------------
-- Affiliate Network
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Paid',
	group_channel='Affiliate Network',
	source=CASE
		WHEN (source || ' / ' || medium) like '%zanox%' THEN 'zanox'
		WHEN (source || ' / ' || medium) like '%looklink%' THEN 'looklink'
		WHEN (source || ' / ' || medium) like '%lomadee%' THEN 'lomadee'
		WHEN (source || ' / ' || medium) like '%insightmedia%' THEN 'insightmedia'
		WHEN (source || ' / ' || medium) like '%leadpix%' THEN 'leadpix'
		WHEN (source || ' / ' || medium) like '%weach%' THEN 'weach'
		WHEN (source || ' / ' || medium) = 'affiliate-network' THEN 'affiliate-network'
		ELSE source 
		end,
	/*campaign=CASE
  		WHEN (source || ' / ' || medium) like '%zanox%' AND date < '2018-04-20' THEN adcontent
		WHEN (source || ' / ' || medium) like '%zanox%' AND date >= '2018-05-01' THEN campaign 
		ELSE 'N/A'
  		END,*/
	medium='affiliate-network',
	update_ts=current_timestamp
WHERE
	((source || ' / ' || medium) like '%zanox%' or
			(source || ' / ' || medium) like '%looklink%' or
			(source || ' / ' || medium) like '%lomadee%' or
			(source || ' / ' || medium) like '%insightmedia%' or
			(source || ' / ' || medium) like '%leadpix%' or
			(source || ' / ' || medium) like '%weach%' or
			(source || ' / ' || medium) like '%affiliate-network%');

----------------------------------------------
-- Organic Social
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Organic',
	group_channel='Organic Social',
	medium='organic-social',
	source='facebook',
	update_ts=current_timestamp
WHERE
	medium='referral' and source like '%facebook%';
	
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Organic',
	group_channel='Organic Social',
	source='maps',
	medium='organic',
	update_ts=current_timestamp
WHERE
	source like '%organic%'
	and medium='maps'
	and traffic_type is null;

UPDATE manual_data_sources.ga_sessions
SET traffic_type='Organic',
	group_channel='Organic Social',
	source='instagram',
	medium='organic-social',
	update_ts=current_timestamp
WHERE
	source = 'organic'
	and medium in ('instagram','shop-insta','insta-stories','influencers')
	and traffic_type is null;
	
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Organic',
	group_channel='Organic Social',
	source='instagram',
	medium='organic-social',
	update_ts=current_timestamp
WHERE
	source = 'instagram'
	and medium in ('shop-insta','insta-stories','influencers','organic-social','stories')
	and traffic_type is null;


----------------------------------------------
-- Influencers
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Paid',
	group_channel='Influencers',
	update_ts=current_timestamp
	where
		medium='influencers'
		and traffic_type is null;


UPDATE manual_data_sources.ga_sessions 
SET traffic_type='Paid',
	group_channel=rls.group_channel,
	source=rls.source,
	medium=rls.medium,
	update_ts=current_timestamp
	from manual_data_sources.utm_sources_rules rls join manual_data_sources.ga_sessions ga
	on (ga.source || ' / ' || ga.medium) = rls.old_source_medium
	and rls.group_channel in ('Influencers')
	where ga.traffic_type is null;

----------------------------------------------
-- Referral
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Organic',
	group_channel='Referral',
	medium='referral',
	update_ts=current_timestamp
WHERE
	medium='referral'
	and traffic_type is null;
	
----------------------------------------------
-- Partners
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Paid',
	group_channel='Partners',
	medium='partners',
	update_ts=current_timestamp
WHERE
	medium='partners'
	and traffic_type is null;
	
----------------------------------------------
-- All the rest
UPDATE manual_data_sources.ga_sessions
SET traffic_type=rls.traffic_type,
	group_channel=rls.group_channel,
	source=rls.source,
	medium=rls.medium,
	update_ts=current_timestamp
	FROM manual_data_sources.utm_sources_rules rls join manual_data_sources.ga_sessions ga
	on (ga.source || ' / ' || ga.medium) = rls.old_source_medium
	--and rls.group_channel in ('Email','Transactional Email','Push')
	where ga.traffic_type is null;


----------------------------------------------
-- Others
UPDATE manual_data_sources.ga_sessions
SET traffic_type='Others',
	group_channel='Others',
	update_ts=current_timestamp
WHERe traffic_type is null;



---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
-- #2 Transactions transformations
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
truncate table manual_data_sources.ga_transactions;
INSERT INTO manual_data_sources.ga_transactions
(
	date ,
	traffic_type ,
	group_channel ,
	medium  ,
	source  ,
	campaign  ,
	keyword ,
	landingpagepath  ,
	transactionid  ,
	transactionrevenue  ,
	transactionshipping  ,
	itemquantity ,
	update_ts 
)
with rn as (
SELECT
	row_number() over (partition by transactionid) as rn,
	"start-date" as date,
	null as traffic_type,
	null as group_channel,
	medium as medium,
	source as source,
	campaign as campaign,
	keyword as keyword,
	landingpagepath as landingpagepath,
	transactionid as transactionid,
	transactionrevenue as transactionrevenue,
	transactionshipping as transactionshipping,
	itemquantity as itemquantity,
	current_timestamp as update_ts
FROM
	ga_transactions.report
WHERE
	"start-date"='2018-01-25'
)
select 
	date,
	traffic_type,
	group_channel,
	medium,
	source,
	campaign,
	keyword,
	landingpagepath,
	transactionid,
	transactionrevenue,
	transactionshipping,
	itemquantity,
	update_ts
from rn
where rn=1


----------------------------------------------
-- Google
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Paid',
	source='google',
	medium=CASE
  		WHEN campaign like 'Criteo%' then 'sem'
		WHEN campaign like 'Display%' then 'sem'
		WHEN campaign like 'Pesquisa%' then 'sem'
		WHEN campaign like 'Shopping%' then 'sem'
		WHEN campaign like 'Youtube%' then 'sem'
		WHEN campaign = '(not set)' then 'sem'
		ELSE 'others'
  		END,
	group_channel=CASE
  		WHEN campaign like 'Criteo%' then 'SEM'
		WHEN campaign like 'Display%' then 'Display'
		WHEN campaign like 'Pesquisa%' then 'SEM'
		WHEN campaign like 'Shopping%' then 'SEM'
		WHEN campaign like 'Youtube%' then 'SEM'
		WHEN campaign = '(not set)' then 'SEM'
		ELSE 'Others'
  		END,
	update_ts=current_timestamp
WHERE
	source = 'google'
	and medium in ('sem','cpc');

----------------------------------------------
-- Facebook / Paid Social
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Paid',
	source='facebook',
	medium='paid-social',
	group_channel='Paid Social',
	update_ts=current_timestamp,
	campaign=case when campaign = 'DPA' then 'dpa'
              when campaign = 'RET' then 'ret'
              when campaign = 'ACQ' then 'acq'
              when lower(campaign) = 'acquisition' then 'acq'
              when lower(campaign) = 'retention' then 'ret'
              when lower(campaign) = 'engagement' then 'eng'
              when lower(campaign) = 'branding' then 'bra'
              when campaign = 'RF_17A03_video' then 'bra'
              else campaign
              end
WHERE
	source = 'facebook'
	and medium in ('paid_social','cpc');

UPDATE manual_data_sources.ga_transactions 
SET traffic_type='Paid',
	group_channel='Paid Social',
	source='instagram',
	medium='paid-social',
	update_ts=current_timestamp
	from manual_data_sources.utm_sources_rules rls join manual_data_sources.ga_transactions ga
	on (ga.source || ' / ' || ga.medium) = rls.old_source_medium
	and rls.group_channel in ('Influencers')
	where ga.traffic_type is null;

----------------------------------------------
-- Bing
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Paid',
	source='bing',
	medium='cpc',
	group_channel='SEM',
	update_ts=current_timestamp
WHERE
	source = 'bing'
	and medium = 'cpc';

----------------------------------------------
-- Email
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Organic',
	group_channel=CASE
        WHEN medium in ('email-newsletter','email-automatic') THEN 'Email'
        WHEN medium = 'email-transactional' THEN 'Transactional Email'
        WHEN medium in ('push-blast','push-automatic') THEN 'Push'
        ELSE 'Email Others'
		END,
	update_ts=current_timestamp
WHERE
	medium in ('email-newsletter','email-automatic','email-transactional','push-blast','push-automatic');
	
UPDATE manual_data_sources.ga_transactions 
SET traffic_type='Organic',
	group_channel=rls.group_channel,
	source=rls.source,
	medium=rls.medium,
	update_ts=current_timestamp
	from manual_data_sources.utm_sources_rules rls join manual_data_sources.ga_transactions ga
	on (ga.source || ' / ' || ga.medium) = rls.old_source_medium
	and rls.group_channel in ('Email','Transactional Email','Push')
	where ga.traffic_type is null;


----------------------------------------------
-- SEO
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Organic',
	group_channel='SEO',
	update_ts=current_timestamp
WHERE
	medium like 'organic';
	
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Organic',
	group_channel='SEO',
	update_ts=current_timestamp
WHERE
	medium like 'referral' and source='google';

----------------------------------------------
-- Criteo
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Paid',
	group_channel='Retargeters',
	source='criteo',
	medium='retargeting',
	campaign=CASE
		WHEN campaign like '%low%' then 'lowerfunnel'
		WHEN campaign like '(not set)' then 'lowerfunnel'
		WHEN campaign like '%mid%' then 'midfunnel'
		WHEN campaign like '%logo%' then 'lowerfunnel'
		WHEN campaign like '%customeracquisition%' then 'customeracquisition'
		ELSE campaign
		END,
	update_ts=current_timestamp
WHERE
	(source || ' / ' || medium) like '%criteo%';

----------------------------------------------
-- RTBHouse
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Paid',
	group_channel='Retargeters',
	source='rtbhouse',
	medium='retargeting',
	update_ts=current_timestamp
WHERE
	source='rtbhouse';
	
----------------------------------------------
-- Outbrain
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Paid',
	group_channel='Display',
	source='outbrain',
	medium='display',
	update_ts=current_timestamp
WHERE
	source like '%outbrain%';
	
----------------------------------------------
-- Gemini
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Paid',
	group_channel='Display',
	source='gemini',
	update_ts=current_timestamp
WHERE
	source like '%gemini%';
	
----------------------------------------------
-- Direct Affiliates
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Paid',
	group_channel='Direct Affiliates',
	source=CASE
		WHEN (source || ' / ' || medium) like '%clooset%' THEN 'clooset'
		WHEN (source || ' / ' || medium) like '%ilove%' THEN 'ilovee'
		WHEN lower((source || ' / ' || medium)) like '%moda%it%' THEN 'modait'
		WHEN lower((source || ' / ' || medium)) like '%modait%' THEN 'modait'
		WHEN (source || ' / ' || medium) like '%muccashop%' THEN 'muccashop'
		WHEN lower((source || ' / ' || medium)) like '%steal%' THEN 'steal-the-look'
		WHEN (source || ' / ' || medium) like '%styight%' THEN 'styight'
		WHEN (source || ' / ' || medium) like '%um%so%lugar%' THEN 'um-so-lugar'
		WHEN (source || ' / ' || medium) like '%paraiso%' THEN 'paraiso-feminino'
		WHEN (source || ' / ' || medium) like '%uol%' THEN 'uol'
		ELSE source 
		end,
	medium='direct-affiliate',
	campaign='N/A',
	update_ts=current_timestamp
WHERE
	((source || ' / ' || medium) like '%clooset%' or
	(source || ' / ' || medium) like '%ilove%' or
	(source || ' / ' || medium) like '%muccashop%' or
	lower((source || ' / ' || medium)) like '%steal%' or
	(source || ' / ' || medium) like '%styight%' or
	(source || ' / ' || medium) like '%um%so%lugar%' or
	lower((source || ' / ' || medium)) like '%moda%it' or
	(source || ' / ' || medium) like '%modait' or
	source='modait' or
	(source || ' / ' || medium) like '%paraiso%');

----------------------------------------------
-- Affiliate Network
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Paid',
	group_channel='Affiliate Network',
	source=CASE
		WHEN (source || ' / ' || medium) like '%zanox%' THEN 'zanox'
		WHEN (source || ' / ' || medium) like '%looklink%' THEN 'looklink'
		WHEN (source || ' / ' || medium) like '%lomadee%' THEN 'lomadee'
		WHEN (source || ' / ' || medium) like '%insightmedia%' THEN 'insightmedia'
		WHEN (source || ' / ' || medium) like '%leadpix%' THEN 'leadpix'
		WHEN (source || ' / ' || medium) like '%weach%' THEN 'weach'
		WHEN (source || ' / ' || medium) = 'affiliate-network' THEN 'affiliate-network'
		ELSE source 
		end,
	/*campaign=CASE
  		WHEN (source || ' / ' || medium) like '%zanox%' AND date < '2018-05-01' THEN adcontent
		WHEN (source || ' / ' || medium) like '%zanox%' AND date >= '2018-05-01' THEN campaign 
		ELSE 'N/A'
  		END,*/
	medium='affiliate-network',
	update_ts=current_timestamp
WHERE
	((source || ' / ' || medium) like '%zanox%' or
			(source || ' / ' || medium) like '%looklink%' or
			(source || ' / ' || medium) like '%lomadee%' or
			(source || ' / ' || medium) like '%insightmedia%' or
			(source || ' / ' || medium) like '%leadpix%' or
			(source || ' / ' || medium) like '%weach%' or
			(source || ' / ' || medium) like '%affiliate-network%');

----------------------------------------------
-- Organic Social
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Organic',
	group_channel='Organic Social',
	medium='organic-social',
	source='facebook',
	update_ts=current_timestamp
WHERE
	medium='referral' and source like '%facebook%';
	
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Organic',
	group_channel='Organic Social',
	source='maps',
	medium='organic',
	update_ts=current_timestamp
WHERE
	source like '%organic%'
	and medium='maps'
	and traffic_type is null;

UPDATE manual_data_sources.ga_transactions
SET traffic_type='Organic',
	group_channel='Organic Social',
	source='instagram',
	medium='organic-social',
	update_ts=current_timestamp
WHERE
	source = 'organic'
	and medium in ('instagram','shop-insta','insta-stories','influencers')
	and traffic_type is null;
	
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Organic',
	group_channel='Organic Social',
	source='instagram',
	medium='organic-social',
	update_ts=current_timestamp
WHERE
	source = 'instagram'
	and medium in ('shop-insta','insta-stories','influencers','organic-social','stories')
	and traffic_type is null;


----------------------------------------------
-- Influencers
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Paid',
	group_channel='Influencers',
	update_ts=current_timestamp
	where
		medium='influencers'
		and traffic_type is null;


UPDATE manual_data_sources.ga_transactions 
SET traffic_type='Paid',
	group_channel=rls.group_channel,
	source=rls.source,
	medium=rls.medium,
	update_ts=current_timestamp
	from manual_data_sources.utm_sources_rules rls join manual_data_sources.ga_transactions ga
	on (ga.source || ' / ' || ga.medium) = rls.old_source_medium
	and rls.group_channel in ('Influencers')
	where ga.traffic_type is null;

----------------------------------------------
-- Referral
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Organic',
	group_channel='Referral',
	medium='referral',
	update_ts=current_timestamp
WHERE
	medium='referral'
	and traffic_type is null;
	
----------------------------------------------
-- Partners
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Paid',
	group_channel='Partners',
	medium='partners',
	update_ts=current_timestamp
WHERE
	medium='partners'
	and traffic_type is null;
	
----------------------------------------------
-- All the rest
UPDATE manual_data_sources.ga_transactions
SET traffic_type=rls.traffic_type,
	group_channel=rls.group_channel,
	source=rls.source,
	medium=rls.medium,
	update_ts=current_timestamp
	FROM manual_data_sources.utm_sources_rules rls join manual_data_sources.ga_transactions ga
	on (ga.source || ' / ' || ga.medium) = rls.old_source_medium
	--and rls.group_channel in ('Email','Transactional Email','Push')
	where ga.traffic_type is null;


----------------------------------------------
-- Others
UPDATE manual_data_sources.ga_transactions
SET traffic_type='Others',
	group_channel='Others',
	update_ts=current_timestamp
WHERe traffic_type is null;


---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
-- #3 - Costs Transformations
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO marketing_costs.adwords
(
	date ,
	traffic_type ,
	group_channel ,
	campaign  ,
	adclicks ,
	adcost ,
	impressions ,
	update_ts 
)
select
	date as date,
	'Paid' as traffic_type,
	CASE
  		WHEN campaign like 'Criteo%' then 'SEM'
		WHEN campaign like 'Display%' then 'Display'
		WHEN campaign like 'Pesquisa%' then 'SEM'
		WHEN campaign like 'Shopping%' then 'SEM'
		WHEN campaign like 'Youtube%' then 'SEM'
		WHEN campaign = '(not set)' then 'SEM'
		ELSE 'SEM Others'
  	END as group_channel,
	campaign as campaign,
	adclicks as adclicks,
	adcost as adcost,
	impressions as impressions,
	current_timestamp as update_ts
FROM amarocom_amaro_all.campaigns60477872_v2 
WHERE date>='2016-01-01'
;






---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
--#4 Moving to consolidated table
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

------------------------------
-- sessions
------------------------------
truncate table spend_tracking.sessions;
INSERT INTO spend_tracking.sessions (date
	   , session_source
       , traffic_type
       , group_channel
       , medium
       , source
       , campaign
       , adcontent
       , keyword
       , newusers
       , pageviews
       , sessions
       , percentnewsessions
       , transactions
       , bounces
)  
SELECT 
	date as date,
	'Google Analytics' as session_source,
	traffic_type as traffic_type,
	group_channel as group_channel,
	medium as medium,
	source as source,
	campaign as campaign,
	adcontent as adcontent,
	keyword as keyword,
	newusers as newusers,
	pageviews as pageviews,
	sessions as sessions,
	percentnewsessions as percentnewsessions,
	transactions as transactions,
	bounces as bounces
from
manual_data_sources.ga_sessions
;



------------------------------
-- costs
------------------------------

--adwords

INSERT INTO marketing_costs.adwords
(
	date ,
	traffic_type ,
	group_channel ,
	campaign  ,
	adclicks ,
	adcost ,
	impressions ,
	update_ts 
)
select
	date as date,
	'Paid' as traffic_type,
	CASE
  		WHEN campaign like 'Criteo%' then 'SEM'
		WHEN campaign like 'Display%' then 'Display'
		WHEN campaign like 'Pesquisa%' then 'SEM'
		WHEN campaign like 'Shopping%' then 'SEM'
		WHEN campaign like 'Youtube%' then 'SEM'
		WHEN campaign = '(not set)' then 'SEM'
		ELSE 'SEM Others'
  	END as group_channel,
	campaign as campaign,
	adclicks as adclicks,
	adcost as adcost,
	impressions as impressions,
	current_timestamp as update_ts
FROM amarocom_amaro_all.campaigns60477872_v2 
WHERE date>='2016-01-01'
;

INSERT INTO spend_tracking.costs
(
	date ,
	cost_source ,
	traffic_type ,
	group_channel ,
	source,
	medium,
	campaign  ,
	adclicks ,
	adcost ,
	impressions ,
	update_ts 
)
SELECT date
	   , 'Adwords' as cost_source
       , traffic_type
       , group_channel
	   , campaign
	   , 'google' as source
	   , 'sem' as medium
       , adclicks
       , adcost
	   , impressions
       , update_ts
 FROM marketing_costs.adwords;

--facebook
INSERT INTO marketing_costs.facebook
(
	date ,
	cost_source ,
	traffic_type ,
	group_channel ,
	campaign  ,
	adclicks ,
	adcost ,
	impressions ,
	update_ts 
)
select
	date_start as date,
	'Facebook Nanigans' as cost_source,
	'Paid' as traffic_type,
	'Paid Social' as group_channel,
	CASE WHEN (fb.campaign_name like 'Nanigans%') THEN
    CASE
      WHEN lower(split_part(fb.campaign_name,'_',2)) = 'instagram' THEN 'ig'
      WHEN lower(split_part(fb.campaign_name,'_',2)) = 'retention' THEN 'ret'
      WHEN lower(split_part(fb.campaign_name,'_',2)) = 'engagement' THEN 'eng'
      WHEN lower(split_part(fb.campaign_name,'_',2)) = 'branding' THEN 'bra'
      WHEN lower(split_part(fb.campaign_name,'_',2)) = 'acquisition' THEN 'acq'
      WHEN lower(split_part(fb.campaign_name,'_',2))  = 'app install' then 'app install'
    ELSE lower(split_part(fb.campaign_name,'_',2))
  END
  ELSE fb.campaign_name END as campaign,
	clicks as adclicks,
	spend as adcost,
	impressions as impressions,
	current_timestamp as update_ts
FROM fact_facebook_cost.facebook_ads_insights_242635879264619 fb
WHERE date>='2016-01-01'
and fb.campaign_name like 'Nanigans%'
UNION ALL
select
	date_start as date,
	'Facebook Kenshoo' as cost_source,
	'Paid' as traffic_type,
	'Paid Social' as group_channel,
	CASE WHEN lower(fb.campaign_name) like 'app install%' THEN 'app install'
		WHEN lower(fb.campaign_name) like'%brand%' THEN 'bra'
		WHEN lower(fb.campaign_name) like'bra%' THEN 'bra'
		ELSE lower(fb.campaign_name)
	END as campaign,
	clicks as adclicks,
	spend as adcost,
	impressions as impressions,
	current_timestamp as update_ts
FROM fact_facebook_cost.facebook_ads_insights_242635879264619 fb
WHERE date>='2016-01-01'
AND fb.campaign_name not like 'Nanigans%'
;


INSERT INTO spend_tracking.costs
(
	date ,
	cost_source ,
	traffic_type ,
	group_channel ,
	source,
	medium,
	campaign  ,
	adclicks ,
	adcost ,
	impressions ,
	update_ts 
)
SELECT date
	   , cost_source
       , traffic_type
       , group_channel
	   , 'facebook' as source
	   , 'paid-social' as medium
	   , campaign
       , sum(adclicks)
       , sum(adcost)
	   , sum(impressions)
       , update_ts
 FROM marketing_costs.facebook
 group by 1,2,3,4,5,6,7,11;


---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
--#5 - Orders that are Untracked by GA
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
insert into manual_data_sources.ga_transactions (date,traffic_type,group_channel,campaign,itemquantity,medium,source,transactionid,transactionrevenue,transactionshipping,keyword,landingpagepath,update_ts)
with untracked_orders as (
select
	trunc(o.order_date) as order_date,
	o.order_number,
      CASE
        WHEN LEFT(o.order_number,3) NOT IN ('WEB','WAP','WPS','GSL','GSW','GSF','MKP','TEL','AMA','MKT','DEM','TRO') THEN
          CASE
            WHEN o.order_class = 'SALE' THEN 'WEB'
            WHEN o.order_class = 'SALE - MARKETPLACES' THEN 'MKP'
            ELSE '-'
          END
        WHEN LEFT(o.order_number,3) = 'WAP' AND o.store_id = 1 THEN 'APS'
        WHEN LEFT(o.order_number,3) = 'WAP' AND o.store_id > 1 THEN 'GSA'
        ELSE LEFT(o.order_number,3)
      END as channel_id	  
    from ecommerce_platform_master.orders o
where order_date >= '2016-01-01' --and order_date < '2018-04-20'
	and o.order_number not in (select transactionid from manual_data_sources.ga_transactions)
)
select
	untracked_orders.order_date,
	'Untracked' as traffic_type,
	CASE
		WHEN channel_id in ('WEB','WPS','GSW') THEN 'Untracked WEB'
		WHEN channel_id in ('WAP','APS','GSA') THEN 'Untracked WAP'
		WHEN channel_id = 'GSF' THEN 'GSF'
		WHEN channel_id = 'GSL' THEN 'GSL'
		WHEN channel_id = 'TEL' THEN 'TEL'
		WHEN channel_id = 'TRO' THEN 'TRO'
		WHEN channel_id = 'DEM' THEN 'DEM'
		WHEN channel_id = 'AMA' THEN 'AMA'
		WHEN channel_id = 'MKT' THEN 'MKT'
		WHEN channel_id = 'MKP' THEN 'MKP'
		ELSE 'Others'
	END as group_channel,
	CASE
		WHEN channel_id in ('WEB','WPS','GSW') THEN 'Untracked WEB'
		WHEN channel_id in ('WAP','APS','GSA') THEN 'Untracked WAP'
		WHEN channel_id = 'GSF' THEN 'GSF'
		WHEN channel_id = 'GSL' THEN 'GSL'
		WHEN channel_id = 'TEL' THEN 'TEL'
		WHEN channel_id = 'TRO' THEN 'TRO'
		WHEN channel_id = 'DEM' THEN 'DEM'
		WHEN channel_id = 'AMA' THEN 'AMA'
		WHEN channel_id = 'MKT' THEN 'MKT'
		WHEN channel_id = 'MKP' THEN 'MKP'
		ELSE 'Others'
	END as campaign,
	0 as itemquantity,
	CASE
		WHEN channel_id in ('WEB','WPS','GSW') THEN 'Untracked WEB'
		WHEN channel_id in ('WAP','APS','GSA') THEN 'Untracked WAP'
		WHEN channel_id = 'GSF' THEN 'GSF'
		WHEN channel_id = 'GSL' THEN 'GSL'
		WHEN channel_id = 'TEL' THEN 'TEL'
		WHEN channel_id = 'TRO' THEN 'TRO'
		WHEN channel_id = 'DEM' THEN 'DEM'
		WHEN channel_id = 'AMA' THEN 'AMA'
		WHEN channel_id = 'MKT' THEN 'MKT'
		WHEN channel_id = 'MKP' THEN 'MKP'
		ELSE 'Others'
	END as medium,
	CASE
		WHEN channel_id in ('WEB','WPS','GSW') THEN 'Untracked WEB'
		WHEN channel_id in ('WAP','APS','GSA') THEN 'Untracked WAP'
		WHEN channel_id = 'GSF' THEN 'GSF'
		WHEN channel_id = 'GSL' THEN 'GSL'
		WHEN channel_id = 'TEL' THEN 'TEL'
		WHEN channel_id = 'TRO' THEN 'TRO'
		WHEN channel_id = 'DEM' THEN 'DEM'
		WHEN channel_id = 'AMA' THEN 'AMA'
		WHEN channel_id = 'MKT' THEN 'MKT'
		WHEN channel_id = 'MKP' THEN 'MKP'
		ELSE 'Others'
	END as source,
	untracked_orders.order_number as transactionid,
	0 as transactionrevenue,
	0 as transactionshipping,
	'N/A' as keyword,
	'N/A' as landingpagepath,
	current_timestamp as update_ts
from untracked_orders;


insert into spend_tracking.sessions (date, session_source, traffic_type, group_channel, medium, source, campaign, update_ts)
select 
	date,
	'Manual' as session_source,
	traffic_type,
	group_channel,
	medium,
	source,
	campaign,
	current_timestamp
from
	manual_data_sources.ga_transactions
where
	traffic_type='Untracked'
	and date >= '2016-01-01'
group by
	1,2,3,4,5,6,7,8;

---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
--#99 - Permissions
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

--create schema spend_tracking;
grant usage on schema spend_tracking to looker, group bidev; 
grant select on all tables in schema spend_tracking to looker, group bidev; 
