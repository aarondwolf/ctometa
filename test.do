clear
cap log close

cd "C:\Users\Aaron\Documents\GitHub\ctometa"

*
adopath ++ "C:\Users\Aaron\Documents\GitHub\ctometa"
help ctometa
*/
exit 

cap veracrypt ctometa_data, mount drive(M)


* Setup local macros
local e12 `""M:/01_merged_such_e12.dta""'
local we8 `""M:/01_merged_such_e12_we8.dta""'
local he8 `""M:/01_merged_such_e12_he8.dta""'

	
local survey `""example_xlsform.xlsx""'

* Apply command changes
*qui do ctometa.ado

* Load Data
use `e12'

* Test command
ctometa using `survey', keep(label labelchichewa hint hintchichewa constraint relevance)













