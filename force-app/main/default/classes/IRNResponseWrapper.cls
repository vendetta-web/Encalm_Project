public class IRNResponseWrapper {
    public List<IRNResponse> responses;

    public class IRNResponse {
        public Boolean deleted;
        public String document_status;
        public String error_response;
        public String errors;
        public GovtResponse govt_response;
        public String group_id;
        public String gstin;
        public Boolean is_deleted;
        public String owner_id;
        public String tag_identifier;
        public TransactionDtls transDtls;
        public String transaction_id;
        public String transaction_metadata;
    }

    public class GovtResponse {
        public String Success;
        public Long AckNo;
        public String AckDt;
        public String Irn;
        public String SignedInvoice;
        public String SignedQRCode;
        public String Status;
        public Long EwbNo;
        public String EwbDt;
        public String EwbValidTill;
    }

    public class TransactionDtls {
        public String Version;
        public TranDtls TranDtls;
        public DocDtls DocDtls;
        public PartyDtls SellerDtls;
        public PartyDtls BuyerDtls;
        public PartyDtls DispDtls;
        public PartyDtls ShipDtls;
        public List<ItemList> ItemList;
        public ValDtls ValDtls;
        public EwbDtls EwbDtls;
    }

    public class TranDtls {
        public String TaxSch;
        public String RegRev;
        public String SupTyp;
    }

    public class DocDtls {
        public String Typ;
        public String No;
        public String Dt;
    }

    public class PartyDtls {
        public String Gstin;
        public String LglNm;
        public String TrdNm;
        public String Addr1;
        public String Addr2;
        public String Loc;
        public Integer Pin;
        public String Stcd;
    }

    public class ItemList {
        public String SlNo;
        public String PrdDesc;
        public String IsServc;
        public String HsnCd;
        public Decimal Qty;
        public Decimal FreeQty;
        public String Unit;
        public Decimal UnitPrice;
        public Decimal TotAmt;
        public Decimal Discount;
        public Decimal AssAmt;
        public Decimal GstRt;
        public Decimal IgstAmt;
        public Decimal CgstAmt;
        public Decimal SgstAmt;
        public Decimal CesRt;
        public Decimal CesAmt;
        public Decimal CesNonAdvlAmt;
        public Decimal StateCesRt;
        public Decimal StateCesAmt;
        public Decimal StateCesNonAdvlAmt;
        public Decimal OthChrg;
        public Decimal TotItemVal;
    }

    public class ValDtls {
        public Decimal AssVal;
        public Decimal CgstVal;
        public Decimal SgstVal;
        public Decimal IgstVal;
        public Decimal CesVal;
        public Decimal StCesVal;
        public Decimal Discount;
        public Decimal OthChrg;
        public Decimal RndOffAmt;
        public Decimal TotInvVal;
        public Decimal TotInvValFc;
    }

    public class EwbDtls {
        public String TransId;
        public String TransName;
        public String TransMode;
        public Integer Distance;
        public String TransDocNo;
        public String TransDocDt;
        public String VehNo;
        public String VehType;
    }

    public static List<IRNResponseWrapper.IRNResponse> parse(String jsonString) {
        
        List<IRNResponseWrapper.IRNResponse> parsedResponse = (List<IRNResponseWrapper.IRNResponse>) JSON.deserialize(jsonString, List<IRNResponseWrapper.IRNResponse>.class);
        return parsedResponse;

    }
}