@isTest
public class SamplePMDViolationTest {

    @isTest
    static void testUpdateAccounts_NoDmlOccurs_NamesRemainUnchanged() {
        // Arrange: Create test Accounts
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accList.add(new Account(Name = 'Test Account ' + i));
        }
        insert accList;

        // Create one Contact per Account (method queries them but does nothing with them beyond grouping)
        List<Contact> conList = new List<Contact>();
        for (Account acc : accList) {
            conList.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                AccountId = acc.Id
            ));
        }
        insert conList;

        // Baseline: query fresh copy of accounts to capture original names
        Map<Id, String> originalNamesById = new Map<Id, String>();
        for (Account a : [
            SELECT Id, Name
            FROM Account
            WHERE Id IN :accList
        ]) {
            originalNamesById.put(a.Id, a.Name);
        }
        System.assertEquals(5, originalNamesById.size(), 'Precondition: 5 accounts should exist');

        // Act
        Test.startTest();
        SamplePMDViolation.updateAccounts();
        Test.stopTest();

        // Assert: Since updateAccounts() does not perform DML, names should be unchanged
        List<Account> postCallAccounts = [
            SELECT Id, Name
            FROM Account
            WHERE Id IN :accList
            ORDER BY Id
        ];
        System.assertEquals(5, postCallAccounts.size(), '5 accounts should still be present');

        for (Account acc : postCallAccounts) {
            System.assertEquals(
                originalNamesById.get(acc.Id),
                acc.Name,
                'Account Name should remain unchanged because no DML is performed by updateAccounts()'
            );
        }
    }

    @isTest
    static void testUpdateAccounts_WithNoData_NoErrors() {
        // Act & Assert: Should not throw when there are no accounts
        Test.startTest();
        SamplePMDViolation.updateAccounts();
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Account], 'No accounts should exist in this test');
        System.assertEquals(0, [SELECT COUNT() FROM Contact], 'No contacts should exist in this test');
    }
}
