# ctometa

## Installing via *net install*

The current version is still a work in progress. To install, user can use the net install command to download from the project's Github page:

```
net install ctometa, from("https://aarondwolf.github.io/ctometa")
```

## Syntax

        ctometa using filename [, keep(namelist) nopreserve novallabels novarlabels]

## Description

**ctometa** reads in metadata coded in an Excel document for SurveyCTO (an XLSForm) and applies it to the current dataset by applying characteristics. This metadata includes variable labels, hints, constraimts, relevance expressions, etc.

For *select_one* variables, ctometa creates a new set of value labels by pulling from the choices sheet in the SurveyCTO XLSForm. The command does not, by default, assign those value labels to existing variables.  The option **<u>v</u>arlabels** can be specified to attach the SurveyCTO variable labels to each variable.

The command also pulls value labels from the choices sheet and applies the appropriate labels to pre-split *select_multiple* variables in the dataset as variable labels. For example, let's say you have a variable, V001, which is a *select_multiple* with two options, Option A (with the value 1) and Option B (with the value 2). By default, SurveyCTO will provide a Stata .do file to split this variable into two sub-variables: V001_1 and V001_2.  **ctometa** would assign the variable label "V001=Option A" to V001_1, and "V001=Option B" to V001_2.

All metadata is stored in characteristics with the prefix CTO_fieldname, where fieldname is a SurveyCTO field such as label, hint, relevance, etc. These can be referenced by commands such as the ds command, via the syntax:


        ds, has(char CTO_fieldname)

By default, ctometa will remove the list name from *select_one* and *select_multiple* variables before assigning their type characteristic. It will create a new characteristic, *list*, that stores the list of choices in the choices. For example, if you have a variable, v002, which is a calculate field in SurveyCTO, the characteristic v002[CTO_type] will be "calculate". However, if the variable v002 were a *select_one yesno* field, v002[CTO_type] would return "select_one", and v002[CTO_list] would return "yesno". Similar for select_multiple fields.

## Remarks 

SurveyCTO makes use of the "$" symbol in labels, hints, and choices. For example, the label for a variable such as v002 could read "This label references the ${v001} field.".  If a global macro $v001 had been specified, Stata would insert its contents into the characteristic. Otherwise, it would write replace the whole phrase ("${v001}") with a blank space.

ctometa edits all fields to get rid of this symbol. For clarity, it also replaces the "{" and "}" with a "[" and "]", respectively. So, the above label would read "This label references the [v001] field.".

Where the field for a given variable is blank in SurveyCTO (e.g. a field with no relevance expression, indicating that the question is asked for all cases), the variable in Stata will not be assigned a characteristic for that variable.  So, for example, all variables that were calculate variables in SurveyCTO will have no value for the CTO_list characteristic.

## Options

- **<u>k</u>eep(namelist)** specifies a list of fields to use as metadata. Any field present in your SurveyCTO XLSForm is acceptable. *Note: colons should disappear. E.g. label:hindi should become labelhindi.*
- **<u>noval</u>labels** prevents ctometa from re-labelling existing variable values using the choices
      sheet.
- **<u>novar</u>labels** prevents ctometa from re-labelling existing variables using the specified label.
- **<u>nop</u>reserve** Programmer's option. You will be left with the "survey" sheet (useful for
      debugging).

## Examples

Assume you have a dataset example.dta, and an associated XLSForm example.xlsx in your current directory:

```
.  use example.dta, clear
```

To pull all metadata fields as characteristics, type:

```
.  ctometa using example.xlsx
```

If you only want to add the characteristics for type, label, label:hindi, and relevance, you would specify:

```
.  ctometa using example.xlsx, keep(type label labelhindi relevance)
```


To create a variable list containing all variables of the type select_one, you would then type:

```
.  ds, has(char CTO_type_select_one)
```

## Acknowledgements

No acknowledgements as of yet.

## Authors

Aaron Wolf, Northwestern University
aaron.wolf@u.northwestern.edu