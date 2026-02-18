public class SamplePMDViolation {

    public static void updateAccounts() {
        
        List<Account> accList = [SELECT Id, Name FROM Account LIMIT 5];
        
        String temp = 'Unused Variable'; // PMD: Unused local variable
        
        for(Account acc : accList) {
            
            // PMD: SOQL inside loop
            List<Contact> conList = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
            
            acc.Name = 'Updated Name'; // PMD: Hardcoded string
            
            try {
                update acc;
            } catch(Exception e) {
                // PMD: Empty catch block
            }
        }
        
        Id hardcodedId = '001XXXXXXXXXXXXXXX'; // PMD: Hardcoded ID
    }
}