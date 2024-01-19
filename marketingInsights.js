import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

//Apex Methods
import getEmailHistory from '@salesforce/apex/MarketingCloudController.getEmailHistory';
import getPreviewEmail from '@salesforce/apex/MarketingCloudController.getPreviewEmail';

//Custom Labels
import SFMC_EmailInsights_EmailName from '@salesforce/label/c.SFMC_EmailInsights_EmailName';
import SFMC_EmailInsights_EmailSubject from '@salesforce/label/c.SFMC_EmailInsights_EmailSubject';
import SFMC_EmailInsights_DateSent from '@salesforce/label/c.SFMC_EmailInsights_DateSent';
import SFMC_EmailInsights_DateOpened from '@salesforce/label/c.SFMC_EmailInsights_DateOpened';
import SFMC_EmailInsights_HardBounce from '@salesforce/label/c.SFMC_EmailInsights_HardBounce';
import SFMC_EmailInsights_SoftBounce from '@salesforce/label/c.SFMC_EmailInsights_SoftBounce';
import SFMC_EmailInsights_TotalClicks from '@salesforce/label/c.SFMC_EmailInsights_TotalClicks';
import SFMC_EmailInsights_DateUnsubscribed from '@salesforce/label/c.SFMC_EmailInsights_DateUnsubscribed';
import SFMC_EmailInsights_PreviewURL from '@salesforce/label/c.SFMC_EmailInsights_PreviewURL';


export default class MarketingInsights extends LightningElement {
    @api recordId;
    emailHistoryData;
    isLoading = true;

    //Pagination
    page = 1;
    itemsPerPage = 10;
    totalRecords;
    isPrevDisabled = true;
    isNextDisabled = true;
    paginatedData = [];

    //Email Preview Modal
    isModalOpen = false;
    htmlContent = '';

    //Email History Table
    tableColumns = [
        { label: SFMC_EmailInsights_EmailName, fieldName: 'emailName' },
        { label: SFMC_EmailInsights_EmailSubject, fieldName: 'emailSubject' },
        { label: SFMC_EmailInsights_DateSent, fieldName: 'dateSent', type: 'date' },
        { label: SFMC_EmailInsights_DateOpened, fieldName: 'dateOpened', type: 'date' },
        { label: SFMC_EmailInsights_HardBounce, fieldName: 'hardBounce', type: 'boolean' },
        { label: SFMC_EmailInsights_SoftBounce, fieldName: 'softBounce', type: 'boolean' },
        { label: SFMC_EmailInsights_TotalClicks, fieldName: 'totalClicks', type: 'number' },
        { label: SFMC_EmailInsights_DateUnsubscribed, fieldName: 'dateUnsubscribed', type: 'date' },
        {
            label: SFMC_EmailInsights_PreviewURL,
            type: 'button',
            typeAttributes: {
                label: 'Preview',
                name: 'preview_url',
                variant: 'base'
            }
        }
    ];

    @wire(getEmailHistory, { contactOrLeadId: '$recordId' })
    wiredEmailHistory({ error, data }) {
        if (data) {
            this.isLoading = false;
            this.emailHistoryData = data.map(record => {
                return {
                    id: record.recordId,
                    emailName: record.emailName,
                    emailSubject: record.emailSubject,
                    dateSent: record.dateSent,
                    dateOpened: record.dateOpened,
                    hardBounce: record.hardBounce,
                    softBounce: record.softBounce,
                    totalClicks: record.totalClicks,
                    dateUnsubscribed: record.dateUnsubscribed,
                    previewURL: record.previewURL
                };
            });
            this.totalRecords = this.emailHistoryData.length;
            this.paginateData();
            this.updatePaginationButtons();
        } else if (error) {
            this.emailHistoryData = undefined;
            this.isLoading = false;
            this.showErrorToast('An error occurred: ' + error.message)
        } else if (data === null) {
            this.emailHistoryData = undefined;
            this.isLoading = false;
        }
    }

    //getter method to check if contact/lead has no email history
    get hasEmailHistory() {
        return this.emailHistoryData !== null && this.emailHistoryData !== undefined;
    }

    //get the preview URL from the row and call the apex method to get the HTML content
    //htmlContent is rendered in child component emailPreviewModal
    async handlePreviewURL(event) {
        const actionName = event.detail.action.name
        const previewURL = event.detail.row.previewURL
        let result;

        if (actionName === 'preview_url') {
            try{
                result = await getPreviewEmail({ previewUrl: previewURL })
            } catch (error) {
                this.showErrorToast('An error occurred: ' + error.message)
            }

            if(result !== null && result !== undefined && result.startsWith('Error')){
                this.showErrorToast('An error occurred: ' + result);
            } else{
                this.htmlContent = result;
                this.openModal();
            }
        }
    }

    //Error Handling
    //Use this helper method to throw an error toast message
    showErrorToast(errorMessage) {
        const toastEvent = new ShowToastEvent({
            title: 'Error',
            message: errorMessage,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(toastEvent);
    }

    //pagination helpers
    paginateData() {
        const startIndex = (this.page - 1) * this.itemsPerPage;
        const endIndex = this.page * this.itemsPerPage;
        this.paginatedData = this.emailHistoryData.slice(startIndex, endIndex);
    }

    handlePreviousPage() {
        if (this.page > 1) {
            this.page--;
            this.updatePaginationButtons();
            this.paginateData();
        }
    }

    handleNextPage() {
        if (this.page < Math.ceil(this.totalRecords / this.itemsPerPage)) {
            this.page++;
            this.updatePaginationButtons();
            this.paginateData();
        }
    }

    updatePaginationButtons() {
        this.isPrevDisabled = this.page <= 1;
        this.isNextDisabled = this.totalRecords <= this.itemsPerPage || this.page >= Math.ceil(this.totalRecords / this.itemsPerPage);
    }

    //modal helpers
    openModal() {
        this.isModalOpen = true;
    }

    handleModalClose() {
        this.isModalOpen = false;
    }
}