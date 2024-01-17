/**
 * Created by mirko on 16.01.2024.
 */

import { LightningElement, api } from 'lwc';

export default class EmailPreviewModal extends LightningElement {
    @api htmlContent;
    @api isOpen = false;

    closeModal() {
        this.isOpen = false;
        // Dispatch an event to notify parent component
        this.dispatchEvent(new CustomEvent('close'));
    }

    // Lifecycle hook to render HTML content
    renderedCallback() {
        const container = this.template.querySelector('.email-preview-content');
        if (container) {
            // Ensure the content is sanitized and safe
            container.innerHTML = this.htmlContent;
        }
    }
}
