/**
 * Queueable Apex class for processing News Category records with pagination support
 */
public class NewsCategoryQueueable implements Queueable, Database.AllowsCallouts {
    private Id categoryId;
    private String categoryName;
    private Integer pages;
    private Integer currentPage;
    
    /**
     * Constructor
     * @param categoryId The Id of the News_Category__c record
     * @param categoryName The category name
     * @param pages Total pages to sync
     */
    public NewsCategoryQueueable(Id categoryId, String categoryName, Integer pages) {
        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.pages = pages;
        this.currentPage = 1; 
    }
    
    /**
     * Constructor with current page
     * @param categoryId The Id of the News_Category__c record
     * @param categoryName The category name
     * @param pages Total pages to sync
     * @param currentPage Current page being processed
     */
    public NewsCategoryQueueable(Id categoryId, String categoryName, Integer pages, Integer currentPage) {
        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.pages = pages;
        this.currentPage = currentPage;
    }
    
    /**
     * Execute method for the queueable job
     * @param context The QueueableContext
     */
    public void execute(QueueableContext context) {
            News_Category__c category = [SELECT Id, Name, Sync__c FROM News_Category__c WHERE Id = :categoryId LIMIT 1];
            NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(categoryName, pages, currentPage);
            List<Article__c> articlesToInsert = new List<Article__c>();
                
            articlesToInsert = response.toSObjects(categoryId);
            
            if (!articlesToInsert.isEmpty()) {
                insert articlesToInsert;
            }
    
            // Check if this is the last page
            if (currentPage < pages) {
                System.enqueueJob(new NewsCategoryQueueable(categoryId, categoryName, pages, currentPage + 1));
            } else {
                category.Last_Synced__c = System.now();
                update category;
            }
    }
}