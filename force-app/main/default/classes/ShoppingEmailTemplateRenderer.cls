public with sharing class ShoppingEmailTemplateRenderer {
    @InvocableMethod(label='Shopping Email Template' description='Renders a Visualforce email template with merge fields.')
    public static List<TemplateResult> renderTemplate(List<TemplateInput> inputs) {
        List<TemplateResult> results = new List<TemplateResult>();

        for (TemplateInput input : inputs) {
            if (input.leadId == null || input.templateId == null) {
                continue;
            }

            try {
                // Render the stored email template
                Messaging.SingleEmailMessage emailMessage = Messaging.renderStoredEmailTemplate(input.templateId, input.leadId, null);

                if (emailMessage != null) {
                    TemplateResult result = new TemplateResult();
                    result.body = emailMessage.getHtmlBody(); // Extract HTML content
                    results.add(result);
                }
            } catch (Exception e) {
                System.debug('Error rendering email template: ' + e.getMessage());
            }
        }
        return results;
    }

    // Input class for Flow
    public class TemplateInput {
        @InvocableVariable(label='Lead ID' required=true)
        public Id leadId;

        @InvocableVariable(label='Template ID' required=true)
        public Id templateId;
    }

    // Output class for Flow
    public class TemplateResult {
        @InvocableVariable(label='Body')
        public String body;
    }
}