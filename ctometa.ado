*! version 1.0.4  7aug2020 Aaron Wolf, aaron.wolf@u.northwestern.edu
cap program drop ctometa
program define ctometa, rclass

	version 15
	
	syntax using [, Keep(namelist) noPreserve noVALlabels noVARlabels]
	
	if "`preserve'" != "nopreserve"  preserve
qui {	

//	List of variables in the current dataset
	qui ds
	local indf `r(varlist)'

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
	
*===============================================================================*
*																				*
*		SECTION 1: 	Main survey questions										*
*																				*
*===============================================================================*
	
	
	* Keep type, name and specified variables. Keep all by default.
	if "`keep'" != "" keep type name `keep'
	else {
	    ds label*
		local labels `r(varlist)'
		gettoken label: labels
		
		ds hint*
		local hints `r(varlist)'
		gettoken hint: hints
		
	    keep type name `label' `hint'
	}
	
//	Isolate label variable
	* Ensure only one label was selected
	ds label*
	local language = subinstr("`r(varlist)'","label","",.)
	if wordcount("`r(varlist)'") > 1 {
		di as error "You must keep only one label language"
		exit 198			
	}
	rename label label
	
	cap ds hint*
	if _rc ==0 & wordcount("`r(varlist)'") > 1 {
		di as error "You must keep only one hint language"
		exit 198			
	}
	cap rename hint hint	
	
	
	* Preserve sort order
	gen sort = _n
	
	* Trim all variables to ensure extra spaces don't cause errors
	qui ds, has(type string)
	foreach var of varlist `r(varlist)' {
		replace `var' = strtrim(stritrim(`var'))
	}
	
	
	* Remove begin/end group/repeat, and notes
	drop if inlist(type,"begin group","begin repeat","end group","end repeat","note")
	
	* Keep only variables in the current dataset
	levelsof name, local(current)
	local insheet: list current & indf
	gen keepname = 0
	foreach name of local insheet {
		replace keepname = 1 if name == "`name'"
	}
	keep if keepname == 1
	drop keepname
	
	qui count
	if `r(N)' > 0 {
	
		* Get list of variables to write to metadata
		ds type name sort label, not
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
		
		* Ensure list has proper Stata names
		replace list = subinstr(list,"-","_",.)
		
		* Create new extended list variable for each list
		levelsof list, local(lists)
		foreach list of local lists {
			cap confirm name `list'
			if _rc {
				di as error "`list' is not a valid Stata name."
				confirm name `list'
			}
			else gen list_`list' = "1" if list == "`list'"
		}
//		Adjust metadata for selected() relevance criteria
		* Count number of "selected(" expressions
		* Count number of "selected(" expressions
		replace relevance = subinstr(stritrim(relevance),", ",",",.)
		replace relevance = subinstr(relevance," )",")",.)
		replace relevance = subinstr(relevance,"'","",.)
		gen count = (strlen(relevance)-strlen(subinstr(relevance,"selected","",.)))/strlen("selected")	
		sum count
		
		
		* Loop over all possible selected expressions and replace with expression for split variable equivalent
		forvalues i = 1/`r(max)' {
			gen exp`i' = regexs(0) if 		regexm(relevance,"selected\(\\$\{[A-Za-z0-9_]+\},([']?[-]?[0-9]+[']?)\)")
			gen part1_`i' = regexs(1) if 	regexm(relevance,"(selected\(\\$\{)([A-Za-z0-9_]+)(\},)([']?[-]?[0-9]+[']?)(\))")
			gen part2_`i' = regexs(2) if 	regexm(relevance,"(selected\(\\$\{)([A-Za-z0-9_]+)(\},)([']?[-]?[0-9]+[']?)(\))")
			gen part3_`i' = regexs(3) if 	regexm(relevance,"(selected\(\\$\{)([A-Za-z0-9_]+)(\},)([']?[-]?[0-9]+[']?)(\))")
			gen part4_`i' = regexs(4) if 	regexm(relevance,"(selected\(\\$\{)([A-Za-z0-9_]+)(\},)([']?[-]?[0-9]+[']?)(\))")
			gen part5_`i' = regexs(5) if 	regexm(relevance,"(selected\(\\$\{)([A-Za-z0-9_]+)(\},)([']?[-]?[0-9]+[']?)(\))")
			gen new`i' = part2_`i' + "_" + subinstr(part4_`i',"-","_",.) + "=1"
			replace relevance = subinstr(relevance,exp`i',new`i',.)
			drop exp`i' part?_`i' new`i'
		}

		
//		Adjust relevance criteria for remaining expressions
		* Remaining relevance cleaning		
		replace relevance = subinstr(relevance,"`=char(10)'"," ",.)
		replace relevance = subinstr(relevance,"}","]",.)
		replace relevance = subinstr(relevance,"\${","[",.)
		replace relevance = subinstr(relevance,"[","",.)
		replace relevance = subinstr(relevance,"]","",.)
		replace relevance = subinstr(relevance,"or","|",.)
		replace relevance = subinstr(relevance,"and","&",.)
		replace relevance = subinstr(relevance,"=","==",.)
		replace relevance = subinstr(relevance,"<==","<=",.)
		replace relevance = subinstr(relevance,">==",">=",.)
		replace relevance = subinstr(relevance,"!==","!=",.)
		replace relevance = subinstr(relevance,"not","!",.)
		
		
		* Save survey metadata
		tempfile svymeta
		save `svymeta'		
		
		* Write a temporary .do file with a line creating a characteristic for each variable
		cap file close metadata
		tempfile metadata
		
		* Check that the file does not exist. Delete if it does
		cap confirm file `metadata'
		if _rc == 0 erase `metadata'
		
		file open metadata using `metadata', write
		sort sort
		drop sort
		qui count
		local n = `r(N)'
		foreach x of varlist type list label `vlist' type_* list_* name {
			cap confirm string variable `x'
			if _rc {
				tostring `x', replace
				replace `x' = "" if `x' == "."
			}
			replace `x' = subinstr(subinstr(subinstr(`x',"\${","[",.),"}","]",.),"`=char(10)'"," ",.)
			replace `x' = "cap char " + name + "[CTO_`x'] " + `x' if !missing(`x')
			forvalues i = 1/`n' {
				file write metadata (`x'[`i']) _n
			}
		}
		
		
	*===============================================================================*
	*																				*
	*		SECTION 2: 	Select Multiple split questions								*
	*																				*
	*===============================================================================*
		
		
		* Isolate list of select_multiple variable to use relevant choices list
		use `svymeta', clear
		
		* Isolate select_multiple variables
		keep if type == "select_multiple"
		keep type list name relevance
		rename list list
		levelsof list, local(choicelists)
		
		tempfile multiple
		save `multiple'

	//	Choices - Define Variable Labels
		* Load choices
		import excel `using', sheet(choices) firstrow clear
		rename list_name list
		keep list value label`language'
		rename label label
		
		* Ensure only one label was selected
		ds label*
		local language = subinstr("`r(varlist)'","label","",.)
		if wordcount("`r(varlist)'") > 1 {
			di as error "You must keep only one label language"
			exit 198			
		}
		rename label label

		
		* Trim all variables to ensure extra spaces don't cause errors
		qui ds, has(type string)
		foreach var of varlist `r(varlist)' {
			replace `var' = strtrim(stritrim(`var'))
		}
		
		tempfile choices
		save `choices'
		
		* Ensure list has proper Stata names
		replace list = subinstr(list,"-","_",.)

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
		
		* Create vallabel variable
		cap tostring value, replace
		gen vallabel = "cap label define " + list + " " + value + " " + `"""' + label + `"""' + ", modify"
		replace vallabel = subinstr(subinstr(subinstr(vallabel,"\${","[",.),"}","]",.),"`=char(10)'"," ",.)
		
		* Write to file
		qui count
		forvalues i = 1/`r(N)' {
			file write metadata (vallabel[`i']) _n
		}
		
	//	Choices - select_multiple metadata
		use `choices', clear
		
		* Keep only lists used by survey
		gen keeplist = 0
		foreach list of local choicelists {
			replace keeplist = 1 if list == "`list'"		
		}
		
		keep if keeplist == 1
		drop keeplist
		
		qui count
		if `r(N)' > 0 {
		
			* Join by list_name
			joinby list using `multiple'
			order type name list value label
			sort name list value label
			cap confirm numeric variable value
				if !_rc gen variable = subinstr(name + "_" + string(value),"-","_",.)
				else gen variable = subinstr(name + "_" + value,"-","_",.)
				
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
		}
		
		file close metadata


		
		if "`preserve'" != "nopreserve" restore
		else use `svymeta', clear
		*/
		* Run metadata .do file
		qui do `metadata'
		
	*===============================================================================*
	*																				*
	*		SECTION 3: 	Attach CTO_list value labels to each select_one variable	*
	*																				*
	*===============================================================================*
		
		if "`vallabels'" != "novallabels" {
			qui ds, has(char CTO_type_select_one)
			if "`r(varlist)'" != "" {
				foreach var of varlist `r(varlist)' {
					cap destring `var', replace
					la val `var' ``var'[CTO_list]'
				}
			}
		}
		
		if "`varlabels'" != "novarlabels" {
			qui ds, has(char CTO_label)
			if "`r(varlist)'" != "" {
				foreach var of varlist `r(varlist)' {
					la var `var' `"``var'[CTO_label]'"'
				}
			}
		}
		
	}
}
	* Return local macros with types and lists used	
	return local types 		`"`types'"'
	return local lists 		`"`lists'"'

end
