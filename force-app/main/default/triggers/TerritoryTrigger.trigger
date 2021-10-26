trigger TerritoryTrigger on Territory__c (before insert, before update) {

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            TerritoryTriggerHandler.beforeInsertTerritory(Trigger.new);
        }
        when BEFORE_UPDATE {
            TerritoryTriggerHandler.beforeUpdateTerritory(Trigger.new, Trigger.oldMap);
        }
    }

}