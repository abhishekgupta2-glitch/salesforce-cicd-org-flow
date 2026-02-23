public with sharing class SamplePMDViolation {

    public static void updateAccounts() {
        
        // Get 5 Accounts
        List<Account> accList = [
            SELECT Id, Name 
            FROM Account 
            LIMIT 5
        ];
        
        if(accList.isEmpty()) {
            return;
        }
        
        // Update Account names+abhjiss
        for(Account acc : accList) {
            acc.Name = 'Updated Name';
        }
        
        update accList;
    }
}