/**
* @File Name : AccountTrigger.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 4, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 4, 2024 |   | Initial Version
**/

public class AccountTrigger {
	@AuraEnabled
	Public static void LightningStudio(){
		System.debug('Lightning Studio');
	}
}