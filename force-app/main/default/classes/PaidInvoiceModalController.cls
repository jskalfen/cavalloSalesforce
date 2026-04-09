public with sharing class PaidInvoiceModalController {

    // The "Paid On" field from the Chargebee package:
    // chargebeeapps__Paid_On__c — used for date-range filtering below.

    public class InvoiceWrapper {
        @AuraEnabled public String invoiceId;
        @AuraEnabled public String invoiceName;
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountOwnerName;
        @AuraEnabled public String status;
        @AuraEnabled public Boolean checkedInvoice;
        @AuraEnabled public Date paidOn;
    }

    public class InvoiceResult {
        @AuraEnabled public List<InvoiceWrapper> invoices;
        @AuraEnabled public Boolean isAdmin;
        @AuraEnabled public String userRoleType;
        @AuraEnabled public Integer totalCount;
    }

    @AuraEnabled(cacheable=true)
    public static InvoiceResult getPaidInvoices(String dateFilter) {
        InvoiceResult result = new InvoiceResult();

        User currentUser = [
            SELECT Id, Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        String profileName = currentUser.Profile.Name;

        Boolean isAdmin = profileName == 'System Administrator';
        Boolean isAM    = profileName == 'Account Manager';
        Boolean isAE    = profileName == 'Account Executive';

        result.isAdmin = isAdmin;
        if (isAdmin) {
            result.userRoleType = 'Admin';
        } else if (isAM) {
            result.userRoleType = 'Account Manager';
        } else if (isAE) {
            result.userRoleType = 'Account Executive';
        } else {
            result.userRoleType = 'Other';
        }

        Date startDate;
        Date endDateExclusive;

        if (dateFilter == 'LAST_MONTH') {
            startDate = Date.today().addMonths(-1).toStartOfMonth();
            endDateExclusive = Date.today().toStartOfMonth();
        } else if (dateFilter == 'THIS_QUARTER') {
            Integer month = Date.today().month();
            Integer quarterStartMonth = ((month - 1) / 3) * 3 + 1;
            startDate = Date.newInstance(Date.today().year(), quarterStartMonth, 1);
            endDateExclusive = Date.today().addDays(1);
        } else {
            startDate = Date.today().toStartOfMonth();
            endDateExclusive = Date.today().addDays(1);
        }

        Id currentUserId = UserInfo.getUserId();
        List<chargebeeapps__CB_Invoice__c> invoices;

        if (isAdmin) {
            invoices = [
                SELECT Id, Name,
                       chargebeeapps__Account__r.Name,
                       chargebeeapps__Account__r.Owner.Name,
                       chargebeeapps__Status__c,
                       chargebeeapps__Paid_On__c,
                       Checked_Invoice__c
                FROM chargebeeapps__CB_Invoice__c
                WHERE chargebeeapps__Status__c = 'paid'
                  AND Checked_Invoice__c = false
                  AND chargebeeapps__Paid_On__c >= :startDate
                  AND chargebeeapps__Paid_On__c <  :endDateExclusive
                ORDER BY chargebeeapps__Account__r.Name ASC
                LIMIT 500
            ];
        } else if (isAM || isAE) {
            invoices = [
                SELECT Id, Name,
                       chargebeeapps__Account__r.Name,
                       chargebeeapps__Account__r.Owner.Name,
                       chargebeeapps__Status__c,
                       chargebeeapps__Paid_On__c,
                       Checked_Invoice__c
                FROM chargebeeapps__CB_Invoice__c
                WHERE chargebeeapps__Status__c = 'paid'
                  AND Checked_Invoice__c = false
                  AND chargebeeapps__Account__r.OwnerId = :currentUserId
                  AND chargebeeapps__Paid_On__c >= :startDate
                  AND chargebeeapps__Paid_On__c <  :endDateExclusive
                ORDER BY chargebeeapps__Account__r.Name ASC
                LIMIT 500
            ];
        } else {
            result.invoices = new List<InvoiceWrapper>();
            result.totalCount = 0;
            return result;
        }

        List<InvoiceWrapper> wrappers = new List<InvoiceWrapper>();
        for (chargebeeapps__CB_Invoice__c inv : invoices) {
            InvoiceWrapper w = new InvoiceWrapper();
            w.invoiceId      = inv.Id;
            w.invoiceName    = inv.Name;
            w.accountId      = inv.chargebeeapps__Account__c;
            w.accountName    = inv.chargebeeapps__Account__r.Name;
            w.accountOwnerName = inv.chargebeeapps__Account__r.Owner.Name;
            w.status         = inv.chargebeeapps__Status__c;
            w.checkedInvoice = inv.Checked_Invoice__c;
            w.paidOn         = inv.chargebeeapps__Paid_On__c != null
                               ? inv.chargebeeapps__Paid_On__c.date()
                               : null;
            wrappers.add(w);
        }

        result.invoices   = wrappers;
        result.totalCount = wrappers.size();
        return result;
    }

    @AuraEnabled
    public static void markInvoiceChecked(String invoiceId) {
        if (String.isBlank(invoiceId)) {
            throw new AuraHandledException('Invoice Id is required.');
        }
        chargebeeapps__CB_Invoice__c invoice = new chargebeeapps__CB_Invoice__c(
            Id = invoiceId,
            Checked_Invoice__c = true
        );
        update invoice;
    }
}
