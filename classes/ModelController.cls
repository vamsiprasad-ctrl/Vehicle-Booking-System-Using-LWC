public without sharing class ModelController {

    @AuraEnabled(cacheable=true)
    public static List<Model__c> getActiveModels() {
        return [
            SELECT Id, Name, Description__c, Image_URL__c
            FROM Model__c
            WHERE Is_Active__c = true
            ORDER BY Name ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Variant__c> getVariantsByModel(Id modelId) {
        return [
            SELECT Id, Name, Price__c, Fuel_Type__c,
                   Transmission__c, Color_Options__c, Image_URL__c
            FROM Variant__c
            WHERE Model__c = :modelId
            ORDER BY Price__c ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Model__c getModelById(Id modelId) {
        return [
            SELECT Id, Name, Description__c, Image_URL__c
            FROM Model__c
            WHERE Id = :modelId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCitiesByModel(Id modelId) {
        List<String> cityList = new List<String>();
        try {
            List<Model__c> models = [
                SELECT Id, Available_Cities__c
                FROM Model__c
                WHERE Id = :modelId
                LIMIT 1
            ];
            if (!models.isEmpty() &&
                !String.isBlank(models[0].Available_Cities__c)) {
                List<String> raw = models[0].Available_Cities__c.split(',');
                for (String city : raw) {
                    String trimmed = city.trim();
                    if (!String.isBlank(trimmed)) cityList.add(trimmed);
                }
                cityList.sort();
            }
        } catch (Exception e) {
            System.debug('getCitiesByModel error: ' + e.getMessage());
        }
        return cityList;
    }

    @AuraEnabled(cacheable=true)
    public static List<ModelWithVariants> getActiveModelsWithVariants() {
        List<Model__c> models = [
            SELECT Id, Name, Description__c, Image_URL__c,
                   (SELECT Id, Name, Price__c, Fuel_Type__c, Transmission__c
                    FROM Variants__r
                    ORDER BY Price__c ASC)
            FROM Model__c
            WHERE Is_Active__c = true
            ORDER BY Name ASC
        ];

        List<ModelWithVariants> result = new List<ModelWithVariants>();
        for (Model__c m : models) {
            ModelWithVariants mwv = new ModelWithVariants();
            mwv.id           = m.Id;
            mwv.name         = m.Name;
            mwv.description  = m.Description__c;
            mwv.imageUrl     = m.Image_URL__c;
            mwv.variantCount = m.Variants__r.size();
            if (!m.Variants__r.isEmpty()) {
                mwv.startingPrice = m.Variants__r[0].Price__c;
                mwv.fuelType      = m.Variants__r[0].Fuel_Type__c;
                mwv.transmission  = m.Variants__r[0].Transmission__c;
            }
            result.add(mwv);
        }
        return result;
    }

    public class ModelWithVariants {
        @AuraEnabled public String  id;
        @AuraEnabled public String  name;
        @AuraEnabled public String  description;
        @AuraEnabled public String  imageUrl;
        @AuraEnabled public Decimal startingPrice;
        @AuraEnabled public String  fuelType;
        @AuraEnabled public String  transmission;
        @AuraEnabled public Integer variantCount;
    }
}