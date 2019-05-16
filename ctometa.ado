cap program drop ctometa
program define ctometa, rclass

	version 15
	
	syntax using [, Keep(namelist) NOPreserve NOVallabels]
	
	if "`preserve'" != "nopreserve" preserve
qui {	
//	Survey
	* Import survey and confirm that keep namelist exists
	import excel `using', sheet("survey") firstrow clear
	
	foreach name in type name `keep' {
		cap confirm variable `name'
			if _rc != 0 {
				di as err `"The field "`name'" does not exist in using XLSForm."'
				exit 198				
			}
	}
	
	* Keep type, name and specified variables. Keep all by default.
	if "`keep'" != "" keep type name `keep'
	else keep _all
	
	* Remove begin/end group/repeat, and notes
	drop if inlist(type,"begin group","begin repeat","end group","end repeat","note")
	
	* Get list of variables to write to metadata
	ds type name, not
	local vlist `r(varlist)'
	
	* Split type to get type and list
	split type, parse(" ") gen(type)
	replace type = type1 if inlist(type1,"select_one","select_multiple")
	gen list = type2 if inlist(type1,"select_one","select_multiple"), after(type)
	replace type = subinstr(type," ","_",.)
	drop type?
	
	* Create new extended type variable for each type
	levelsof type, local(types)
	foreach type of local types {
		gen type_`type' = "1" if type == "`type'"
	}
	
	* Create new extended list variable for each list
	levelsof list, local(lists)
	foreach list of local lists {
		gen list_`list' = "1" if list == "`list'"
	}
	
	* Save survey metadata
	tempfile svymeta
	save `svymeta'		
	
	* Write a temporary .do file with a line creating a characteristic for each variable
	cap file close metadata
	tempfile metadata
	file open metadata using `metadata', write
		
	qui count
	foreach x of varlist type list `vlist' name type_* list_* {
		replace `x' = subinstr(subinstr(subinstr(`x',"\${","[",.),"}","]",.),"`=char(10)'"," ",.)
		replace `x' = "cap char " + name + "[CTO_`x'] " + `x' if !missing(`x')
		forvalues i = 1/`r(N)' {
			file write metadata (`x'[`i']) _n
		}
	}
	
	
	* Isolate list of select_multiple variable to use relevant choices list
	use `svymeta', clear
	
	* Isolate select_multiple variables
	keep if type == "select_multiple"
	keep type list name relevance
	rename list list
	levelsof list, local(choicelists) sep(",")
	
	tempfile multiple
	save `multiple'

//	Choices - Define Variable Labels
	* Load choices
	import excel `using', sheet(choices) firstrow clear
	rename list_name list
	
	tempfile choices
	save `choices'
	
	* Keep only lists that are used by the survey
	gen keeplist = 0
	foreach list of local lists {
		replace keeplist = 1 if list == "`list'"		
	}	
	keep if keeplist == 1
	drop keeplist
	
	* Preserve sort order
	gen sort = _n
	sort list sort
	
	* Select the first "label" variable as the default
	ds label*
	local choicelabels `r(varlist)'
	
	if "`keep'" == "" local labels `choicelabels'
	else local labels: list choicelabels & keep
	
	gettoken default: labels
	
	* Create vallabel variable
	cap tostring value, replace
	gen vallabel = "cap label define " + list + " " + value + " " + `"""' + `default' + `"""' + ", modify"
	replace vallabel = subinstr(subinstr(subinstr(vallabel,"\${","[",.),"}","]",.),"`=char(10)'"," ",.)
	
	* Write to file
	qui count
	forvalues i = 1/`r(N)' {
		file write metadata (vallabel[`i']) _n
	}
	
		
//	Choices - select_multiple metadata
	use `choices', clear
	
	* Keep labels that were specified in keep earlier
	ds label*
	local choicelabels `r(varlist)'
	
	if "`keep'" == "" local labels `choicelabels'
	else local labels: list choicelabels & keep	
	
	keep list value `labels'
	
	* Keep only lists used by survey
	gen keeplist = 0
	foreach list of local choicelists {
		replace keeplist = 1 if list == "`list'"		
	}	
	keep if keeplist == 1
	drop keeplist
	
	* Join by list_name
	joinby list using `multiple'
	order type name list value label
	sort name list value label
	gen variable = subinstr(name + "_" + string(value),"-","_",.)
	
	foreach label of local labels {
		replace `label' = name + "=" + `label'
	}	
	
	* Create label metadata
	replace type = "select_multiple_choice"
	
	* Rename name
	rename name sm_name
	rename variable name
	order name, last
	drop value
	
	* Create new extended type variable for each type
	levelsof type, local(smtypes)
	foreach type of local smtypes {
		gen type_`type' = "1" if type == "`type'"
	}
	
	* Create new extended list variable for each list
	levelsof list, local(smlists)
	foreach list of local smlists {
		gen list_`list' = "1" if list == "`list'"
	}
	
	* Write Metadata
	order name, last
	qui count
	foreach x of varlist _all {
		replace `x' = subinstr(subinstr(subinstr(`x',"\${","[",.),"}","]",.),"`=char(10)'"," ",.)
		replace `x' = "cap char " + name + "[CTO_`x'] " + `x' if !missing(`x')
		forvalues i = 1/`r(N)' {
			file write metadata (`x'[`i']) _n
		}
	}
	
	
	file close metadata
	
	
	





	if "`preserve'" != "nopreserve" restore
	
	* Run metadata .do file
	qui do `metadata'
}
	* Return local macros with types and lists used	
	return local types `"`types'"'
	return local lists `"`lists'"'

end
