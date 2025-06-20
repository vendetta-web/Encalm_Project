public with sharing class CCAvenueInvoiceService {

    // Helper class to hold CCAvenue config values
    public class CCAvenueConfig {
        public String accessCode;
        public String workingKey;
        public String endpointUrl;
    }
    
    // Fetch values from Custom Metadata
    private static CCAvenueConfig getConfig() {
        CCAvenueConfig__mdt config = [
            SELECT Access_Code__c, Working_Key__c, Environment_URL__c 
            FROM CCAvenueConfig__mdt 
            LIMIT 1
        ];
        
        CCAvenueConfig ccConfig = new CCAvenueConfig();
        ccConfig.accessCode = config.Access_Code__c;
        ccConfig.workingKey = config.Working_Key__c;
        ccConfig.endpointUrl = config.Environment_URL__c;
        system.debug('ccConfig.accessCode: ' + ccConfig.accessCode);
        system.debug('ccConfig.workingKey: ' + ccConfig.workingKey);
        return ccConfig;
    }
    
    // Main method to create invoice
    public static String createInvoice(Map<String, Object> invoiceData) {
        CCAvenueConfig cfg = getConfig();
        
        // Encrypt invoice payload
        String plainJson = JSON.serialize(invoiceData);
        String encryptedRequest = CCAvenueCryptoService.encrypt(plainJson, cfg.workingKey);
        
        // Prepare callout body
        String body =  'enc_request=' + EncodingUtil.urlEncode(encryptedRequest, 'UTF-8') +
            //'6f40db0ae3e4375c7c92ba139913d8bad3abd6949592f89bce9c9e48fb26449d16cc93d9de52481644454e966baf7d357da3ad360fd0fcdc65d9c671ded68809b34c106d206ea7983afbb2d35681327c0000409f87f4f85281311517baab23cdd97a928340d6e53a5ea5f74b8d8869c49766f2f01ef8a6b266fa16d9f9dc100e42ca3d890926a895a7af42105b9ce8911ed6352c5ad1332d47608e99036b26bcab5f789e2d32dc5e729d5b1b7fa8f9aeaa5eab608ce62e9f64f9123f596470d2c8c158a1d0bfce7993eab02bc235eaf6139bc2f0ca63cf2792129738f8e2537862cda7a96c056f6cfcf2e4084a3c55dc7ccc05f87726c88ba8b27e9a120f4f425df355971591db0b7c69f65ae1754b757139baa4470a9705fa2c61132956b32cef95614610027c09df48ce996b6689bcd20576e9914c27264d363a65a085caf15dc29bec0eb460e503a88c765abd304ddf5dfc328f086f6f6d63a1241562e4b159b09541e3b794614442e8aad04caa452c18363eae993c3a10ef271a84d8186c3d49ba01ec369e93abf50e74fb91ff232be32180d602540e92d5503b9bcf87dd9fb3189a04c5e1819c34ff9816b77b27a095d15ae386ed310b1b165791499db4290e138b1de6f359fe27d5217fdeb0c7f8aa3f497d6e395c40c91716d49336043caef58ecb70b9d1898b1415a0a6981b84269baead81e6e69ab9ce24a75579d9e2960d2ec6e4dbfb03b7eb08af664d219a66dfb9fdccb0f3f4641b915c425393'
                      '&access_code=' + EncodingUtil.urlEncode(cfg.accessCode, 'UTF-8') +
                      '&request_type=JSON&command=generateQuickInvoice';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:CCAvenue_NC/apis/servlet/DoWebTrans');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        system.debug('body: ' + body);
        req.setBody(body);
        system.debug('req: ' + req);
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, String> resultMap = parseResponse(res.getBody());
            system.debug('res.getBody(): ' + res.getBody());
            if (resultMap.containsKey('enc_response')) {
                String decryptedResponse = CCAvenueCryptoService.decrypt(resultMap.get('enc_response'), cfg.workingKey);
                system.debug('decryptedResponse: ' + decryptedResponse);
                return decryptedResponse;
            } else {
                throw new CalloutException('No enc_response found in CCAvenue API response.');
            }
        } else {
            throw new CalloutException('CCAvenue callout failed: ' + res.getBody());
        }
    }
    
    // Helper method to parse URL-encoded response into Map
    private static Map<String, String> parseResponse(String responseBody) {
        Map<String, String> result = new Map<String, String>();
        for (String pair : responseBody.split('&')) {
            List<String> keyValue = pair.split('=');
            if (keyValue.size() == 2) {
                result.put(keyValue[0], keyValue[1]);
            }
        }
        return result;
    }
}