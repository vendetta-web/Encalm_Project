/**
* @File Name : OracleAccountWrapper .cls
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

public class OracleAccountWrapper {
    public List<Item> items;

    public class Item {
        public String AccountNumber;
        public Decimal TotalOpenReceivablesForAccount;
		public Decimal TotalTransactionsDueForAccount;
    }
}