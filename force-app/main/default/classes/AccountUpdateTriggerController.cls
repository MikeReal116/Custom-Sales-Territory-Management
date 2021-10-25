public with sharing class AccountUpdateTriggerController {

    public static void afterInsert(List<Account> newAccs){
        
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

    private static void handleOwnerChange(Map<Id, String> idMapToBillingPostalCode){
        //territory zip code map with the sales rep Id
        Map <String, Id> territoryMapToRep = new Map<String, Id>();

        
        List<Territory__c> territories = [
            SELECT Id, Zip_Code__c,Owner__c 
            FROM Territory__c 
            WHERE Zip_Code__c IN :idMapToBillingPostalCode.values()
        ];

        //return if no territory with the billing code hasn't been assigned to any sales rep
        if(territories.isEmpty()){
            return;
        }

        for(Territory__c territory : territories){
            territoryMapToRep.put(territory.Zip_Code__c, territory.Owner__c);
        }

        List<Account> accounts = [
            SELECT Id, OwnerId, BillingPostalCode 
            FROM Account 
            WHERE Id IN :idMapToBillingPostalCode.KeySet()
        ];
        
        Map<Id, Id> accountIdMapToOwnerId = new Map<Id, Id>();

        for(Account acc: accounts){
            if(territoryMapToRep.containsKey(acc.BillingPostalCode)){
                acc.OwnerId = territoryMapToRep.get(acc.BillingPostalCode);
                accountIdMapToOwnerId.put(acc.Id, territoryMapToRep.get(acc.BillingPostalCode));
            }
        }

        update accounts;

        List<Contact> contacts = [
            SELECT Id, AccountId,OwnerId 
            FROM Contact 
            WHERE AccountId IN :accountIdMapToOwnerId.KeySet()
        ];

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
