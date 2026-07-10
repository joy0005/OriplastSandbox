/**
 * @description       : This will replace the JSON  received by the tally integration
 * @author            : D. K. Sinha
 * @group             :
 * @last modified on  : 05-04-2024
 * @last modified by  : 
 **/
public with sharing class TallyJsonDataObject {
    public String Distributor                          {set;get;}
    public String DistributorIdentificationKey         {set;get;}
    public List<InvoiceDetails> invoiceDetails         {set;get;}
  
    public class InvoiceDetails {
        // ** invoiceNumber has unique value
        public String InvoiceNumber                   {set;get;} 
        public String InvoiceDate                     {set;get;}
        public String InvoiceStatus                   {set;get;}
        public DealerDetails DealerDetails            {set;get;}
        public List<InvoiceLineItem> invoiceLineItems {set;get;}
    }
    
    public class DealerDetails {
        public String Name                        {set;get;}
        /*public String gst                         {set;get;}
        public String state                        {set;get;}
        public String billingAddress              {set;get;}
        public String dealerIdentificationKey     {set;get;}*/
    }
   
    public class InvoiceLineItem {
        //public String description                 {set;get;}
        public String SKU                         {set;get;}
        public Decimal Quantity                   {set;get;}
        public String UnitofMeasure               {set;get;}
        public Decimal Rate                       {set;get;}
        // public Decimal tradeDiscount              {set;get;}
        // public Decimal tradeDiscountPercentage    {set;get;}
        // public Decimal cashDiscount               {set;get;}
        // public Decimal cashDiscountPercentage     {set;get;}
        // public Decimal totalDiscount              {set;get;}
        public Decimal TotalDiscountPercentage     {set;get;}
        /*public Decimal cgst                       {set;get;}
        public Decimal cgstPercentage             {set;get;}
        public Decimal sgst                       {set;get;}
        public Decimal sgstPercentage             {set;get;}
        public Decimal igst                       {set;get;}
        public Decimal igstPercentage             {set;get;}*/
        public Decimal FinalPrice                 {set;get;}
    } 

}