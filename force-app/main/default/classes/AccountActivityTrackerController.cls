public with sharing class AccountActivityTrackerController {

    public class AccountWrapper {
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountOwnerName;
        @AuraEnabled public DateTime lastHumanContact;
        @AuraEnabled public String lastHumanContactByName;
        @AuraEnabled public Decimal daysSinceLastContact;
    }

    public class TrackedUserOption {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
    }

    public class ActivityResult {
        @AuraEnabled public List<AccountWrapper> accounts;
        @AuraEnabled public List<TrackedUserOption> trackedUsers;
        @AuraEnabled public Boolean isAdmin;
        @AuraEnabled public Integer totalCount;
    }

    @AuraEnabled(cacheable=true)
    public static ActivityResult getStaleAccounts(String dayFilter, String userFilter) {
        ActivityResult result = new ActivityResult();

        User currentUser = [
            SELECT Id, Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        Boolean isAdmin = currentUser.Profile.Name == 'System Administrator';
        result.isAdmin = isAdmin;

        Integer threshold = parseDayThreshold(dayFilter);

        Set<Id> trackedUserIds = EACActivityService.getTrackedUserIds();
        if (trackedUserIds.isEmpty()) {
            result.accounts = new List<AccountWrapper>();
            result.trackedUsers = new List<TrackedUserOption>();
            result.totalCount = 0;
            return result;
        }

        if (isAdmin) {
            result.trackedUsers = getTrackedUserOptions(trackedUserIds);
        }

        List<Account> staleAccounts;

        if (isAdmin) {
            Set<Id> filterIds = trackedUserIds;
            if (String.isNotBlank(userFilter) && userFilter != 'ALL') {
                try {
                    filterIds = new Set<Id>{ (Id) userFilter };
                } catch (Exception e) {
                    filterIds = trackedUserIds;
                }
            }
            staleAccounts = [
                SELECT Id, Name, Owner.Name,
                       Last_Human_Contact__c, Last_Human_Contact_By__r.Name,
                       Days_Since_Last_Human_Contact__c
                FROM Account
                WHERE OwnerId IN :filterIds
                  AND (Last_Human_Contact__c = null
                       OR Days_Since_Last_Human_Contact__c >= :threshold)
                ORDER BY Days_Since_Last_Human_Contact__c DESC NULLS FIRST
                LIMIT 500
            ];
        } else {
            Id currentUserId = UserInfo.getUserId();
            staleAccounts = [
                SELECT Id, Name, Owner.Name,
                       Last_Human_Contact__c, Last_Human_Contact_By__r.Name,
                       Days_Since_Last_Human_Contact__c
                FROM Account
                WHERE OwnerId = :currentUserId
                  AND (Last_Human_Contact__c = null
                       OR Days_Since_Last_Human_Contact__c >= :threshold)
                ORDER BY Days_Since_Last_Human_Contact__c DESC NULLS FIRST
                LIMIT 500
            ];
        }

        List<AccountWrapper> wrappers = new List<AccountWrapper>();
        for (Account acct : staleAccounts) {
            AccountWrapper w = new AccountWrapper();
            w.accountId = acct.Id;
            w.accountName = acct.Name;
            w.accountOwnerName = acct.Owner.Name;
            w.lastHumanContact = acct.Last_Human_Contact__c;
            w.lastHumanContactByName = acct.Last_Human_Contact_By__r != null
                ? acct.Last_Human_Contact_By__r.Name
                : null;
            w.daysSinceLastContact = acct.Days_Since_Last_Human_Contact__c;
            wrappers.add(w);
        }

        result.accounts = wrappers;
        result.totalCount = wrappers.size();
        return result;
    }

    private static List<TrackedUserOption> getTrackedUserOptions(Set<Id> trackedUserIds) {
        List<TrackedUserOption> options = new List<TrackedUserOption>();
        TrackedUserOption allOption = new TrackedUserOption();
        allOption.value = 'ALL';
        allOption.label = 'All Users';
        options.add(allOption);

        for (User u : [
            SELECT Id, Name FROM User WHERE Id IN :trackedUserIds ORDER BY Name
        ]) {
            TrackedUserOption opt = new TrackedUserOption();
            opt.value = u.Id;
            opt.label = u.Name;
            options.add(opt);
        }
        return options;
    }

    private static Integer parseDayThreshold(String dayFilter) {
        if (dayFilter == '90') {
            return 90;
        } else if (dayFilter == '60') {
            return 60;
        }
        return 30;
    }
}
