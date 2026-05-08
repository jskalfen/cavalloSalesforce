public with sharing class EACActivityService {

    private static final String INVOICE_SUBJECT_PREFIX = 'Cavallo Invoice';

    @TestVisible
    private static Set<Id> trackedUserIdsCache;

    public static Set<Id> getTrackedUserIds() {
        if (trackedUserIdsCache != null) {
            return trackedUserIdsCache;
        }
        trackedUserIdsCache = new Set<Id>();
        for (EAC_Tracked_User__mdt rec : [
            SELECT User_Id__c FROM EAC_Tracked_User__mdt WHERE User_Id__c != null
        ]) {
            String uid = rec.User_Id__c.trim();
            if (String.isNotBlank(uid)) {
                try {
                    trackedUserIdsCache.add((Id) uid);
                } catch (Exception e) {
                    // Skip malformed Ids in config
                }
            }
        }
        return trackedUserIdsCache;
    }

    public static void processTaskActivities(List<Task> tasks) {
        Set<Id> trackedIds = getTrackedUserIds();
        if (trackedIds.isEmpty()) {
            return;
        }

        Map<Id, ActivityInfo> accountActivityMap = new Map<Id, ActivityInfo>();

        for (Task t : tasks) {
            if (!trackedIds.contains(t.OwnerId)) {
                continue;
            }
            if (String.isNotBlank(t.Subject) && t.Subject.startsWith(INVOICE_SUBJECT_PREFIX)) {
                continue;
            }
            Id accountId = t.AccountId;
            if (accountId == null) {
                continue;
            }
            updateActivityMap(accountActivityMap, accountId, t.CreatedDate, t.OwnerId);
        }

        applyAccountUpdates(accountActivityMap);
    }

    public static void processEventActivities(List<Event> events) {
        Set<Id> trackedIds = getTrackedUserIds();
        if (trackedIds.isEmpty()) {
            return;
        }

        Map<Id, ActivityInfo> accountActivityMap = new Map<Id, ActivityInfo>();

        for (Event e : events) {
            if (!trackedIds.contains(e.OwnerId)) {
                continue;
            }
            if (String.isNotBlank(e.Subject) && e.Subject.startsWith(INVOICE_SUBJECT_PREFIX)) {
                continue;
            }
            Id accountId = e.AccountId;
            if (accountId == null) {
                continue;
            }
            updateActivityMap(accountActivityMap, accountId, e.CreatedDate, e.OwnerId);
        }

        applyAccountUpdates(accountActivityMap);
    }

    private static void updateActivityMap(Map<Id, ActivityInfo> activityMap, Id accountId, DateTime activityDate, Id userId) {
        ActivityInfo existing = activityMap.get(accountId);
        if (existing == null || activityDate > existing.activityDate) {
            activityMap.put(accountId, new ActivityInfo(activityDate, userId));
        }
    }

    private static void applyAccountUpdates(Map<Id, ActivityInfo> accountActivityMap) {
        if (accountActivityMap.isEmpty()) {
            return;
        }

        Map<Id, Account> accounts = new Map<Id, Account>([
            SELECT Id, Last_Human_Contact__c, Last_Human_Contact_By__c
            FROM Account
            WHERE Id IN :accountActivityMap.keySet()
        ]);

        List<Account> toUpdate = new List<Account>();
        for (Id acctId : accountActivityMap.keySet()) {
            Account acct = accounts.get(acctId);
            if (acct == null) {
                continue;
            }
            ActivityInfo info = accountActivityMap.get(acctId);
            if (acct.Last_Human_Contact__c == null || info.activityDate > acct.Last_Human_Contact__c) {
                acct.Last_Human_Contact__c = info.activityDate;
                acct.Last_Human_Contact_By__c = info.userId;
                toUpdate.add(acct);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private class ActivityInfo {
        public DateTime activityDate;
        public Id userId;

        public ActivityInfo(DateTime activityDate, Id userId) {
            this.activityDate = activityDate;
            this.userId = userId;
        }
    }
}
