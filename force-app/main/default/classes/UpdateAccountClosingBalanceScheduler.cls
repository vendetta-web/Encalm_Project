/**
* @File Name : UpdateAccountClosingBalanceScheduler.cls
* @Description :
* @Author : Supriya Bassi
* @Last Modified By :
* @Last Modified On : June 18, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 18, 2025 |   | Initial Version
**/

public class UpdateAccountClosingBalanceScheduler implements Schedulable {
	public void execute(SchedulableContext sc) {
        Database.executeBatch(new UpdateClosingBalanceBatch(), 50);
    }
}