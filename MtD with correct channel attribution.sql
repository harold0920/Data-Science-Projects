with opps_leads as (
  select distinct opportunity_id, cast(filter(webparameters, x -> x['key'] == "timestamp")[0]['value'] as timestamp) as ingena_timestamp from contact360_prod.silver.opps_leads
)
select
  ref.`Opportunity Reference Number`,
  prop.`Opportunity Sale Type`,
  country.`Country Name`,
  centre.`Centre City`,
  channel.`Channel Group`,
  channel.Channel,
  custom.`Source Major`,
  custom.`Source Minor`,
  custom.`Source Detail`,
  campaign.`Campaign Name`,
  custom.`Search Term` as `Term`,
  platform.`Platform Name`,
  to_date(fact.`Opportunity Created Local Date Key`, 'yyyyMMdd') as `Opportunity Created Date`,
  to_date(fact.`Opportunity First Tour Completed Date Key`, 'yyyyMMdd') as `First Tour Completed Date`,
  to_date(fact.`Opportunity Sale Confirmed Date Key`, 'yyyyMMdd') as `Sale Confirmed Date`,
  custom.`Contact Type`,
  custom.`Website Brand`,
  product.`Product Group Name`,
  opps_leads.ingena_timestamp as `Ingena Timestamp`,
  custom.`Device Group`,
  case
    when contact.`Contact is Broker` = "Yes" then account.`Account Name`
    else null
  end as `Broker Name`,
  custom.`Invalid Enquiry`,
  prop.`Opportunity Lost Reason Name`,
  
  -- Cleaned Channel column (applying both clean_channels and map_classified_portals logic)
  case
    -- map_classified_portals: Property Portals + keyword match → Classified
    when lower(channel.Channel) = 'property portals' 
      and custom.`Source Detail` rlike '(?i)(ouedkniss|kleinanzeigen|willhaben|dubizzle|opensooq|bikroy|2dehands|dnls|chavesnamao|olx|bruneida|globalfreeclassifiedads|alo bg|bazar|kijiji|yelp|mercadolibre|58 CN|58\\.com|dianping\\.com|encuentra24|casas24|njuskalo|bazaraki|dba|guloggratis|okidoki|oikotie|leboncoin|paruvendu|quoka|carousell|jofogas|donedeal|property\\.ie|bakeca|trovit|pigiame|ss lv|mudah|avito|marktplaats|trademe|finn|rubrik|mitula|gratka|qatar living|2gis|4zida|halo oglasi|bolha|oglasi|ananzi|findmy|milanuncios|comparis|petites annonces|proxity|tayara|sahibinden)'
      then 'Classified'
    
    -- map_classified_portals: Craigs List → Classified
    when lower(channel.Channel) = 'craigs list' then 'Classified'
    
    -- clean_channels: Online Affiliate override (Campaign Name contains "BETTERBUSINESS")
    when lower(campaign.`Campaign Name`) like '%betterbusiness%' then 'Online Affiliate'
    
    -- clean_channels: Broker rule (Zapier Meta)
    when lower(account.`Account Name`) = 'zapier meta' then 'Paid Social'
    
    -- clean_channels: Global Campaign rule
    when lower(campaign.`Campaign Name`) in (
      'gb > en > of > sm > bl > ms > pmax_t_',
      'gb > en > of > pm > bl > ms > pmax_t_'
    ) then 'Paid Display'
    
    -- clean_channels: CHINA RULES - Regus/Spaces Lead + Social Media
    when lower(country.`Country Name`) = 'china'
      and lower(custom.`Source Detail`) in ('regus lead', 'spaces lead')
      and lower(custom.`Source Minor`) = 'social media'
      then 'Paid Social'
    
    -- clean_channels: CHINA RULES - Regus/Spaces Lead + Paid Search
    when lower(country.`Country Name`) = 'china'
      and lower(custom.`Source Detail`) in ('regus lead', 'spaces lead')
      and lower(custom.`Source Minor`) = 'paid search'
      then 'Paid Search'
    
    -- clean_channels: CHINA RULES - Paid Search keywords
    when lower(country.`Country Name`) = 'china'
      and lower(custom.`Source Detail`) rlike '(baidu|baibu|pc landing page)'
      then 'Paid Search'
    
    -- clean_channels: CHINA RULES - Paid Social keywords
    when lower(country.`Country Name`) = 'china'
      and lower(custom.`Source Detail`) rlike '(toutiao|wechat|wechat dsp|wechatdsp|little red book|xiaohongshu)'
      then 'Paid Social'
    
    -- clean_channels: CHINA RULES - Paid Display keywords
    when lower(country.`Country Name`) = 'china'
      and lower(custom.`Source Detail`) rlike '(gaode|gaode map)'
      then 'Paid Display'
    
    -- Default: keep original Channel
    else channel.Channel
  end as `Cleaned Channel`,
  
  sum(fact.`KPI Number Of Enquiries`) as Enquiries,
  sum(fact.`KPI Number Of First Tours Completed`) as `Tours Completed`,
  sum(fact.`KPI Number Of Deals`) as Deals,
  sum(fact.`KPI Sales Revenue Report Currency`) as revenue
from
  contact360_prod.gold.fact_sales_funnel fact
inner join
  contact360_prod.gold.dim_centre centre
on fact.`Opportunity Centre Alternative Key` = centre.`Centre Alternative Key`
inner join contact360_prod.gold.dim_country country
on centre.`Country Alternative Key` = country.`Country Alternative Key`
inner join contact360_prod.gold.dim_channel channel on fact.`Opportunity Channel Alternative Key` = channel.`Channel Alternative Key`
inner join contact360_prod.gold.dim_campaign campaign on fact.`Opportunity Campaign Alternative Key` = campaign.`Campaign Alternative Key`
inner join contact360_prod.gold.dim_platform platform on fact.`Opportunity Platform Alternative Key` = platform.`Platform Alternative Key`
inner join contact360_prod.gold.dim_opportunity_custom_property custom on fact.`Opportunity Custom Property Alternative Key` = custom.`Opportunity Custom Property Alternative Key`
inner join contact360_prod.gold.dim_product product on fact.`Opportunity Product Alternative Key` = product.`Product Alternative Key`
inner join contact360_prod.gold.dim_opportunity_reference ref on fact.`Opportunity Reference Alternative Key` = ref.`Opportunity Reference Alternative Key`
inner join contact360_prod.gold.dim_opportunity_property prop on fact.`Opportunity Property Alternative Key` = prop.`Opportunity Property Alternative Key`
inner join contact360_prod.gold.dim_account account on fact.`Opportunity Referred By Account Alternative Key` = account.`Account Alternative Key`
inner join contact360_prod.gold.dim_contact contact on fact.`Opportunity Referred By Contact Alternative Key` = contact.`Contact Alternative Key`
left join opps_leads on ref.`Opportunity ID` = opps_leads.opportunity_id

where custom.`Invalid Enquiry` = "No"
  and country.`Country Name` <> "Japan"
  --and to_date(fact.`Opportunity Created Local Date Key`, 'yyyyMMdd')
      --between '2025-01-01' and '2026-1-31' -- replace this with opportunity date range needed

      
group by all
having sum(fact.`KPI Number Of Enquiries`) > 0
