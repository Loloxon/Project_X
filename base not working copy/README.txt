{ Main concept and core functions Jerzy Kasperek kasperek@agh.edu.pl
{ Auxiliary functions Łukasz Smolarek (lukasz.smolarek@e-vertigo.com)
{======================================================================================================================================================}
{
Version 7.1
Date 20.11.2018

Change log
1. New functions MTBF_LogUSerDefinedParametersOfComponents - logs all...
2. New functions MTBF_CopyDefinedParametersValue - OK
3. LP_LOG directory is required in Project folder
4. Missing raport correction
5. Added selection criteria to add components for actions...
6. New function - replace header
7. All supported usage examples
8. Missing part raport formatting changed - each component data in one line to easy sorting + no duplicates
}
{======================================================================================================================================================}
{ Based on Altium scripts ( as below) for MTBF evaluation with Reliasoft Lambda Predict Software
{ Main function:
( MTBF_AddComponentUserParameters opens FileOpen dialog. User should open dedicated format config txt file.
{
# Syntax:
# Line starting with # - its a comment line
# Each line introduce one  parameter and should have exact four words (string type)
# First ASCII string is the Altium component type selector. 'All' denotes global ( for each component) parameter.
# Second ASCII string is the LambdaPredict given methodology Parameter Name
# Third ASCII string is the Parameter Value assigned
# Fourth - (last one) ASCII string is the Visibility atribute (ON/OFF)
#
# Note that spaces are not allowed in "Altium component type" field! In "Parameter Value" field spaces are allowed but
# should be coded by '*'  Scipt will recover spaces
# Also note that EXACT one space is required between strings!

Main functionality:
The main MTBF_AddComponentUserParameters procedure reads config file line by line and than
for each parameter found scans current design for SchDoc document.
Then calls the main engine: procedure MTBF_AddUserDefinedParametersToComponents with two parameters:
current SchDoc and parameter. Then each SchDoc component is checked if there is a match with given parameter.
If so, the parameter is attached to the component with its new value and given visibility aspect.
So for, there are four match criteria defined.
1. Config line example:
  'All' 'RS_CATT' '?' 'ON'
   First string = 'All' will define an attachment with given parameter ('RS_CAT' in this example) to every component and will set its value to
   the second string ('?' in this example). Also the visibility for this parameter will be set to 'ON'.
   Category 'RS_CAT' defines component category. This is the most important categorisation - and must be set for each component.
2. Config line example:
   'Capacitor' 'RS_CATT' 'Capacitor' 'OFF'
   First string = 'Capacitor' will define an attachment with given parameter ('RS_CATT' in this example) to every component with the word 'Capacitor'
   in his ALTIUM decription field. Also will sets its value to secong string ('Capacitor' in this example).
   Also visibility for this parameter is set to 'OFF'.
3. Config lines example:
   'U21' 'RS_CATT' 'Microprocessor,*Digital' 'OFF'
   'U21' 'RS_NMBR_BITS' '16' 'OFF'
   After these two lines as above processing,  component U21 (if found) with will receive parameter RS_CATT = 'Microprocessor, Digital',
   and  RS_NMBR_BITS = 16
   ( '*' symbols are coverted into spaces).Also visibility for this parameter is set to 'OFF'.
4. Config line example:
   'R' 'RS_RTD_PWR' '0.1' 'OFF'
   First string = 'R' (one letter) will define an attachment with given parameter group ('RS_RTD_PWR' - rated power in this example) to every component with
   his ALTIUM designator field starting with 'R' letter. So, R1,R3,R41 in this example will receive parameter RS_RTD_PWR = 0.1 (Watt).
   Also visibility for this parameter is set to 'OFF'.

Special raport utility
5. Config line example:
   '???' 'RS_CATT' 'any' 'any' generates report for any component checking if given parameter name is set and/or contain '?'.
   So this config line shall be used at the end...

Special raport utility     (version 4.0 +)
6. Config line example:
   '???' '???' 'any' 'any' generates report for an every parameter used in every ny component
   So this config line shall be used as the last one...

The log file records the work in text file named with the current time stamp.
}

// Copyright notice from ALTIUM
{======================================================================================================================================================}
{ Summary                                                                      }
{ Demo how to add, modify and delete the user parameters for components        }
{                                                                              }
{ Version 1.0                                                                  }
{ Copyright (c) 2008 by Altium Limited                                         }
{======================================================================================================================================================}