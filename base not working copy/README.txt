Main concept and core functions: Jerzy Kasperek (kasperek@agh.edu.pl)
Auxiliary functions: �ukasz Smolarek (lukasz.smolarek@e-vertigo.com)
Upgrade: Pawe� J. Rajda (pjarajda@agh.edu.pl)
{===================================================================================================================}
{
Version 8.0
Date 29.08.2023

Change log
1. Edited : indents, names (UpperCamelCase), kewords (lowercase), comments.
   Removed (comment) declarations of not used objects.

}
{===================================================================================================================}
Based on Altium scripts (as below) for MTBF evaluation with Reliasoft Lambda Predict Software
Main function:
( AddComponentUserParameters opens FileOpen dialog. User should open dedicated format config txt file.
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
The main AddComponentUserParameters procedure reads config file line by line and for each parameter found
it scans current design for SchDoc documents. Then it calls the main engine: AddUserDefParamsToComponents procedure with two arguments: current SchDoc and parameter. 
Then each SchDoc component is checked if there is a match with given parameter. If so, the parameter is attached
to the component with its new value and given visibility aspect.

So far, there are four match criteria defined.

1. Config line example - Designator field:
   'R' 'RS_RTD_PWR' '0.1' 'OFF'
   First string = 'R' (one letter) defines an attachment with given parameter group ('RS_RTD_PWR' - rated power in
   this example) to every component with its ALTIUM designator field starting with 'R' letter, eg. R1, R3, R41 ...
   in this example receive parameter RS_RTD_PWR = 0.1 (Watt). Visibility for this parameter is set to 'OFF'.

2. Config lines example - ......:
   'U21' 'RS_CATT' 'Microprocessor,*Digital' 'OFF'
   'U21' 'RS_NMBR_BITS' '16' 'OFF'
   After these two lines as above processing,  component U21 (if found) with will receive parameter RS_CATT =
   'Microprocessor, Digital', and  RS_NMBR_BITS = 16.
   '*' symbols are coverted into spaces. Visibility for this parameter is set to 'OFF'.

3. Config line example - Description field:
   'Capacitor' 'RS_CATT' 'Capacitor' 'OFF'
   First string = 'Capacitor' will define an attachment with given parameter ('RS_CATT' in this example) to every
   component with the word 'Capacitor' in its ALTIUM decription field. Also will set its value to second string
   ('Capacitor' in this example). Visibility for this parameter is set to 'OFF'.

4. Config line example - Global match:
  'All' 'RS_CATT' '?' 'ON'
   First string = 'All' will define an attachment with given parameter ('RS_CAT' in this example) to every component
   and will set its value to the second string ('?' in this example). Visibility for this parameter will be set to
   'ON'. Category 'RS_CAT' defines component category. This is the most important categorisation - and must be set
   for each component.

Special report utility formats
5. Config line example - Exact parameter check:
   '???' 'RS_CATT' 'any' 'any'
   Generates a report for any component checking if given parameter name is set and/or contains '?'.
   This config line shall be used at the end.

6. Config line example - All parameters check:
   '???' '???' 'any' 'any' generates report for an every parameter used in every component
   So this config line shall be used as the last one...

The log file records the work in text file named with the current time stamp.
}

// Copyright notice from ALTIUM
//================================================================================================================== 
// Summary                                                                      
// Demo how to add, modify and delete the user parameters for components        
//                                                                              
// Version 1.0                                                                  
// Copyright (c) 2008 by Altium Limited                                         
//================================================================================================================== 