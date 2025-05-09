/*
* ───────────────────────────────────────────────────────────────────────────────────────────────
* Created by: Maxify Development Team
* Created Date: 22th,April,2025
* Purpose: : The SwiftRetryScheduler is responsible to handel Failure Mechanism:
* Owner :  Encalm
*───────────────────────────────────────────────────────────────────────────────────────────────
*/
global class SwiftRetryScheduler implements Schedulable {
    String oppId;
    String actionType;

    global SwiftRetryScheduler(String oppId, String actionType) {
        this.oppId = oppId;
        this.actionType = actionType;
    }
 
    global void execute(SchedulableContext sc) {
        apiCall(oppId, actionType);
    }
     
    @future (callout=true)
    global static void apiCall(String oppId, String actionType) {
         MDEN_SWIFT.getAccessToken(oppId, actionType);
    }
}