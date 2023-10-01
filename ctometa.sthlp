{smcl}
{* 5may2019}{...}
{cmd:help ctometa}
{hline}

{title:Title}

{phang}
{cmd:ctometa} {hline 2} Pull metadata from a SurveyCTO XLSForm and apply it to the current dataset.


{title:Syntax}

	{cmd:ctometa} {cmd:using} {it:{help filename}} [{cmd:,} {opt k:eep(namelist)} {opt nop:reserve} {opt noval:labels} {opt novar:labels}]


{title:Description}

{pstd}
{cmd:ctometa} reads in metadata coded in an Excel document for SurveyCTO
(an {it: XLSForm}) and applys it to the current dataset by applying {help char:characteristics}. This metadata includes variable labels, hints, constraimts, 
relevance expressions, etc. 

{pstd}
For {it: select_one} variables, {cmd: ctometa} creates a new set of value 
labels by pulling from the {it: choices} sheet in the SurveyCTO XLSForm. The 
command does not, by default, assign those value labels to existing variables. 
The option {opt v:arlabels} can be specified to attach the SurveyCTO variable
labels to each variable.

{pstd}
The command also pulls value labels from the {it: choices} sheet and applys the
appropriate labels to pre-split {it: select_multiple} variables in the dataset as variable
labels. For example, let's say you have a variable, V001, which is a {it: select_multiple} 
with two options, {bf: Option A} (with the value 1) and {bf: Option B} (with the 
value 2). By default, SurveyCTO will provide a Stata .do file to split this variable
into two sub-variables: V001_1 and V001_2. {cmd: ctometa} would assign the variable 
{help label} "V001=Option 1" to V001_1, and "V001=Option B" to V001_2.


{pstd}
All metadata is stored in {help char:characteristics} with the prefix {bf:CTO_{it:fieldname}}, 
where {it:fieldname} is a SurveyCTO field such as {it:label}, {it:hint}, {it:relevance},
etc. These can be referenced by commands such as the {help ds} command, via the syntax:

	{cmd:ds, has(char CTO_}{it:fieldname}{cmd:)}
	
	
{pstd}
By default, {cmd:ctometa} will remove the list name from {it:select_one} and
{it:select_multiple} variables before assigning their type characteristic. It will
create a new characteristic, {it:list}, that stores the list of choices in the 
{it:choices}. For example, if you have a variable, v002, which is a {it:calculate} 
field in SurveyCTO, the characteristic {bf:v002[CTO_type]} will be "calculate". 
However, if the variable v002 were a {it:select_one yesno} field, {bf:v002[CTO_type]}
would return "select_one", and {bf:v002[CTO_list]} would return "yesno". Similar
for {it:select_multiple} fields.	


{title:Remarks} 

{pstd}
SurveyCTO makes use of the "$" symbol in labels, hints, and choices. For example,
the label for a variable such as {bf:v002} could read "{it:This label references the ${v001} field.}". 
If a {help global} macro {bf:$v001} had been specified, Stata
would insert its contents into the {help char:characteristic}. Otherwise, it would
write replace the whole phrase ("${v001}") with a blank space. 

{pstd}
{cmd:ctometa} edits all fields to get rid of this symbol. For clarity, it also 
replaces the "{" and "}" with a "[" and "]", respectively. So, the above label would
read "{it:This label references the [v001] field.}".

{pstd}
Where the field for a given variable is blank in SurveyCTO (e.g. a field with 
no relevance expression, indicating that the question is asked for all cases), 
the variable in Stata will not be assigned a characteristic for that variable.
So, for example, all variables that were {it:calculate} variables in SurveyCTO
will have no value for the {bf:CTO_list} characteristic. 

{title:Options}

{phang}{opt k:eep(namelist)} specifies a list of fields to use as metadata. Any 
field present in your SurveyCTO XLSForm is acceptable. 

	{bf:Note}: colons should disappear. E.g. {it:label:hindi} should become {it:labelhindi}.

{phang}{opt noval:labels} prevents {cmd:ctometa} from re-labelling existing variable values using the {it:choices} sheet.

{phang}{opt novar:labels} prevents {cmd:ctometa} from re-labelling existing variables using the specified {it:label}.

{phang}{opt nop:reserve} Programmer's option. You will be left with the "survey" sheet (useful for debugging).


{title:Examples}

{pstd}
Assume you have a dataset {it:example.dta}, and an associated XLSForm {it: example.xlsx}
in your current directory:

        {cmd:.} {cmd: use example.dta, clear}

{pstd}
To pull all metadata fields as characteristics, type:

        {cmd:.} {cmd: ctometa using example.xlsx}
		
{pstd}
If you only want to add the characteristics for {it:type}, {it:label}, {it:label:hindi}, 
and {it:relevance}, you would specify:

        {cmd:.} {cmd: ctometa using example.xlsx, keep(type label labelhindi relevance)}
		
{pstd}
To create a variable list containing all variables of the type {it:select_one}, 
you would then type:

        {cmd:.} {cmd: ds, has(char CTO_type_select_one)}


{title:Acknowledgements}

{pstd}
No acknowledgements as of yet.


{title:Authors}

{pstd}Aaron Wolf, Northwestern University{p_end}
{pstd}aaron.wolf@u.northwestern.edu{p_end}

