@isTest
public class Utility_Class_Test {
    
    @isTest
    static void testCurrencyStringFormatter() {
        Decimal value1 = 123;
        String result1 = Utility_Class.currencyStringFormatter(value1);
        System.assertEquals('123.00', result1, 'Test Case 1 Failed');
        
        Decimal value2 = 123.4;
        String result2 = Utility_Class.currencyStringFormatter(value2);
        System.assertEquals('123.40', result2, 'Test Case 2 Failed');
        
        Decimal value3 = 123.45;
        String result3 = Utility_Class.currencyStringFormatter(value3);
        System.assertEquals('123.45', result3, 'Test Case 3 Failed');
        
        Decimal value5 = 0;
        String result5 = Utility_Class.currencyStringFormatter(value5);
        System.assertEquals('0.00', result5, 'Test Case 5 Failed');
        
        Decimal value6 = 123456789.12;
        String result6 = Utility_Class.currencyStringFormatter(value6);
        System.assertEquals('123,456,789.12', result6, 'Test Case 6 Failed');
    }
}