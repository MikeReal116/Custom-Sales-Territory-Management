trigger AccountUpdate on Account (before insert, after update) {

    switch on Trigger.operationType {
        when BEFORE_INSERT{
            AccountUpdateTriggerController.beforeInsert(Trigger.new);
        }
        when  AFTER_UPDATE{
            AccountUpdateTriggerController.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}