@isTest
private class GetRecordsInCollectionTest {
    
    @testSetup
    static void testSetup(){
        List <Account> accounts = new List <Account> ();
        for (integer i = 1; i <= 8; i++){
            Account account = new Account (Name = 'account ' + i,
                                 AccountNumber = '123');
            accounts.add(account);
        }
        accounts[0].site = 'US';
        accounts[1].site = 'US';
        accounts[2].site = 'US';
        accounts[3].site = 'CA';
        accounts[4].site = 'CA';
        accounts[5].site = 'UK';
        accounts[6].site = 'UK';
        
        insert accounts;
    }
    
    @IsTest
    static void testSetup_HasEightAccounts() {
        List <Account> accountList = [SELECT Id FROM Account WHERE AccountNumber = '123'];
        System.assertEquals(8, accountList.size(),'Should insert 8 accounts');
    }
    
    @IsTest
    static void getRecords_AccountsInUS_Three() {
        List<String> validTextCollection = new List <String> {'US'};
        List <GetRecordsInCollection.FlowInput> inputList = prepSingleInputList('Account','Site',validTextCollection);
        List <Account> accountList = GetRecordsInCollection.GetRecordsInCollection(inputList)[0].matchingRecords;
        System.assertEquals(3, accountList.size(),'Should find 3 accounts with site: US');
    }
    
    @IsTest
    static void getRecords_AccountsWithHotOrWarmRating_Three() {
        List<String> validTextCollection = new List <String> {'US','CA'};
        List <GetRecordsInCollection.FlowInput> inputList = prepSingleInputList('Account','Site',validTextCollection);
        List <Account> accountList = GetRecordsInCollection.GetRecordsInCollection(inputList)[0].matchingRecords;
        System.assertEquals(5, accountList.size(),'Should find 5 accounts with rating: hot or warm');
    }
    
    @IsTest
    static void getRecords_InvalidObject_ThrowError() {
        List<String> validTextCollection = new List <String> {'US','CA'};
        List <GetRecordsInCollection.FlowInput> inputList = prepSingleInputList('Nothing','No_Field__c',validTextCollection);
        Boolean hasError = false;
        try{
            List <Account> accountList = GetRecordsInCollection.GetRecordsInCollection(inputList)[0].matchingRecords;
        } catch (IllegalArgumentException e){
            hasError = true;
        }
        System.assert(hasError,'Should throw an exception if the object is invalid');
    }
    
    // private method to simplify creating FlowInput records for tests
    private static List <GetRecordsInCollection.FlowInput> prepSingleInputList (String objectName,  String bindField, List<String> validTextCollection){
        GetRecordsInCollection.FlowInput input = new GetRecordsInCollection.FlowInput();
        input.objectName = objectName;
        input.returnFields = new List<String> {'Id','AccountNumber'};
        input.bindField = bindField;
        input.validTextCollection = validTextCollection;        
        List<GetRecordsInCollection.FlowInput> inputs = new List <GetRecordsInCollection.FlowInput> {input};
        return inputs;
    }
    
    // here starts bulkified testing
    
    @IsTest
    static void getRecords_MultipleDifferentObjects_ThrowError() {
        GetRecordsInCollection.FlowInput input = new GetRecordsInCollection.FlowInput();
        input.objectName = 'Account';
        input.returnFields = new List<String> {'Id','Site'};
        input.bindField = 'AccountNumber';
        input.validTextCollection = new List<String> {'US','CA'};        

        GetRecordsInCollection.FlowInput input2 = input.clone();
        input2.objectName = 'Contact';
        
        List <GetRecordsInCollection.FlowInput> inputList = new List <GetRecordsInCollection.FlowInput> {input, input2};
        Boolean hasError = false;
        try{
            List <Account> accountList = GetRecordsInCollection.GetRecordsInCollection(inputList)[0].matchingRecords;
        } catch (IllegalArgumentException e){
            hasError = true;
        }
        System.assert(hasError,'Should throw an exception if batched requests reference different objects');
    }
    
    @IsTest
    static void getRecords_MultipleRequests_OneSOQL() {
        GetRecordsInCollection.FlowInput input = new GetRecordsInCollection.FlowInput();
        input.objectName = 'Account';
        input.returnFields = new List<String> {'Id','AccountNumber'};
        input.bindField = 'Site';
        input.validTextCollection = new List<String> {'US','CA'};        
        GetRecordsInCollection.FlowInput input2 = input.clone();
        List <GetRecordsInCollection.FlowInput> inputList = new List <GetRecordsInCollection.FlowInput> {input, input2};
        Test.startTest();
        List <GetRecordsInCollection.FlowOutput> flowOutputs = GetRecordsInCollection.GetRecordsInCollection(inputList);
        Integer numQueries = Limits.getQueries();
        Test.stopTest();
        System.assertEquals(1, numQueries,'Should execute one query even with multiple requests');
    }
        
    @IsTest
    static void getRecords_MultipleBindFields_OneSOQLAndCorrectValues() {
        GetRecordsInCollection.FlowInput input = new GetRecordsInCollection.FlowInput();
        input.objectName = 'Account';
        input.returnFields = new List<String> {'Id','AccountNumber'};
        input.bindField = 'Site';
        input.validTextCollection = new List<String> {'US','CA'};        

        GetRecordsInCollection.FlowInput input2 = input.clone();
        input2.bindField = 'AccountNumber';
        input2.validTextCollection = new List <String> {'123','nothing'};
        
        List <GetRecordsInCollection.FlowInput> inputList = new List <GetRecordsInCollection.FlowInput> {input, input2};
        Test.startTest();
        List <GetRecordsInCollection.FlowOutput> flowOutputs = GetRecordsInCollection.GetRecordsInCollection(inputList);
        Integer numQueries = Limits.getQueries();
        System.assertEquals(1, numQueries,'Should execute one query even with multiple requests');
    	  GetRecordsInCollection.FlowOutput firstResult = flowOutputs[0];
        GetRecordsInCollection.FlowOutput secondResult = flowOutputs[1];
        System.assertEquals(5, firstResult.matchingRecords.size(), 'Should find 5 accounts with site US or CA');
        System.assertEquals(8, secondResult.matchingRecords.size(), 'Should find 8 accounts with Account Number: 123');
        Test.stopTest();
    }
    
}
