public class Utility_Class {
    
    public static String currencyStringFormatter(Decimal doubleValue){
        String currencyStringWithTrail = '';
        String currencyString = String.valueOf(doubleValue.format());
        if(!currencyString.contains('.')){
            currencyString = currencyString+'.00';
        }else if(currencyString.contains('.')){
          	currencyStringWithTrail = currencyString.subStringAfter('.');
            if(currencyStringWithTrail.length() == 1){
              currencyString = currencyString+'0';
            } 
        }
        return currencyString; 
    }
}