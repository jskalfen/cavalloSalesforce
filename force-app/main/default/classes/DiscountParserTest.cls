@isTest
public class DiscountParserTest {
    @isTest
    static void testGetDurationType() {
        String manualDiscount = '[{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DGP00019","isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"10.00","discountAmount":null,"currency_code":"USD","cbId":"D_942110","apply_on":"specific_item_price","amount":null}]';

        List<String> input = new List<String>{ manualDiscount };
        List<String> result = DiscountParser.getDurationType(input);

        System.assertEquals(1, result.size());
        System.assertEquals('one-time', result[0]);
    }

    @isTest
    static void testInvalidJson() {
        String invalidManualDiscount = '[{"invalidJson":"value"}]';

        List<String> input = new List<String>{ invalidManualDiscount };
        List<String> result = DiscountParser.getDurationType(input);

        System.assertEquals(1, result.size());
        System.assertEquals(null, result[0]);
    }

    @isTest
    static void testEmptyDurationType() {
        String manualDiscountNoDurationType = '[{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DGP00019","isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":false,"id":null,"discountType":"PERCENTAGE","discountPercentage":"10.00","discountAmount":null,"currency_code":"USD","cbId":"D_942110","apply_on":"specific_item_price","amount":null}]';

        List<String> input = new List<String>{ manualDiscountNoDurationType };
        List<String> result = DiscountParser.getDurationType(input);

        System.assertEquals(1, result.size());
        System.assertEquals(null, result[0]);
    }
}