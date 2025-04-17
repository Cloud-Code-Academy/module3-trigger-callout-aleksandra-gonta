/**
 * Handler class for NewsCategoryTrigger
 */
public with sharing class NewsCategoryTriggerHandler {
    
    /**
     * Handles after insert events for News_Category__c
     * Uses Future method for callouts when Sync__c is true
     * @param newRecords List of newly inserted News_Category__c records
     */
    public static void handleInsert(List<News_Category__c> newRecords) {
        List<String> categoriesToSync = new List<String>();
        for (News_Category__c category : newRecords) {
            if (category.Sync__c && String.isNotBlank(category.Name)) {
                categoriesToSync.add(category.Name);
            }
        }
    
        if (!categoriesToSync.isEmpty()) {
            syncCategoriesWithFuture(categoriesToSync);
        }
    }
    
    /**
     * Handles after update events for News_Category__c
     * Uses Queueable Apex for callouts when Sync__c is true
     * @param newRecords List of updated News_Category__c records
     * @param oldMap Map of old record states
     */
    public static void handleUpdate(List<News_Category__c> newRecords, Map<Id, News_Category__c> oldMap) {
        List<News_Category__c> categoriesToSync = new List<News_Category__c>();
        
        for (News_Category__c category : newRecords) {
            Boolean oldSyncValue = oldMap.get(category.Id).Sync__c;
            Boolean newSyncValue = category.Sync__c;

            if (oldSyncValue != newSyncValue && newSyncValue == true ) {
                categoriesToSync.add(category);
            }
        }
    
        if (!categoriesToSync.isEmpty() ) {
            syncCategoriesWithQueueable(categoriesToSync);
        }
    }
    
    /**
     * Future method to sync categories using the NewsAPI
     * Used for insert operations
     * @param categoryNames List of category names to sync
     */
   @future(callout=true)
    public static void syncCategoriesWithFuture(List<String> categoryNames) {
        
        NewsAPIResponse response = null;
        List<Article__c> articlesToInsert = new List<Article__c>();
        List<News_Category__c> categoriesToUpdate = new List<News_Category__c>();
        if (categoryNames.isEmpty()) {
            return;
        }
        
        List<News_Category__c> categories = [
            SELECT Id, Name, Sync__c 
            FROM News_Category__c 
            WHERE Name IN :categoryNames
        ]; 
        
        if (categories.isEmpty()) {
            return;
        }

        for(News_Category__c category : categories) {

            if (Limits.getCallouts() < Limits.getLimitCallouts()) {
                if (!Test.IsRunningTest()) {
                    response = NewsAPIService.getTopHeadlinesByCategory(category.Name,3,1);
                } else {
                    response = NewsAPIService.parseResponse(NewsAPIMock.createSuccessMock().respond(new HttpRequest()).getBody());
                }
                List<Article__c> articles = response.toSObjects(category.Id, category.Name);
                articlesToInsert.addAll(articles);
                News_Category__c categoryToUpdate = new News_Category__c(Id = category.Id, Sync__c = false, Last_Synced__c = System.now());
                categoriesToUpdate.add(categoryToUpdate);
            }   
        }

        if (!articlesToInsert.isEmpty()) {
            insert articlesToInsert;
        }
        update categoriesToUpdate;
    }
    
    /**
     * Queueable method to sync categories using the NewsAPI
     * Used for update operations
     * @param categoriesToSync List of News_Category__c records to sync
     */
    private static void syncCategoriesWithQueueable(List<News_Category__c> categoriesToSync) {
        if (categoriesToSync == null || categoriesToSync.isEmpty()) {
            return;
        }
    
        News_Category__c category = categoriesToSync[0];
        System.enqueueJob(new NewsCategoryQueueable(category.Id, category.Name, 1));
    }
}