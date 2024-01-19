public with sharing class MarketingCloudController {

    //Get relevant endpoint from Custom Metadata Type
    private static final Boolean isSandboxOrTest = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox || Test.isRunningTest();
    private static final String ENDPOINT_EMAIL_HISTORY = isSandboxOrTest ?
            Configuration__mdt.getInstance('SFMC_EndpointRequestData_Test').Value__c :
            Configuration__mdt.getInstance('SFMC_EndpointRequestData').Value__c;

    @AuraEnabled(cacheable=true)
    public static List<EmailHistory> getEmailHistory(String contactOrLeadId) {
        //Use existing class SFMC_ConnectionSet to get the token
        //Create payload
        //Create request using existing helper methods
        String token = SFMC_ConnectionSet.getAuthToken(true);
        String payload =
                        'token=' + EncodingUtil.urlEncode(token, 'UTF-8') +
                        '&operation=requestDataInternal' +
                        '&lookupBy=subscriberKey' +
                        '&subscriberKey=' + EncodingUtil.urlEncode(contactOrLeadId, 'UTF-8') +
                        '&history=true' +
                        '&historyPageSize=100' +
                        '&historyPage=1';

        HttpRequest request = SFMC_ConnectionSet.createRequest(ENDPOINT_EMAIL_HISTORY, payload);
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        HttpResponse response = SFMC_ConnectionSet.getResponse(request);

        //Parse response with wrapper
        List<EmailHistory> emailHistories = new List<EmailHistory>();
        if (response.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> userdata = (List<Object>)result.get('userdata');

            if(userdata.size() > 0){
                for (Object data : userdata) {
                    Map<String, Object> emailData = (Map<String, Object>)data;
                    EmailHistory emailHistory = parseEmailHistory(emailData);
                    emailHistories.add(emailHistory);
                }
            }
        }

        if(emailHistories.size() > 0){
            return emailHistories;
        }else{
            return null;
        }
    }

    @AuraEnabled(Cacheable=true)
    public static String getPreviewEmail(String previewUrl) {
        String token = SFMC_ConnectionSet.getAuthToken(true);
        HttpRequest request = SFMC_ConnectionSet.createRequest(previewUrl, '');
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setMethod('POST');
        try{
            HttpResponse response = SFMC_ConnectionSet.getResponse(request);
            if(response.getStatusCode() == 200) {
                Map<String, Object> temp1 = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Map<String, Object> temp2 = (Map<String, Object>) temp1.get('message');
                List<Object> temp3 = (List<Object>) temp2.get('views');
                Map<String, Object> temp4 = (Map<String, Object>) temp3[0];
                String result = (String) temp4.get('content');
                return result;
            }else if(response.getStatusCode() != 200){
                return 'Error: ' + response.getStatusCode() + ' - ' + 'Unabled to generate Preview';
            }
        }catch(Exception e){
            return 'Error: ' + e.getMessage();
        }
        return null;
    }

    public class EmailHistory {
        @AuraEnabled public String emailName;
        @AuraEnabled public String emailSubject;
        @AuraEnabled public DateTime dateSent;
        @AuraEnabled public DateTime dateOpened;
        @AuraEnabled public Boolean hardBounce;
        @AuraEnabled public Boolean softBounce;
        @AuraEnabled public Integer totalClicks;
        @AuraEnabled public DateTime dateUnsubscribed;
        @AuraEnabled public String previewURL;

        public EmailHistory(String emailName, String emailSubject, 
                            DateTime dateSent, DateTime dateOpened, 
                            Boolean hardBounce, Boolean softBounce, 
                            Integer totalClicks, DateTime dateUnsubscribed, 
                            String previewURL) {
            this.emailName = emailName;
            this.emailSubject = emailSubject;
            this.dateSent = dateSent;
            this.dateOpened = dateOpened;
            this.hardBounce = hardBounce;
            this.softBounce = softBounce;
            this.totalClicks = totalClicks;
            this.dateUnsubscribed = dateUnsubscribed;
            this.previewURL = previewURL;
        }
    }

    private static EmailHistory parseEmailHistory(Map<String, Object> data) {
        return new EmailHistory(
            (String) data.get('emailName'),
            (String) data.get('emailSubject'),
            parseDateTime((String) data.get('sentDateServertime')),
            parseDateTime((String) data.get('openDateServertime')),
            !((List<Object>) ((Map<String, Object>) data.get('bounces')).get('hardBounces')).isEmpty(),
            !((List<Object>) ((Map<String, Object>) data.get('bounces')).get('softBounces')).isEmpty(),
            (Integer) data.get('totalClicks'),
            parseDateTime((String) data.get('unsubDateServertime')),
            (String) data.get('previewUrl')
        );
    }

    public static DateTime parseDateTime(String dateString) {
        if(dateString != null && dateString != ''){
            try {
                // Split the date and time parts
                String[] dateTimeParts = dateString.split(' ');
                String[] dateParts = dateTimeParts[0].split('/');
                String[] timeParts = dateTimeParts[1].split(':');

                // Extract the date components
                Integer month = Integer.valueOf(dateParts[0]);
                Integer day = Integer.valueOf(dateParts[1]);
                Integer year = Integer.valueOf(dateParts[2]);

                // Extract the time components
                Integer hour = Integer.valueOf(timeParts[0]);
                Integer minute = Integer.valueOf(timeParts[1]);
                Integer second = Integer.valueOf(timeParts[2]);

                // Convert 12-hour clock to 24-hour clock if needed
                String ampm = dateTimeParts[2];
                if (ampm.equalsIgnoreCase('PM') && hour < 12) {
                    hour += 12;
                } else if (ampm.equalsIgnoreCase('AM') && hour == 12) {
                    hour = 0;
                }

                // Create a new DateTime instance
                DateTime dt = DateTime.newInstance(year, month, day, hour, minute, second);

                return dt;
            } catch (Exception e) {
                // Handle exceptions if the parsing or conversion fails
                System.debug('Error parsing DateTime: ' + e.getMessage());
                return null;
            }
        } else {
            return null;
        }
    }
}