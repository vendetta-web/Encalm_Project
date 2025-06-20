/**
* @File Name : UpdateClosingBalanceBatch.cls
* @Description : This batch will update the accounts closing balance
* @Author : Supriya Bassi
* @Last Modified By :
* @Last Modified On : June 18, 2025
* @Modification Log : // To query specific account balance key =Q and value= AccountNumber=120000104
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 18, 2025 |   | Initial Version
**/

global class UpdateClosingBalanceBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts  {

    // Store the oracle balances mapped by AccountNumber
    Map<String, Decimal> balanceMap = new Map<String, Decimal>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Fetch Accounts that have Oracle Account Numbers mapped
        return Database.getQueryLocator([
            SELECT Id,AccountNumber, Oracle_Closing_Balance__c
            FROM Account
            WHERE AccountNumber != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        if (balanceMap.isEmpty()) {
            fetchAccountBalancesFromOracle();
        }

        for (Account acc : scope) {
            if (balanceMap.containsKey(acc.AccountNumber)) {
                acc.Oracle_Closing_Balance__c = balanceMap.get(acc.AccountNumber);
            }
        }

        update scope;
    }

    global void finish(Database.BatchableContext bc) {
        // You can add logging or email here if needed
    }

    private void fetchAccountBalancesFromOracle() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Oracle_Closing_Balance/receivablesCustomerAccountActivities');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('respnse -->' +  res);

        if (res.getStatusCode() == 200) {
            OracleAccountWrapper wrapper = (OracleAccountWrapper) JSON.deserialize(res.getBody(), OracleAccountWrapper.class);

            for (OracleAccountWrapper.Item item : wrapper.items) {
                if (item.AccountNumber != null && item.TotalOpenReceivablesForAccount != null) {
                    balanceMap.put(item.AccountNumber, item.TotalOpenReceivablesForAccount);
                }
            }
        } else {
            System.debug('Failed to fetch Oracle balances: ' + res.getStatus());
        }
    }
}