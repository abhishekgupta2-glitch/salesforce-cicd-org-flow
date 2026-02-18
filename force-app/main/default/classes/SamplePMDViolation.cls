public class SamplePMDViolation {

    public static void updateAccounts() {
        
        List<Account> accList = [SELECT Id, Name FROM Account LIMIT 5];
        
        String temp = 'Unused Variable'; // Unused variable
        
        for(Account acc : accList) {
            
            // SOQL inside loop
            List<Contact> conList = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
            //jsjhs sjdhdhid
            
            acc.Name = 'Updated Name'; // Hardcoded string
            
            try {
                update acc; // DML inside loop
            } catch(Exception e) {
                // Empty catch block
            }
        }
        
        String hardcodedId = '001XXXXXXXXXXXXXXX'; // keep as String to avoid failure
    }
}