public  class OmniChannelAssignmentEnforcer {
    public static Boolean isAgentEligibleCase(Id userId) {

        Integer caseCount = [SELECT COUNT() FROM Case WHERE OwnerId = :userId AND Status != 'Closed' AND Status != 'Awaiting Customer Response'];
		system.debug('caseCount>>>'+caseCount);
        return (caseCount < 10);
    }
    public static Boolean isAgentEligibleLead(Id userId) {
        List<String> statusList = new List<String>{'Open','Awaiting Customer Response','Customer Responded'};
        Integer leadCount = [
            SELECT COUNT() 
            FROM Lead 
            WHERE OwnerId = :userId AND Status IN : statusList
        ];

        return (leadCount < 10);
    }
    
}