public with sharing class TerritoryTriggerHandler {
    public static void beforeInsertTerritory(List<Territory__c> newTerritories){
        Set<String> postalCode = new Set<String>();

        // add zip code of the new territories to insert to the set
        for(Territory__c territory: newTerritories){
            if(territory.Zip_Code__c != null){
                postalCode.add(territory.Zip_Code__c);
            }
        }

       checkTerritoryController(postalCode, newTerritories);

   }
  
   public static void beforeUpdateTerritory(List<Territory__c> newTerritories, Map<Id, Territory__c> oldTerritories){
        Set<String> postalCode = new Set<String>();

        // add zip code of the new territories to insert to the set if
        //new zip code is not null and is different from the old one
        for(Territory__c territory: newTerritories){
            if(territory.Zip_Code__c != null && territory.Zip_Code__c != oldTerritories.get(territory.Id).Zip_Code__c){
                postalCode.add(territory.Zip_Code__c);
            }
        }
       
        checkTerritoryController(postalCode, newTerritories);
        
    }

    private static void checkTerritoryController(Set<String> postalCode, List<Territory__c> newTerritories){
        // count the number of sales reps assigned to a single zip code 
        List<AggregateResult> agResults = [
            SELECT Zip_Code__c, COUNT(Id) numOfReps FROM Territory__c
            WHERE Zip_Code__c IN :postalCode 
            GROUP BY Zip_Code__c
        ];

        

        // Map to store the zip code and the number of sales reps assigned to it
        Map<String, Integer> postalCodeMapToSalesReps = new Map<String, Integer>();
        for(AggregateResult agResult : agResults){
            String zipCode = String.valueof(agResult.get('Zip_Code__c'));
            Integer numOfReps = Integer.valueof(agResult.get('numOfReps'));
            postalCodeMapToSalesReps.put(zipCode, numOfReps);
        }

        List<Territory__c> territoriesToInsert = new List<Territory__c>();

        for(Territory__c territory: newTerritories){
            //if zip code already exist in our records and map
            // if it zip code has more than 3 reps associated with it
            if(postalCodeMapToSalesReps.containsKey(territory.Zip_Code__c) && postalCodeMapToSalesReps.get(territory.Zip_Code__c)>=3){
                System.debug('Here');
                territory.addError('You can not have more than 3 sales reps for the same zip code');     
            //if it's a new zip code, add it to the map and it to zero 
            }else if (!postalCodeMapToSalesReps.containsKey(territory.Zip_Code__c)){
                postalCodeMapToSalesReps.put(territory.Zip_Code__c, 0);
            }

            Integer numOfRepsOfPostalCode = postalCodeMapToSalesReps.get(territory.Zip_Code__c);
            postalCodeMapToSalesReps.put(territory.Zip_Code__c, numOfRepsOfPostalCode +1);
        }

    }
    
    
}
