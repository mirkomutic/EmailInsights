@IsTest
private class MarketingCloudControllerTest {

    private static final String AUTH_ENDPOINT = Configuration__mdt.getInstance('SFMC_Endpoint_Auth').Value__c;
    private static final String REQUEST_DATA_ENDPOINT = Configuration__mdt.getInstance('SFMC_EndpointRequestData_Test').Value__c;
    private static final String PREVIEW_EMAIL_ENDPOINT = 'https://mcqk1-pt73plx40hd2kd2lkc-5by.rest.marketingcloudapis.com/guide/v1/emails/31666/dataExtension/key:personMaster/contacts/key:0030700000rTrbrAAC/preview?kind=html';

    // Inner class to handle multiple callout mocks
    private class MultiMockHttpCallout implements HttpCalloutMock {
        // Map to hold the endpoint URL and corresponding mock response
        private Map<String, HttpResponse> mockResponses = new Map<String, HttpResponse>();

        // Method to add mock responses
        public void addMockResponse(String endpoint, HttpResponse response) {
            mockResponses.put(endpoint, response);
        }

        // Implementing interface method
        public HttpResponse respond(HttpRequest request) {
            // Determine the response based on the request endpoint
            HttpResponse response = mockResponses.get(request.getEndpoint());
            if (response != null) {
                return response;
            }

            // Default response if no match found
            HttpResponse defaultResponse = new HttpResponse();
            defaultResponse.setStatusCode(404);
            defaultResponse.setBody('No mock response set for this endpoint');
            return defaultResponse;
        }
    }

    @IsTest
    private static void getEmailHistory_Test() {
        // Set Multi Mock
        setMultiMock();

        Test.startTest();
        List<MarketingCloudController.EmailHistory> emailHistories =
        MarketingCloudController.getEmailHistory('0030700000rTrbrAAC');
        Test.stopTest();

        // Assert results
        Assert.areNotEqual(null, emailHistories, 'The email history should not be null');
        Assert.areNotEqual(0, emailHistories.size(), 'The email history should not be null');
        Assert.areEqual(1, emailHistories.size(), 'The email history should have 1 item');
    }

    @IsTest
    private static void getPreviewEmail_Test() {
        // Set Multi Mock
        setMultiMock();

        Test.startTest();
        String emailPreview =
                MarketingCloudController.getPreviewEmail('https://mcqk1-pt73plx40hd2kd2lkc-5by.rest.marketingcloudapis.com/guide/v1/emails/31666/dataExtension/key:personMaster/contacts/key:0030700000rTrbrAAC/preview?kind=html');
        Test.stopTest();

        // Assert results
        Assert.areEqual(emailPreview, 'This is a sample HTML');
    }

    private static void setMultiMock(){
        MultiMockHttpCallout multiMock = new MultiMockHttpCallout();

        HttpResponse authMockResponse = new HttpResponse();
        authMockResponse.setStatusCode(200);
        authMockResponse.setBody(getAuthResponseBodyString());
        multiMock.addMockResponse(AUTH_ENDPOINT, authMockResponse);

        HttpResponse requestDataMockResponse = new HttpResponse();
        requestDataMockResponse.setStatusCode(200);
        requestDataMockResponse.setBody(getRequestDataResponseBodyString());
        multiMock.addMockResponse(REQUEST_DATA_ENDPOINT, requestDataMockResponse);

        HttpResponse previewEmailMockResponse = new HttpResponse();
        previewEmailMockResponse.setStatusCode(200);
        previewEmailMockResponse.setBody(getPreviewEmailBodyString());
        multiMock.addMockResponse(PREVIEW_EMAIL_ENDPOINT, previewEmailMockResponse);

        Test.setMock(HttpCalloutMock.class, multiMock);
    }

    public static String getAuthResponseBodyString(){
        Map<String, Object> authResponseBodyMap = new Map<String, Object>{
                'access_token' => 'randomToken',
                'expires_in' => 1080
        };
        return JSON.serialize(authResponseBodyMap);
    }

    public static String getRequestDataResponseBodyString(){
        Map<String, Object> requestDataResponseMap = new Map<String, Object>{
                'status' => 'ok',
                'message' => 'dataRetrieved',
                'details' => 'en_GB',
                'userdata' => new List<Object>{
                        new Map<String, Object>{
                                'systemType' => 'history',
                                'requestStatus' => 'ok',
                                'jobid' => '283634',
                                'trackingId' => '',
                                'emailName' => 'KTCHNrebel_Newsletter_12_2023',
                                'sentDateServertime' => '12/22/2023 2:30:51 AM',
                                'openDateServertime' => '12/22/2023 9:00:48 AM',
                                'bounces' => new Map<String, Object>{
                                        'hardBounces' => new List<Object>(),
                                        'softBounces' => new List<Object>(),
                                        'unknownBounces' => new List<Object>()
                                },
                                'totalClicks' => 0,
                                'unsubDateServertime' => '',
                                'emailSubject' => 'Elevate Your Culinary Skills!',
                                'emailId' => '32167',
                                'previewUrl' => 'https://mcqk1-pt73plx40hd2kd2lkc-5by.rest.marketingcloudapis.com/guide/v1/emails/31666/dataExtension/key:personMaster/contacts/key:0030700000rTrbrAAC/preview?kind=html'
                        }
                }
        };
        return JSON.serialize(requestDataResponseMap);
    }

    public static String getPreviewEmailBodyString(){
        Map<String, Object> previewEmailBodyMap = new Map<String, Object>{
                'message' => new Map<String, Object>{
                        'links' => new Map<String, Object>{
                                'self' => new Map<String, Object>{
                                        'href' => '/v1/emails/31666/dataExtension/5e377164-825e-ed11-b877-f40343c958a0/row/3/preview'
                                }
                        },
                        'views' => new List<Object>{
                                new Map<String, Object>{
                                        'contentType' => 'vnd.exacttarget.message.email.htmlBody',
                                        'content' => 'This is a sample HTML'
                                }
                        }
                }
        };
        return JSON.serialize(previewEmailBodyMap);
    }
}