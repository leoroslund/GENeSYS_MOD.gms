* ############### Notes ###############

* y = YEAR_FULL
* l = TIMESLICE_FULL
* f = FUEL
* r = REGION_FULL
* exr = EXOGENOUS_REGION_FULL

* ############### ############### ###############
* ############### New sets ###############

set EXOGENOUS_REGION_FULL All exogenous regions included in the input data but should not be modelled as regions;
alias (EXOGENOUS_REGION_FULL,exr_full);

set EXOGENOUS_REGION(EXOGENOUS_REGION_FULL) Subset of exogenous regions for which computation should actually happen;
alias (EXOGENOUS_REGION,exr)

* ############### ############### ###############
* ############### New parameters ###############

parameter ExogenousDemand(TIMESLICE_FULL,FUEL,EXOGENOUS_REGION_FULL) The total value of export of model regions to exogenous region; 
parameter ExogenousProduction(TIMESLICE_FULL,FUEL,EXOGENOUS_REGION_FULL) The total value of import of model regions from exogenous region;

parameter ExogenousTradeRoute(FUEL,REGION_FULL,EXOGENOUS_REGION_FULL) The length of possible trade routes between model regions and exogenous regions;

Parameter ModelledExogenousTradeCapacity(YEAR_FULL,FUEL,EXOGENOUS_REGION_FULL) The trade capacity between model regions and exogenous regions the supermodel provided for the submodel;
Parameter ResidualExogenousTradeCapacity(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL) The trade capacity that already existed between model regions and exogenous regions for the bas year before supermodel run;
Parameter CommissionedExogenousTradeCapacity(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL) The trade capacity between model regions and exogenous regions which has in reality been commissioned which the model does not need to account cost for;

Parameter GrowthRateExogenousTradeCapacity(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL) The growth rate factor for the exogenous trade capacity;
parameter ExogenousTradeCapacityGrowthCosts(FUEL,REGION_FULL,EXOGENOUS_REGION_FULL) Cost of increasing trade capacity between model regions and exogenous regions; 

parameter ExogenousTradeCosts(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL) Cost for trading fuels without trade capacity to exogenous regions;


* ############### ############### ###############
* ############### New variables ###############

positive variable ExogenousExport(TIMESLICE_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL) The export a modelled region does to a region outside system boundaries;
positive variable ExogenousImport(TIMESLICE_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL) The import a modelled region does to a region outside system boundaries;

Positive Variable TotalExogenousTradeCapacity(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL) The total trade capacity existing between model regions and exogenous regions;
Positive Variable NewExogenousTradeCapacity(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL) The new trade capacity between model regions and exogenous regions;

free variable ExogenousNetTrade(YEAR_FULL,TIMESLICE_FULL,FUEL,REGION_FULL);
free variable ExogenousNetTradeAnnual(YEAR_FULL,FUEL,REGION_FULL);

positive variable NewExogenousTradeCapacityCosts(YEAR_FULL, FUEL, REGION_FULL, EXOGENOUS_REGION_FULL) The cost of building new trade capacity to exogenous regions;
positive variable DiscountedNewExogenousTradeCapacityCosts(YEAR_FULL, FUEL, REGION_FULL, EXOGENOUS_REGION_FULL) Discounted cost for building trade capacity;

free variable AnnualTotalExogenousTradeCosts(YEAR_FULL,REGION_FULL) Annual cost of trading fuels without trade capacity;
free variable DiscountedAnnualTotalExogenousTradeCosts(YEAR_FULL,REGION_FULL) Discounted annual cost of trade with exogenous regions;

* ############### ############### ###############
* ############### New other things... ###############

ExogenousTradeLossBetweenRegions(y,f,r,exr) = TradeLossFactor(f,y)*ExogenousTradeRoute(f,r,exr);

* ############### ############### ###############
* ############### New constraints ###############

* # Trade flow
* Forcing the model to trade to the exogenous regions, the trade should in total be exactly as the supermodel run
equation ET1e_ForceExogenousExport(TIMESLICE_FULL,FUEL,EXOGENOUS_REGION_FULL);
ET1_ForceExogenousExport(l,f,exr)$(ExogenousDemand(l,f,exr) > 0).. sum(r$(ExogenousTradeRoute(f,r,exr)),ExogenousExport(l,f,r,exr)) =e= ExogenousDemand(l,f,exr);
ExogenousExport.fx(l,f,r,exr)$(not ExogenousTradeRoute(f,r,exr)) = 0;
ExogenousExport.fx(l,f,r,exr)$(ExogenousDemand(l,f,exr) = 0) = 0;
equation ET1i_ForceExogenousImport(TIMESLICE_FULL,FUEL,EXOGENOUS_REGION_FULL);
ET1_ForceExogenousImport(l,f,exr)$(ExogenousProduction(l,f,exr) > 0).. sum(r$(ExogenousTradeRoute(f,r,exr)),ExogenousImport(l,f,r,exr)) =e= ExogenousProduction(l,f,exr);
ExogenousImport.fx(l,f,r,exr)$(not ExogenousTradeRoute(f,r,exr)) = 0;
ExogenousImport.fx(l,f,r,exr)$(ExogenousProduction(l,f,exr) = 0) = 0;

* # Trade capacity
* Forcing the model to build a total trade capacity with exogenous regions, the capacity should in total be exactly as the supermodel run
Equation ET2_ForceExogenousTradeCapacity(YEAR_FULL,FUEL,EXOGENOUS_REGION_FULL);
ET2_ForceExogenousTradeCapacity(y,f,exr)$(TagCanFuelBeTraded(f) and ModelledExogenousTradeCapacity(y,f,exr) > 0).. sum(r$(ExogenousTradeRoute(f,r,exr)),TotalExogenousTradeCapacity(y,f,r,exr)) =e= ModelledExogenousTradeCapacity(y,f,exr);
TotalExogenousTradeCapacity.fx(y,f,r,exr)$(not ExogenousTradeRoute(f,r,exr)) = 0;
TotalExogenousTradeCapacity.fx(y,f,r,exr)$(ModelledExogenousTradeCapacity(y,f,exr) = 0) = 0;

* Ensuring that enough new trade capacity is built in relation to the desired total capacity across model regions
equation ET3a_TotalExogenousTradeCapacityStartYear(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET2a_CommissionedExogenousTradeCapacityStartYear(y,f,r,exr)$(ExogenousTradeRoute(f,r,exr) and TagCanFuelBeTraded(f) and YearVal(y) = %year%).. TotalExogenousTradeCapacity(y,f,r,exr) =e= ResidualExogenousTradeCapacity(y,f,r,exr);
equation ET3b_TotalExogenousTradeCapacity(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET2b_CommissionedExogenousTradeCapacity$(ExogenousTradeRoute(f,r,exr) and TagCanFuelBeTraded(f) and YearVal(y) > %year%).. TotalExogenousTradeCapacity(y,f,r,exr) =e= TotalExogenousTradeCapacity(y-1,f,r,exr) + NewExogenousTradeCapacity(y,f,r,exr) + CommissionedExogenousTradeCapacity(y,f,r,exr);

* Limit growth rate of trade capacity
Equation ET4a_NewExogenousTradeCapacityLimitPower(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET4a_NewExogenousTradeCapacityLimitPower(y,'Power',r,exr)$(ExogenousTradeRoute('Power',r,exr) > 0 and GrowthRateExogenousTradeCapacity(y,'Power',r,exr) > 0 and YearVal(y) > %year%).. GrowthRateExogenousTradeCapacity(y,'Power',r,exr)*YearlyDifferenceMultiplier(y)*TotalExogenousTradeCapacity(y-1,'Power',r,exr) =g= NewExogenousTradeCapacity(y,'Power',r,exr);
Equation ET4b_NewExogenousTradeCapacityLimitNatGas(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET4b_NewExogenousTradeCapacityLimitNatGas(y,'Gas_Natural',r,exr)$(ExogenousTradeRoute('Gas_Natural',r,exr) and GrowthRateExogenousTradeCapacity(y,'Gas_Natural',r,exr)).. 100$(not ResidualExogenousTradeCapacity(y,'Gas_Natural',r,exr)) + (GrowthRateExogenousTradeCapacity(y,'Gas_Natural',r,exr)*YearlyDifferenceMultiplier(y))*TotalExogenousTradeCapacity(y-1,'Gas_Natural',r,exr) =g= NewExogenousTradeCapacity(y,'Gas_Natural',r,exr);
Equation ET4c_NewExogenousTradeCapacityLimitH2(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET4c_NewExogenousTradeCapacityLimitH2(y,'H2',r,exr)$(ExogenousTradeRoute('H2',r,exr) and GrowthRateExogenousTradeCapacity(y,'H2',r,exr)).. 50$(not ResidualExogenousTradeCapacity(y,'H2',r,exr))+(GrowthRateExogenousTradeCapacity(y,'H2',r,exr)*YearlyDifferenceMultiplier(y))*TotalExogenousTradeCapacity(y-1,'H2',r,exr) =g= NewExogenousTradeCapacity(y,'H2',r,exr);

* Setting remaining new exogenous trade capacity to zero
NewExogenousTradeCapacity.fx(y,f,r,exr)$(ExogenousTradeRoute(f,r,exr) = 0 or GrowthRateExogenousTradeCapacity(y,f,r,exr) = 0) = 0;

* # Trade flow limits
* Power
equation ET5a_ExogenousTradeCapacityPowerLinesImport(YEAR_FULL,TIMESLICE_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET5a_ExogenousTradeCapacityPowerLinesImport(y,l,'Power',r,exr)$(ExogenousTradeRoute('Power',r,exr) > 0).. (ExogenousImport(l,'Power',r,exr)) =l= TotalExogenousTradeCapacity(y,'Power',r,exr)*YearSplit(l,y)*31.536;
equation ET5b_ExogenousTradeCapacityPowerLinesExport(YEAR_FULL,TIMESLICE_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET5b_ExogenousTradeCapacityPowerLinesExport(y,l,'Power',r,exr)$(ExogenousTradeRoute('Power',r,exr) > 0).. (ExogenousExport(l,'Power',r,exr)) =l= TotalExogenousTradeCapacity(y,'Power',r,exr)*YearSplit(l,y)*31.536;

* H2
equation ET6a_ExogenousTradeCapacityPipelinesLinesImport(YEAR_FULL,TIMESLICE_FULL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET6a_ExogenousTradeCapacityPipelinesLines(y,l,r,exr).. ExogenousImport(l,'H2',r,exr) =l= TotalExogenousTradeCapacity(y,'H2',r,exr)*YearSplit(l,y);
equation ET6b_ExogenousTradeCapacityPipelinesLinesExport(YEAR_FULL,TIMESLICE_FULL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET6b_ExogenousTradeCapacityPipelinesLinesExport(y,l,r,exr).. ExogenousExport(l,'H2',r,exr) =l= TotalExogenousTradeCapacity(y,'H2',r,exr)*YearSplit(l,y);

* LH2 Trucks
equation ET9a_ExogenousTradeCapacityTrucksImport(YEAR_FULL,TIMESLICE_FULL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET9a_ExogenousTradeCapacityTrucksImport(y,l,r,exr).. ExogenousImport(l,'LH2',r,exr) =l= TotalExogenousTradeCapacity(y,'LH2',r,exr)*YearSplit(l,y);
equation ET9b_ExogenousTradeCapacityTrucksExport(YEAR_FULL,TIMESLICE_FULL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET9b_ExogenousTradeCapacityTrucksExport(y,l,r,exr).. ExogenousExport(l,'LH2',r,exr) =l= TotalExogenousTradeCapacity(y,'LH2',r,exr)*YearSplit(l,y);

* Other
equation ET8a_ExogenousTradeCapacityLimitNonPowerImport(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET8a_ExogenousTradeCapacityLimitNonPowerImport(y,f,r,exr)$(ExogenousTradeCapacityGrowthCosts(f,r,exr) and not sameas(f,'Power')).. sum(l,ExogenousImport(l,f,r,exr)) =l= TotalExogenousTradeCapacity(y,f,r,exr);
equation ET8b_ExogenousTradeCapacityLimitNonPowerExport(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET8b_ExogenousTradeCapacityLimitNonPowerExport(y,f,r,exr)$(ExogenousTradeCapacityGrowthCosts(f,r,exr) and not sameas(f,'Power')).. sum(l,ExogenousExport(l,f,r,exr)) =l= TotalExogenousTradeCapacity(y,f,r,exr);

* # Other trade balance
equation ET9_ExogenousNetTradeBalance(YEAR_FULL,TIMESLICE_FULL,FUEL,REGION_FULL);
ET9_ExogenousNetTradeBalance(y,l,f,r)$(sum(exr,ExogenousTradeRoute(f,r,exr)) and TagCanFuelBeTraded(f)).. sum(exr$(ExogenousTradeRoute(f,r,exr)), ExogenousExport(l,f,r,exr)*(1+ExogenousTradeLossBetweenRegions(y,f,r,exr)) - ExogenousImport(y,l,f,r,rr)) =e= ExogenousNetTrade(y,l,f,r);

equation ET10_AnnualExogenousNetTradeBalance(YEAR_FULL,FUEL,REGION_FULL);
ET10_AnnualExogenousNetTradeBalance(y,f,r)$(sum(exr,ExogenousTradeRoute(f,r,exr)) and TagCanFuelBeTraded(f)).. sum(l, (ExogenousNetTrade(y,l,f,r))) =e= ExogenousNetTradeAnnual(y,f,r);
ExogenousNetTradeAnnual.fx(y,f,r)$(sum(exr,ExogenousTradeRoute(f,r,exr)) = 0 or TagCanFuelBeTraded(f) = 0) = 0;

* # Trade costs
* Capacity costs
equation ET11_NewExogenousTradeCapacityCosts(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET11_NewExogenousTradeCapacityCosts(y,f,r,exr)$(ExogenousTradeRoute(f,r,exr) and ExogenousTradeCapacityGrowthCosts(f,r,exr))..  NewExogenousTradeCapacity(y,f,r,exr)*ExogenousTradeCapacityGrowthCosts(f,r,exr)*ExogenousTradeRoute(f,r,exr) =e= NewExogenousTradeCapacityCosts(y,f,r,exr);
equation ET12_DiscountedNewExogenousTradeCapacityCosts(YEAR_FULL,FUEL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET12_DiscountedNewExogenousTradeCapacityCosts(y,f,r,exr)$(ExogenousTradeRoute(f,r,exr) and ExogenousTradeCapacityGrowthCosts(f,r,exr)).. NewExogenousTradeCapacityCosts(y,f,r,exr)/((1+GeneralDiscountRate(r))**(YearVal(y)-smin(yy, YearVal(yy))+0.5)) =e= DiscountedNewExogenousTradeCapacityCosts(y,f,r,exr);
DiscountedNewExogenousTradeCapacityCosts.fx(y,f,r,exr)$(ExogenousTradeRoute(f,r,exr) = 0 or not ExogenousTradeCapacityGrowthCosts(f,r,exr)) = 0;

* Trade flow costs
equation ET13_AnnualExogenousTradeCosts(YEAR_FULL,REGION_FULL);
ET13_AnnualExogenousTradeCosts(y,r)$(sum((f,exr),ExogenousTradeRoute(f,r,exr))).. sum((l,f,exr)$(ExogenousTradeRoute(f,r,exr)),ExogenousImport(l,f,r,exr) * ExogenousTradeCosts(y,f,r,exr)) + sum((l,f,exr)$(ExogenousTradeRoute(f,r,exr)),ExogenousExport(l,f,r,exr) * ExogenousTradeCosts(y,f,r,exr)) =e= AnnualTotalExogenousTradeCosts(y,r);
AnnualTotalExogenousTradeCosts.fx(y,r)$(sum((f,exr),ExogenousTradeRoute(f,r,exr)) = 0) = 0;
equation ET14_DiscountedAnnualExogenousTradeCosts(YEAR_FULL,REGION_FULL);
ET14_DiscountedAnnualExogenousTradeCosts(y,r)..  AnnualTotalExogenousTradeCosts(y,r)/((1+GeneralDiscountRate(r))**(YearVal(y)-smin(yy, YearVal(yy))+0.5)) =e= DiscountedAnnualTotalExogenousTradeCosts(y,r);

* # Pipeline-specific Capacity Accounting
$ifthen.equ_hydrogen_tradecapacity %switch_hydrogen_blending_share% == 0

equation ET15aa_ExogenousTradeCapacityPipelineAccountingImport(YEAR_FULL,TIMESLICE_FULL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET15aa_ExogenousTradeCapacityPipelineAccountingImport(y,l,r,exr).. sum(f$(not sameas(f,'H2_blend') and TagFuelToSubsets(f,'GasFuels')), ExogenousImport(l,f,r,exr)) =l= TotalExogenousTradeCapacity(y,'Gas_Natural',r,exr)*YearSplit(l,y);
equation ET15ab_ExogenousTradeCapacityPipelineAccountingExport(YEAR_FULL,TIMESLICE_FULL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET15ab_ExogenousTradeCapacityPipelineAccountingExport(y,l,r,exr).. sum(f$(not sameas(f,'H2_blend') and TagFuelToSubsets(f,'GasFuels')), ExogenousExport(l,f,r,exr)) =l= TotalExogenousTradeCapacity(y,'Gas_Natural',r,exr)*YearSplit(l,y);

$else.equ_hydrogen_tradecapacity

equation ET15ba_ExogenousTradeCapacityPipelineAccountingGasFuelsImport(YEAR_FULL,TIMESLICE_FULL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET15ba_ExogenousTradeCapacityPipelineAccountingGasFuelsImport(y,l,r,exr)$(%switch_hydrogen_blending_share%>0 and %switch_hydrogen_blending_share%<1).. sum(f$(not sameas(f,'H2_blend') and TagFuelToSubsets(f,'GasFuels')), ExogenousImport(l,f,r,exr)) + ExogenousImport(l,'H2_blend',r,exr)*(11.4/3.0) =l= TotalExogenousTradeCapacity(y,'gas_natural',r,exr)*YearSplit(l,y);
equation ET15bb_ExogenousTradeCapacityPipelineAccountingGasFuelsExport(YEAR_FULL,TIMESLICE_FULL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET15bb_ExogenousTradeCapacityPipelineAccountingGasFuelsExport(y,l,r,exr)$(%switch_hydrogen_blending_share%>0 and %switch_hydrogen_blending_share%<1).. sum(f$(not sameas(f,'H2_blend') and TagFuelToSubsets(f,'GasFuels')), ExogenousExport(l,f,r,exr)) + ExogenousExport(l,'H2_blend',r,exr)*(11.4/3.0) =l= TotalExogenousTradeCapacity(y,'gas_natural',r,exr)*YearSplit(l,y);

equation ET15ca_ExogenousTradeCapacityPipelineAccountingH2BlendImport(YEAR_FULL,TIMESLICE_FULL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET15ca_ExogenousTradeCapacityPipelineAccountingH2BlendImport(y,l,r,exr)$(%switch_hydrogen_blending_share%>0 and %switch_hydrogen_blending_share%<1).. ExogenousImport(l,'H2_blend',r,exr) =l= (%switch_hydrogen_blending_share%/((1-%switch_hydrogen_blending_share%)*(11.4/3.0))) * sum(f$(not sameas(f,'H2_blend') and TagFuelToSubsets(f,'GasFuels')), ExogenousImport(l,f,r,exr));
equation ET15cb_ExogenousTradeCapacityPipelineAccountingH2BlendExport(YEAR_FULL,TIMESLICE_FULL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET15cb_ExogenousTradeCapacityPipelineAccountingH2BlendExport(y,l,r,exr)$(%switch_hydrogen_blending_share%>0 and %switch_hydrogen_blending_share%<1).. ExogenousExport(l,'H2_blend',r,exr) =l= (%switch_hydrogen_blending_share%/((1-%switch_hydrogen_blending_share%)*(11.4/3.0))) * sum(f$(not sameas(f,'H2_blend') and TagFuelToSubsets(f,'GasFuels')), ExogenousExport(l,f,r,exr));

equation ET15da_ExogenousTradeCapacityPipelineAccountingCombinedImport(YEAR_FULL,TIMESLICE_FULL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET15da_ExogenousTradeCapacityPipelineAccountingCombinedImport(y,l,r,exr)$(%switch_hydrogen_blending_share% = 1).. sum(f$(not sameas(f,'H2_blend') and TagFuelToSubsets(f,'GasFuels')), ExogenousImport(l,f,r,exr)) + ExogenousImport(l,'H2_blend',r,exr)*(11.4/3.0) =l= TotalExogenousTradeCapacity(y,'Gas_Natural',r,exr)*YearSplit(l,y);
equation ET15db_ExogenousTradeCapacityPipelineAccountingCombinedExport(YEAR_FULL,TIMESLICE_FULL,REGION_FULL,EXOGENOUS_REGION_FULL);
ET15db_ExogenousTradeCapacityPipelineAccountingCombinedExport(y,l,r,exr)$(%switch_hydrogen_blending_share% = 1).. sum(f$(not sameas(f,'H2_blend') and TagFuelToSubsets(f,'GasFuels')), ExogenousExport(l,f,r,exr)) + ExogenousExport(l,'H2_blend',r,exr)*(11.4/3.0) =l= TotalExogenousTradeCapacity(y,'Gas_Natural',r,exr)*YearSplit(l,y);

$endif.equ_hydrogen_tradecapacity

* ############### ############### ###############
* ############### Edited functions ###############

* # Energy balance
equation EB2_EnergyBalanceEachTS(YEAR_FULL,TIMESLICE_FULL,FUEL,REGION_FULL);
EB2_EnergyBalanceEachTS(y,l,f,r)$(TagTimeIndependentFuel(y,f,r) = 0).. sum((t,m)$(OutputActivityRatio(r,t,f,m,y) <> 0), RateOfActivity(y,l,t,m,r)*OutputActivityRatio(r,t,f,m,y))*YearSplit(l,y) =e= Demand(y,l,f,r) + sum((t,m)$(InputActivityRatio(r,t,f,m,y) <> 0), RateOfActivity(y,l,t,m,r)*InputActivityRatio(r,t,f,m,y)*TimeDepEfficiency(r,t,l,y))*YearSplit(l,y) + NetTrade(y,l,f,r) + ExogenousNetTrade(y,l,f,r);

* # Objective Function
equation cost;
cost.. z =e= sum((y,r), TotalDiscountedCost(y,r))
+ sum((y,r), DiscountedAnnualTotalTradeCosts(y,r))
+ sum((y,f,r,rr), DiscountedNewTradeCapacityCosts(y,f,r,rr))
+ sum((y,f,r), DiscountedAnnualCurtailmentCost(y,f,r))
+ sum((y,r,f,t),BaseYearBounds_TooHigh(y,r,t,f)*9999)
+ sum((y,r,f,t),BaseYearBounds_TooLow(y,r,t,f)*9999)
+ sum((r,y),heatingslack(y,r)*9999)
- sum((y,r),DiscountedSalvageValueTransmission(y,r))
+ sum((y,r), DiscountedAnnualTotalExogenousTradeCosts(y,r))
+ sum((y,f,r,exr), DiscountedNewExogenousTradeCapacityCosts(y,f,r,exr))
;

