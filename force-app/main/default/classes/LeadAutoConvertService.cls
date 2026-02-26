/**
 * LeadAutoConvertService
 * 
 * Automatically converts newly created Leads when a matching Contact already
 * exists in Salesforce (matched by email address). The lead is merged into the
 * existing Contact and Account without creating a new Opportunity.
 * 
 * Called from LeadTriggerHandler.afterInsert().
 */
public class LeadAutoConvertService {

    @TestVisible
    private static final String CONVERTED_STATUS = 'Converted';

    /**
     * Auto-converts leads whose email matches an existing Contact.
     * - Matches are case-insensitive on the Email field.
     * - Only contacts that belong to an Account are considered.
     * - No Opportunity is created during conversion.
     * - Uses allOrNone = false so individual failures don't block other conversions.
     *
     * @param newLeads List of newly inserted Lead records (from after insert context)
     */
    public static void autoConvertLeads(List<Lead> newLeads) {
        // 1. Collect non-blank emails from the new leads
        Map<String, Lead> emailToLeadMap = new Map<String, Lead>();
        for (Lead ld : newLeads) {
            if (String.isNotBlank(ld.Email)) {
                emailToLeadMap.put(ld.Email.toLowerCase(), ld);
            }
        }

        if (emailToLeadMap.isEmpty()) {
            return;
        }

        // 2. Query existing Contacts with matching emails that belong to an Account
        List<Contact> matchingContacts = [
            SELECT Id, Email, AccountId
            FROM Contact
            WHERE Email IN :emailToLeadMap.keySet()
              AND AccountId != null
            ORDER BY CreatedDate DESC
        ];

        if (matchingContacts.isEmpty()) {
            return;
        }

        // 3. Build email → Contact map (first match wins per email)
        Map<String, Contact> emailToContactMap = new Map<String, Contact>();
        for (Contact c : matchingContacts) {
            String emailKey = c.Email.toLowerCase();
            if (!emailToContactMap.containsKey(emailKey)) {
                emailToContactMap.put(emailKey, c);
            }
        }

        // 4. Build LeadConvert records for each matched lead
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        for (String email : emailToContactMap.keySet()) {
            Lead matchedLead = emailToLeadMap.get(email);
            Contact matchedContact = emailToContactMap.get(email);

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(matchedLead.Id);
            lc.setContactId(matchedContact.Id);
            lc.setAccountId(matchedContact.AccountId);
            lc.setDoNotCreateOpportunity(true);
            lc.setConvertedStatus(CONVERTED_STATUS);

            leadConverts.add(lc);
        }

        // 5. Convert leads — allOrNone = false for graceful partial-failure handling
        if (!leadConverts.isEmpty()) {
            List<Database.LeadConvertResult> results = Database.convertLead(leadConverts, false);

            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug(LoggingLevel.ERROR,
                            'Lead auto-convert failed for Lead ' + leadConverts[i].getLeadId() +
                            ': ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
    }
}

