/**
 * Service class to interact with the NewsAPI for fetching top headlines
 */
public with sharing class NewsAPIService {
    // TODO: Define API endpoint constants
    private static final String API_NAMED_CREDENTIAL = 'callout:NewsAPI'; //https://newsapi.org
    private static final String API_ENDPOINT = '/v2/top-headlines';
    
    // TODO: Define default parameters
    private static final Integer DEFAULT_PAGE_SIZE = 20; 
    private static final Integer DEFAULT_PAGE = 1;
    
    /**
     * Fetches top headlines for a specified category with pagination support
     * @param category The news category (business, entertainment, general, health, science, sports, technology)
     * @param pageSize Number of results per page (default: 20, max: 100)
     * @param page Page number for pagination
     * @return NewsAPIResponse The wrapper object containing the API response
     */
    public static NewsAPIResponse getTopHeadlinesByCategory(String category, Integer pageSize, Integer page) {
        if (category == null) {
            throw new NewsAPIException('Category cannot be null or empty');
        }

        String endpoint = API_NAMED_CREDENTIAL + API_ENDPOINT + '?category=' + category;
        endpoint += '&pageSize=' + (pageSize != null ? pageSize : DEFAULT_PAGE_SIZE);
        endpoint += '&page=' + (page != null ? page : DEFAULT_PAGE);
        
        HttpResponse httpResponse = makeCallout(endpoint);
        NewsAPIResponse parsedResponse = parseResponse(httpResponse.getBody());

        return parsedResponse;
    }
    
    /**
     * Helper method to make the HTTP callout
     * @param endpoint The full URL with parameters
     * @return HttpResponse The HTTP response
     */
    private static HttpResponse makeCallout(String endpoint) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
              return response;
            }else{
               throw new NewsAPIException('Error: ' + response.getStatus() + ' - ' + response.getBody()); 
            }
        } catch (Exception e) {
            Logger.error( e.getMessage());
        } finally{
            Logger.saveLog(); 
        }

    }
    
    /**
     * Helper method to parse the JSON response
     * @param jsonResponse The JSON response string
     * @return NewsAPIResponse The parsed response object
     */
    public static NewsAPIResponse parseResponse(String jsonResponse) {
        try {
            return (NewsAPIResponse) JSON.deserialize(jsonResponse, NewsAPIResponse.class);
        } catch (System.JSONException e) {
            Logger.error('Failed to parse JSON response: ' + e.getMessage());
        }finally{
            Logger.saveLog(); 
        }
    }
    
    /**
     * Custom exception class for NewsAPI errors
     */
    public class NewsAPIException extends Exception {}
} 