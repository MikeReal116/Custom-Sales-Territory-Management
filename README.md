# Requirements


Requirement #1: Recreate the Zip Code spreadsheet as a custom Territory object.The custom object should have the following custom fields Zip Code(Text ) and Owner(Lookup(User))

Requirement #2: When an Account’s BillingPostalCode (aka Zip Code), is changed, 
1. Change the Account Owner to the sales representative assigned to the new zip code
2. Change the Owner field of all the Account’s Contacts to the same sales rep 
3. Change the Owner field of all the Account’s Open Opportunities to the same sales rep

Requirement #3: Multiple sales representatives can be assigned to the same zip code territory. If this is the case, use a random function to select one of the assigned sales representatives.

Requirement #4: Three sales representatives at most can be assigned to a single zip code. Display an error if a user attempts to associate another sales representative to a zip code.





