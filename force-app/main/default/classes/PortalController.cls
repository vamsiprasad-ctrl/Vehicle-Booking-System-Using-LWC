public without sharing class PortalController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPortalStats() {
        Map<String, Object> stats = new Map<String, Object>();

        stats.put('activeModels', [
            SELECT COUNT() FROM Model__c
            WHERE Is_Active__c = true
        ]);

        stats.put('totalTestDrives', [
            SELECT COUNT() FROM Test_Drive__c
        ]);

        stats.put('totalCustomers', [
            SELECT COUNT() FROM Lead
            WHERE IsConverted = true
        ]);

        return stats;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getPortalCities() {
        List<String> cities = new List<String>();
        Schema.DescribeFieldResult fieldResult =
            Lead.Preferred_City__c.getDescribe();
        List<Schema.PicklistEntry> entries =
            fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                cities.add(entry.getValue());
            }
        }
        return cities;
    }
}