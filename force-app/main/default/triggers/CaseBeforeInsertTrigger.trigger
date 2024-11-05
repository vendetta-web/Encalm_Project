trigger CaseBeforeInsertTrigger on Case (before insert) {
    system.debug('-----------------------');
    for (Case c : Trigger.new) {
        // Add your logic here. For example:
        if (c.Subject == null) {
            c.Subject = 'Default Subject'; // Set a default subject if none is provided
        }
        
        // Other business logic can be added here
    }
}