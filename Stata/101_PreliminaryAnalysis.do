/*-------------------------------------------------------------------------------
# Name:		101_PreliminaryAnalysis
# Purpose:	Create preliminary analysis Uganda  
# Author:	Tim Essam, Ph.D.
# Created:	01/12/2015
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/
capture log close
clear
log using "$pathlog/prelimAnalysis", replace

* Load in shock module to look at different shocks faced by hh
use "$pathraw/GSEC16.dta", clear

* List the label for shocks and their cross-walk codes
label list df_SHOCK df_SHOCKRECOVERY

* Tabulate total shocks reported
tab h16q00 if h16q01 == 1

* Calculate total shocks per household
g byte anyshock = (h16q01 ==1)
egen totShock = total(anyshock), by(HHID)
la var anyshock "household reported at least one shock"
la var totShock "total shocks"

* Quickly get a sense of frequency of shocks at HH-level
bys HHID: gen id = _n
tab totShock if id==1, mi

la var totShock "Total shocks"

* Create shock buckets

/*ag 		= other crop damage; input price increase; death of livestock
* aglow		= unusually low prices for ag output
* conflit 	= theft/robbery/violence
* disaster 	= drought, flood, heavy rains, landslides, fire
* drought	= drought/irregular rains
* financial	= loss of non-farm job
* pricedown = price fall of food items
* health	= death of hh member; illness of hh member
* other 	= loss of house; displacement; other
* theft		= theft of money/assets/output/etc.. */ 
g byte ag 		= inlist(h16q00, 104, 105, 106) &  inlist(h16q01, 1) == 1
g byte aglow	= inlist(h16q00, 107) &  inlist(h16q01, 1) == 1
g byte conflict = inlist(h16q00, 116) &  inlist(h16q01, 1) == 1
g byte drought	= inlist(h16q00, 101) &  inlist(h16q01, 1) == 1
g byte disaster = inlist(h16q00, 102, 103, 117) &  inlist(h16q01, 1) == 1
g byte financial= inlist(h16q00, 108, 109) &  inlist(h16q01, 1) == 1
g byte health 	= inlist(h16q00, 110, 111, 112, 113) &  inlist(h16q01, 1) == 1
g byte other 	= inlist(h16q00, 118) &  inlist(h16q01, 1) == 1
g byte theft	= inlist(h16q00, 114, 115) &  inlist(h16q01, 1) == 1

la var ag "Agriculture"
la var aglow "Low ag output prices"
la var conflict "Conflict"
la var disaster "Disaster"
la var financial "Financial"
la var health "Health"
la var other "Other"
la var theft "Theft"
la var drought "lack of rainfall or drought"

* How did households cope?
label list df_SHOCKRECOVERY

/* Coping Mechanisms - What are good v. bad coping strategies? From (Heltberg et al., 2013)
	http://siteresources.worldbank.org/EXTNWDR2013/Resources/8258024-1352909193861/
	8936935-1356011448215/8986901-1380568255405/WDR15_bp_What_are_the_Sources_of_Risk_Oviedo.pdf
	Good Coping:: use of savings, credit, asset sales, additional employment, 
					migration, and assistance
	Bad Coping : increases vulnerabiliy* compromising health and edudcation 
				expenses, productive asset sales, conumsumption reductions 
				*/
				
g byte goodcope = inlist(h16q4a, 1, 2, 4, 5, 6, 7, 8, 9, 10, 12) &  inlist(h16q01, 1) == 1
g byte badcope 	= inlist(h16q4a, 3, 13, 14, 15, 11) &  inlist(h16q01, 1) == 1
g byte incReduction = h16q3a == 1

la var goodcope "Good primary coping strategy"
la var badcope "Bad primary coping strategy"
la var incReduction "Income reduction due to shock"

* Collapse data to househld level and merge back with GIS info
ds (h16* result_code id ), not
keep `r(varlist)'

* Collapse everything down to HH-level using max values for all vars
* Copy variable labels to reapply after collapse
include "$pathdo/copylabels.do"

#delimit ;
	collapse (max) ag aglow conflict drought disaster financial health other theft 
	goodcope badcope incReduction anyshock totShock, by(HHID) fast; 
#delimit cr
	
* Reapply variable lables & value labels
include "$pathdo/attachlabels.do"

