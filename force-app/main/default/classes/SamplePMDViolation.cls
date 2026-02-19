public with sharing class SamplePMDViolation {

    private static final String UPDATED_NAME = 'Updated Name';

    public static void updateAccounts() {
        
        // Get Accounts
        List<Account> accList = [
            SELECT Id, Name 
            FROM Account 
            LIMIT 5
        ];

        if (accList.isEmpty()) {
            return;
        }

        // Collect Account Ids
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accList) {
            accountIds.add(acc.Id);
        }

        // Query Contacts outside loop (bulkified)
        Map<Id, List<Contact>> contactsByAccount = new Map<Id, List<Contact>>();
        for (Contact con : [
            SELECT Id, AccountId 
            FROM Contact 
            WHERE AccountId IN :accountIds
        ]) {
            if (!contactsByAccount.containsKey(con.AccountId)) {
                contactsByAccount.put(con.AccountId, new List<Contact>());
            }
            contactsByAccount.get(con.AccountId).add(con);
        }

        // Update accounts
        for (Account acc : accList) {
            acc.Name = UPDATED_NAME;
        }

        try {
            update accList; // Single DML
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'Error updating accounts: ' + e.getMessage());
            throw e; // Do not swallow exception
        }
    }
}