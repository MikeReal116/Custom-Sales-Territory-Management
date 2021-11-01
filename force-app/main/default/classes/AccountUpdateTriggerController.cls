public with sharing class AccountUpdateTriggerController {

    public static void beforeInsert(List<Account> newAccs){
        
        Map<Id, String> idMapToBillingPostalCode = new Map<Id, String>();

        //loop through the new account and check if it has BillingPostal Code
        //If it has, add to the account Id billing postal code map
        for(Account acc: newAccs){
            if(!String.isBlank(acc.BillingPostalCode)){
                idMapToBillingPostalCode.put(acc.Id, acc.BillingPostalCode);
            }
           
        }

        handleOwnerChange(idMapToBillingPostalCode);

    }
   
    public static void afterUpdate(List<Account> newAccs, Map<Id, Account> oldAccsMap ){
   
        TriggerContextUtility.setFirstRunFalse();
            
        Map<Id, String> idMapToBillingPostalCode = new Map<Id, String>();
           
        //loop through the new account and check if it has BillingPostal Code
        //if the new billing postal code is not null and has changed 
        //If it has, add to the account Id billing postal code map
        for(Account acc : newAccs){
            if(!String.isBlank(acc.BillingPostalCode) && acc.BillingPostalCode!= oldAccsMap.get(acc.Id).BillingPostalCode){
                idMapToBillingPostalCode.put(acc.Id, acc.BillingPostalCode);
            }
        }

            
        handleOwnerChange(idMapToBillingPostalCode);
         

    }

    private static Integer generateRandomInteger(List<Id> ids){
        Integer randomNumber = Integer.valueof(Math.random()*(ids.size()+1));
        return randomNumber;
    }

    private static void handleOwnerChange(Map<Id, String> idMapToBillingPostalCode){
        //territory zip code map with the sales rep Id
        //same zip code can be assigned to multiple sales reps
        Map <String, List<Id>> territoryMapToReps = new Map<String, List<Id>>();

        
        List<Territory__c> territories = [SELECT Id, 
                                                 Zip_Code__c,
                                                 Owner__c 
                                            FROM Territory__c 
                                           WHERE Zip_Code__c IN :idMapToBillingPostalCode.values()];

        //return if no territory with the billing code hasn't been assigned to any sales rep
        if(territories.isEmpty()){
            return;
        }

        for(Territory__c territory : territories){
            //if billing postal code doesnt exist, add it as a key and initialize it as an empty list
            if(!territoryMapToReps.containsKey(territory.Zip_Code__c)){
                territoryMapToReps.put(territory.Zip_Code__c, new List<Id>());
            }
            //get the billing postal code and add the sales reps associated with that postal code
            territoryMapToReps.get(territory.Zip_Code__c).add(territory.Owner__c);
        }

        // check if list contains multiple sales reps randomly assign one rep to that billing postal code
        for(String postalCode: territoryMapToReps.KeySet()){
            if(territoryMapToReps.get(postalCode).size()>1){
                Integer randomNumber = generateRandomInteger(territoryMapToReps.get(postalCode));
                List<Id> newSalesRep = new List<Id>();
                newSalesRep.add(territoryMapToReps.get(postalCode).get(randomNumber));
                territoryMapToReps.put(postalCode, newSalesRep);
            }
        }

        List<Account> accounts = [
            SELECT Id, OwnerId, BillingPostalCode 
            FROM Account 
            WHERE Id IN :idMapToBillingPostalCode.KeySet()
        ];
        
        Map<Id, Id> accountIdMapToOwnerId = new Map<Id, Id>();

        for(Account acc: accounts){
            if(territoryMapToReps.containsKey(acc.BillingPostalCode)){
                acc.OwnerId = territoryMapToReps.get(acc.BillingPostalCode).get(0);
                accountIdMapToOwnerId.put(acc.Id, territoryMapToReps.get(acc.BillingPostalCode).get(0));
            }
        }

        update accounts;

        List<Contact> contacts = [SELECT Id,
                                         AccountId,
                                         OwnerId 
                                    FROM Contact 
                                   WHERE AccountId IN :accountIdMapToOwnerId.KeySet()];

        for(Contact con:contacts){
            if(accountIdMapToOwnerId.containsKey(con.AccountId)){
                con.OwnerId = accountIdMapToOwnerId.get(con.AccountId);
            }
        }
            
        update contacts;

        List<Opportunity> opportunities = [
            SELECT Id, OwnerId FROM Opportunity 
            WHERE StageName != 'Closed Won'
            AND StageName != 'Closed Lost'
            AND AccountId IN :accountIdMapToOwnerId.KeySet()
        ];

        for(Opportunity opp: opportunities){
            if(accountIdMapToOwnerId.containsKey(opp.AccountId)){
                opp.OwnerId = accountIdMapToOwnerId.get(opp.AccountId);
            }
        }

        update opportunities;
    }
    
}
