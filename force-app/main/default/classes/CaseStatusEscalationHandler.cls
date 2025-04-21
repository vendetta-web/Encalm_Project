// Updated by Abhishek :- Not used anywhere, confirmed from Sidhant. April 15 2025

public class CaseStatusEscalationHandler {

    // Method to schedule the action after 2 minutes
    public static void scheduleEscalation(List<Case> casesToEscalate) {
        // Calculate the time 2 minutes from now
        DateTime twoMinutesFromNow = System.now().addMinutes(2);
        System.debug('twoMinutesFromNow'+ twoMinutesFromNow);
        
        // Format the time into the cron expression
        String cronExpression = '0 ' + twoMinutesFromNow.minute() + ' ' + twoMinutesFromNow.hour() + ' ' + twoMinutesFromNow.day() + ' ' + twoMinutesFromNow.month() + ' ? ' + twoMinutesFromNow.year();
        
        // Schedule the job to run in 2 minutes (time-based)
        String jobName = 'Case Status Escalation Job';
        // Schedules the `CaseEscalationJob` as an external class now
        System.schedule(jobName, cronExpression, new CaseEscalationJob(casesToEscalate));
    }
}