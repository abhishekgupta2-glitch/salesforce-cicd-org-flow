public class AccountUpdater {

    public static void updateAccountPhone() {
        
        // Get first 5 accounts
        List<Account> accList = [SELECT Id, Phone FROM Account LIMIT 5];
        
        for(Account acc : accList) {
            acc.Phone = '9999999999';
        }
        
        if(!accList.isEmpty()){
            update accList;
        }
    }
}