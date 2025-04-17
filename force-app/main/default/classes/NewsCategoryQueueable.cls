/**
 * Queueable Apex class for processing News Category records with pagination support
 */
public class NewsCategoryQueueable implements Queueable, Database.AllowsCallouts {
    private static final Integer DEFAULT_PAGE_SIZE = 20; 
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
        List<Article__c> articlesToInsert = response.toSObjects(categoryId, categoryName);
                   
         if (!articlesToInsert.isEmpty()) {
                insert articlesToInsert;
            }

        Integer totalResults = response.totalResults;
        Integer totalPages = (Integer) Math.ceil((Decimal) totalResults / DEFAULT_PAGE_SIZE);
        this.pages = totalPages;

        if (currentPage < totalPages) {
            System.enqueueJob(new NewsCategoryQueueable(categoryId, categoryName, pages, currentPage + 1));
        } else {
            category.Last_Synced__c = System.now();
            category.Sync__c = false;
            update category;
        }

        List<News_Category__c> remainingCategories = [
            SELECT Id, Name 
            FROM News_Category__c 
            WHERE Sync__c = true
            LIMIT 1
        ];
            
        if (!remainingCategories.isEmpty()) {
            News_Category__c nextCategory = remainingCategories[0];
            System.enqueueJob(new NewsCategoryQueueable(nextCategory.Id, nextCategory.Name, 1));
        }
    }
}