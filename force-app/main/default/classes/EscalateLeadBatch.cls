public class EscalateLeadBatch implements Database.Batchable<SObject>{
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Status, CreatedDate, ownerId FROM Lead WHERE Status = 'Open']);
    }
    public void execute(Database.BatchableContext BC, List<Lead> scope) {
        List<Lead> ldList = new List<Lead>();
        Map<Id, Id> managerMap = new Map<Id, Id>();
        Set<Id> ownerSetId = new set<Id>();
        for(Lead ld : scope){
            ownerSetId.add(ld.OwnerId);
        }
        List<User> usList = [SELECT Id, ManagerId FROM User Where Id =: ownerSetId];
        if(!usList.isEmpty()){
            for(User us : usList){
                managerMap.put(us.Id, us.ManagerId);
            }
        }
        for(Lead ld : scope){
            if(managerMap.values() != null && managerMap.containsKey(ld.OwnerId)){
                Long timeDiff = System.now().getTime() - ld.CreatedDate.getTime();
                if (ld.CreatedDate != null && timeDiff >= 30 * 60 * 1000) {
                    ld.OwnerId = managerMap.get(ld.OwnerId);
                    ld.Status = 'Escalated';
                    ldList.add(ld);
                } 
            }else{
                system.debug('Case owner doesn\'t have Manager');
            }
        }
        if(!ldList.isEmpty()){
            update ldList;
        }
    }
    public void finish(Database.BatchableContext BC) {
        System.debug('Batch process completed!');
    }
}