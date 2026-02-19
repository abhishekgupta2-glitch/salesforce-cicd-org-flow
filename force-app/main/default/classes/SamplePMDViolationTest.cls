@isTest
public class SamplePMDViolationTest {

    @isTest
    static void testUpdateAccounts() {
        
        // Create test Accounts
        List<Account> accList = new List<Account>();
        for(Integer i = 0; i < 5; i++) {
            accList.add(new Account(Name = 'Test Account ' + i));
        }
        insert accList;
        
        // Create Contacts for each Account
        List<Contact> conList = new List<Contact>();
        for(Account acc : accList) {
            conList.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                AccountId = acc.Id
            ));
        }
        insert conList;
        
        Test.startTest();
        SamplePMDViolation.updateAccounts();
        Test.stopTest();
        
        // Verify Accounts were updated
        List<Account> updatedAcc = [
            SELECT Id, Name FROM Account WHERE Id IN :accList
        ];
        
        for(Account acc : updatedAcc) {
            System.assertEquals('Updated Name', acc.Name);
        }
    }
}