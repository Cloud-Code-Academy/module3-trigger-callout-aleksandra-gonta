/**
 * Wrapper class for parsing the NewsAPI response
 */
public class NewsAPIResponse {
    // TODO: Define fields to match the NewsAPI response structure
    public String status { get; set; }
    public Integer totalResults { get; set; }
    public List<Article> articles { get; set; }
    
    /**
     * Inner class representing a news article
     */
     public class Article {
        public Source source;
        public String author;
        public String title;
        public String description;
        public String url;
        public String urlToImage;
        public String publishedAt;
        public String content;
        
        /**
         * Converts the API article to a Salesforce Article__c record
         * @return Article__c The Salesforce record
         */
        public Article__c toSObject(Id categoryId, String categoryName) {
            DateTime parsedPublishedAt = (DateTime)JSON.deserialize('"' + this.publishedAt + '"', DateTime.class);
            String[] titleWords = title.split(' ');
            String uniqueName = titleWords[0] + '_' + titleWords[1] + '_' + parsedPublishedAt.format('yyyy-MM-dd');
            Article__c articleObj = new Article__c();
            articleObj.name = uniqueName;
            articleObj.Source__c = source.name;
            articleObj.Author__c = this.author;   
            articleObj.Title__c = this.title.length() > 255 ? this.title.substring(0,255) : this.title;
            articleObj.Description__c = this.description.length() > 32768 ? this.description.substring(0,32768) : this.description;
            articleObj.Url__c = this.url;
            articleObj.UrlToImage__c = this.urlToImage != null && this.urlToImage.length() > 255 ? this.urlToImage.substring(0,255) : this.urlToImage;
            articleObj.Published_At__c = Datetime.valueOf(parsedPublishedAt);
            articleObj.Content__c = this.content;
            articleObj.News_Category__c = categoryId;
            articleObj.Category__c = categoryName;      
            
            return articleObj;
        }
    }
    
    /**
     * Inner class representing a news source
     */
    public class Source {
        public String id;
        public String name;
    }
    
    /**
     * Helper method to convert all articles in this response to Salesforce records
     * @return List<Article__c> List of Salesforce records
     */
    public List<Article__c> toSObjects(Id categoryId, String categoryName) {
        List<Article__c> articleObjList = new List<Article__c>();
        for (NewsAPIResponse.Article article : this.articles) {
            Article__c articleObj = article.toSObject(categoryId, categoryName);
            articleObjList.add(articleObj);
        }
        return articleObjList;
    }
} 