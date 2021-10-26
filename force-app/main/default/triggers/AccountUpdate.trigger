trigger AccountUpdate on Account (after insert, after update) {

    switch on Trigger.operationType {
        when AFTER_INSERT{
            AccountUpdateTriggerController.afterInsert(Trigger.new);
        }
        when  AFTER_UPDATE{
            AccountUpdateTriggerController.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}