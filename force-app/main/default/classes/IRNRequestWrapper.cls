public class IRNRequestWrapper {
    public TransactionWrapper transactionWrap;
   // public CustomFields custom_fields;

    public class TransactionWrapper {
        public String Version;
        public TransactionDtls TranDtls;
        public DocumentDtls DocDtls;
        public SellerDtls SellerDtls;
        public BuyerDtls BuyerDtls;
       // public DispatchFromDtls DispDtls;
        //public ShipToDtls ShipDtls;
        public List<ItemList> ItemList;
        public ValueDtls ValDtls;
      /*  public PaymentDtls PayDtls;
        public ReferenceDtls RefDtls;
        public List<AdditionalDocDtls> AddlDocDtls;
        public ExportDtls ExpDtls;
        public EWayBillDtls EwbDtls;*/
    }

    public class TransactionDtls {
        public String TaxSch;
        public String SupTyp;
        public String RegRev; //Optional 
       // public String EcmGstin; //Optional 
        public String IgstOnIntra;
    }

    public class DocumentDtls {
        public String Typ;
        public String No;
        public String Dt;
    }

    public class SellerDtls {
        public String Gstin;
        public String LglNm;
       // public String TrdNm; //Optional
        public String Addr1;
       // public String Addr2; //Optional
        public String Loc;
        public Integer Pin;
        public String Stcd;
       // public String Ph; //Optional
       // public String Em; //Optional
    }

    public class BuyerDtls {
        public String Gstin;
        public String LglNm;
       // public String TrdNm;
        public String Pos;
        public String Addr1;
      //  public String Addr2;
        public String Loc;
        public Integer Pin;
        public String Stcd;
      //  public String Ph;
      //  public String Em;
    }

  /*  public class DispatchFromDtls {
        public String Nm;
        public String Addr1;
        public String Addr2;
        public String Loc;
        public Integer Pin;
        public String Stcd;
    }

    public class ShipToDtls {
        public String Gstin;
        public String LglNm;
        public String TrdNm;
        public String Addr1;
        public String Addr2;
        public String Loc;
        public Integer Pin;
        public String Stcd;
    }*/

    public class ItemList {
        public String SlNo;
        public String PrdDesc;
        public String IsServc;
        public String HsnCd;
       // public String Barcde;
        public Decimal Qty;
       // public Decimal FreeQty;
       // public String Unit;
        public Decimal UnitPrice;
        public Decimal TotAmt;
        public Decimal Discount;
       // public Decimal PreTaxVal;
        public Decimal AssAmt;
        public Decimal GstRt;
        public Decimal IgstAmt;
        public Decimal CgstAmt;
        public Decimal SgstAmt;
       /* public Decimal CesRt;
        public Decimal CesAmt;
        public Decimal CesNonAdvlAmt;
        public Decimal StateCesRt;
        public Decimal StateCesAmt;
        public Decimal StateCesNonAdvlAmt;
        public Decimal OthChrg;*/
        public Decimal TotItemVal;
        /*public String OrdLineRef;
        public String OrgCntry;
        public String PrdSlNo;*/
        //public BatchDtls BchDtls;
        //public List<AttributeDtls> AttribDtls;
    }

    /*public class BatchDtls {
        public String Nm;
        public String ExpDt;
        public String WrDt;
    }

    public class AttributeDtls {
        public String Nm;
        public String Val;
    }*/

    public class ValueDtls {
        public Decimal AssVal;
        public Decimal CgstVal;
        public Decimal SgstVal;
        public Decimal IgstVal;
      //  public Decimal CesVal;
      //  public Decimal StCesVal;
        public Decimal Discount;
      //  public Decimal OthChrg;
      //  public Decimal RndOffAmt;
        public Decimal TotInvVal;
      //  public Decimal TotInvValFc;
    }

   /* public class PaymentDtls {
        public String Nm;
        public String AccDet;
        public String Mode;
        public String FinInsBr;
        public String PayTerm;
        public String PayInstr;
        public String CrTrn;
        public String DirDr;
        public Integer CrDay;
        public Decimal PaidAmt;
        public Decimal PaymtDue;
    }

    public class ReferenceDtls {
        public String InvRm;
        public DocPeriodDtls DocPerdDtls;
        public List<PrecDocDtls> PrecDocDtls;
        public List<ContractDtls> ContrDtls;
    }

    public class DocPeriodDtls {
        public String InvStDt;
        public String InvEndDt;
    }

    public class PrecDocDtls {
        public String InvNo;
        public String InvDt;
        public String OthRefNo;
    }

    public class ContractDtls {
        public String RecAdvRefr;
        public String RecAdvDt;
        public String TendRefr;
        public String ContrRefr;
        public String ExtRefr;
        public String ProjRefr;
        public String PORefr;
        public String PORefDt;
    }

    public class AdditionalDocDtls {
        public String Url;
        public String Docs;
        public String Info;
    }

    public class ExportDtls {
        public String ShipBNo;
        public String ShipBDt;
        public String Port;
        public String RefClm;
        public String ForCur;
        public String CntCode;
    }

    public class EWayBillDtls {
        public String TransId;
        public String TransName;
        public Decimal Distance;
        public String TransDocNo;
        public String TransDocDt;
        public String VehNo;
        public String VehType;
        public String TransMode;
    }

    public class CustomFields {
        public String customfieldLable1;
        public String customfieldLable2;
        public String customfieldLable3;
    }*/
}