@isTest
public class AccountUpdaterTest {

    @isTest
    static void testUpdateAccountPhone() {
        
        // Create test Accounts
        List<Account> accList = new List<Account>();
        for(Integer i = 0; i < 5; i++) {
            accList.add(new Account(
                Name = 'Test Account ' + i,
                Phone = '1234567890'
            ));
        }
        insert accList;
        
        // Call the method
        Test.startTest();
        AccountUpdater.updateAccountPhone();
        Test.stopTest();
        
        // Verify updated values
        List<Account> updatedAccounts = 
            [SELECT Id, Phone FROM Account WHERE Id IN :accList];
        
        for(Account acc : updatedAccounts) {
            System.assertEquals('9999999999', acc.Phone, 
                'Phone number should be updated to 9999999999');
        }
    }
}