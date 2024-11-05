/**
* @File Name : CSVFileReadLWCCntrl.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 22, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 22, 2024 |   | Initial Version
**/

public with sharing class CSVFileReadLWCCntrl {
	 @AuraEnabled
    public static list<Account> csvFileRead(Id contentDocumentId){
        list<Account> accountInsertList = new list<Account>();
        if(contentDocumentId != null) {
            
            // Fetch File Data based on the basic of document id 
            ContentVersion contentVersionObj = [SELECT Id, VersionData FROM ContentVersion WHERE ContentDocumentId =:contentDocumentId];
            // split the file data
            list<String> csvRecordsList = contentVersionObj.VersionData.toString().split('\n');

            for(Integer i = 1; i < csvRecordsList.size(); i++){
                Account accountObj = new Account();
                list<String> csvRowData = csvRecordsList[i].split(',');
                System.debug('csvRowData====> '+csvRowData);
                accountObj.Name = csvRowData[0]; // accName
                accountObj.AccountSource = csvRowData[1];
                accountObj.Site = csvRowData[2];
                accountObj.Type = csvRowData[3];
                accountObj.Website = csvRowData[4];
                accountInsertList.add(accountObj);
            }

            try{    
                if(!accountInsertList.isEmpty()) {
                    insert accountInsertList;
                }
            }
            catch (Exception ex) {
                throw new AuraHandledException(ex.getMessage());
            } 
        }
        return accountInsertList;    
    }
}