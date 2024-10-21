trigger ExtractPassengerDetails on EmailMessage (after insert) {
    for (EmailMessage email : Trigger.New) {
        System.debug('Processinnng Email: ' + email.Subject);
        PassengerDetailProcessor.processEmailBody(email.TextBody);
    }
}