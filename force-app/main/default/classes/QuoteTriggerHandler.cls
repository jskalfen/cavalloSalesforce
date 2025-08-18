public with sharing class QuoteTriggerHandler {
    
    public static void beforeInsert(List<Quote> qtList){
        Set<Id> oppIDSet = new Set<Id>();
        String durationType = System.Label.Quote_Discount_Duration_Type;
        String periodUnit = System.Label.Quote_Discount_Period_Unit;
        String period = System.Label.Quote_Discount_Period;
        String discountPercentage = System.Label.Quote_Discount_Pecentage;
        String approvedStatus = System.Label.Quote_Status_Approved;
        Double termLength = 0.00;
        Boolean isDiscountForever = false;
        for(Quote qt: qtList){
            oppIDSet.add(qt.OpportunityId);
        }
        Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>([Select ID,Name,chargebeeapps__Manual_Discount__c From Opportunity Where ID In: oppIDSet]);
        for(Quote qt1: qtList){
            if(oppMap.get(qt1.OpportunityId).chargebeeapps__Manual_Discount__c != null){
                List<QuoteLineDiscount> qlManualDisList= getManualDiscount(oppMap.get(qt1.OpportunityId).chargebeeapps__Manual_Discount__c);
                for(QuoteLineDiscount qlDiscount:qlManualDisList){
                    System.debug('Discount forever:::'+qlDiscount.duration_type);
                    if(qlDiscount.duration_type != null && qlDiscount.duration_type.equalsIgnoreCase(System.Label.Quote_Discount_Duration_Type_Limited_Period) &&
                       qlDiscount.period_unit != null && qlDiscount.period != null){
                           Double lineTermLength = calculateTermLength(qlDiscount.duration_type,qlDiscount.period_unit, qlDiscount.period);
                           if(lineTermLength > termLength){
                               termLength = lineTermLength;   
                           }
                       }else if(qlDiscount.duration_type != null && qlDiscount.duration_type.equalsIgnoreCase(System.Label.Quote_Discount_Duration_Type_Forever)){
                           isDiscountForever = true;
                       }
                }
                qt1.Discount_Term_Length__c = termLength;
                qt1.Is_Discount_Forever__c = isDiscountForever;
            }
        }
    }
    
    public static List<QuoteLineDiscount> getManualDiscount(String mdString){
        List<QuoteLineDiscount> qlDiscountList = (List<QuoteLineDiscount>)JSON.deserialize(mdString,List<QuoteLineDiscount>.class);
        return qlDiscountList;
    }
    
    public static Double calculateTermLength(String durationType,String periodUnit, String period){
        Double termLength = 0.00;
        String periodUnitYear = System.Label.Quote_Discount_Period_Unit_Year;
        String periodUnitMonth = System.Label.Quote_Discount_Period_Unit_Month;
        String periodUnitWeek = System.Label.Quote_Discount_Period_Unit_Week;
        String periodUnitDay = System.Label.Quote_Discount_Period_Unit_Day;
        String discountDurationLimitedPeriod = System.Label.Quote_Discount_Duration_Type_Limited_Period;        
        Integer periodInt = integer.valueOf(period);
        if(durationType == discountDurationLimitedPeriod){
            if(periodUnit == periodUnitYear){
                termLength = (Double)periodInt;
            }else if(periodUnit == periodUnitMonth && periodInt > 12){
                termLength = (Double)periodInt/(Double)12;
            }else if(periodUnit == periodUnitWeek && periodInt > 52){
                termLength = (Double)periodInt/(Double)52;
            }else if(periodUnit == periodUnitDay && periodInt > 365){
                termLength = (Double)periodInt/(Double)365;
            }else{
                termLength = (Double)periodInt;
            }
        }
        return termLength;
    }
    
}