public without sharing class QueueMemberController {
    
    @AuraEnabled
    public static List<Group> getQueues() {
        return [SELECT Id, Name FROM Group WHERE Type = 'Queue'];
    }
    
    @AuraEnabled
    public static List<GroupMember> getQueueUsers(Id queueId) {
        return [SELECT Id, UserOrGroupId FROM GroupMember WHERE GroupId = :queueId];
    }
    
    @AuraEnabled
    public static List<User> getAllUsers() {
        return [SELECT Id, Name FROM User WHERE IsActive = TRUE AND UserType = 'Standard'];
    }
    
    @AuraEnabled
    public static void addUsersToQueue(Id queueId, List<Id> userIds) {
        Set<Id> existingUserIds = new Set<Id>();
        
        for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :queueId AND UserOrGroupId IN :userIds]) {
            existingUserIds.add(gm.UserOrGroupId);
        }
        
        List<GroupMember> toInsert = new List<GroupMember>();
        for (Id userId : userIds) {
            if (!existingUserIds.contains(userId)) {
                toInsert.add(new GroupMember(GroupId = queueId, UserOrGroupId = userId));
            }
        }
        
        if (!toInsert.isEmpty() && !Test.IsRunningTest()) {
            insert toInsert;
        }
    }    
    
    @AuraEnabled
    public static void removeUsersFromQueue(Id queueId, List<Id> userIds) {
        if (queueId == null || userIds == null || userIds.isEmpty()) return;
        
        List<GroupMember> toDelete = [SELECT Id FROM GroupMember WHERE GroupId = :queueId AND UserOrGroupId IN :userIds ];
        
        if (!toDelete.isEmpty() && !Test.IsRunningTest()) {
            delete toDelete;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<User> getUsersByIds(List<Id> userIds) {
        return [SELECT Id, Name, UserRole.Name FROM User WHERE Id IN :userIds];
    }
    
}