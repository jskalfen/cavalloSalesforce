public class DiscountParser {
    @InvocableMethod(label='Get Duration Type' description='Parses the duration_type from Manual Discount JSON')
    public static List<String> getDurationType(List<String> manualDiscountList) {
        List<String> result = new List<String>();
        for(String manualDiscount : manualDiscountList) {
            try {
                List<Object> discountData = (List<Object>) JSON.deserializeUntyped(manualDiscount);
                Map<String, Object> discountMap = (Map<String, Object>) discountData[0];
                String durationType = (String) discountMap.get('duration_type');
                if(durationType != null) {
                    durationType = durationType.replace('_', '-');
                }
                result.add(durationType);
            } catch (Exception e) {
                result.add(null);
            }
        }
        return result;
    }
}