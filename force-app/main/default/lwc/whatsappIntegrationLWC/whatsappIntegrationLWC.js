import { LightningElement, api, track } from 'lwc';
import sendToWhatsApp from '@salesforce/apex/WhatsAppIntegrationController.sendToWhatsApp';
import queryPhoneFields from '@salesforce/apex/WhatsAppIntegrationController.queryPhoneFields';
import getPublicUrl from '@salesforce/apex/WhatsAppIntegrationController.getPublicUrl';
import getMessageHistoryByPhoneNumber from '@salesforce/apex/WhatsAppIntegrationController.getMessageHistoryByPhoneNumber';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import lwcConstant from "c/lwcConstant";

export default class RecordPageLWC extends lwcConstant {
    @api recordId;
    @api cvId;
    @api type = '';
    @track uploadedFiles = 0;
    @track messageHistory = [];
    @track phoneNumber = '';
    @track message = '';
    @track mediaLink = '';
    @track timestamp = '';
    @track phoneOptions = [];
    @track selectedAutofillPhone = '';
    @track showAutofillInput = false;
    @track showManualInput = false;
    
    handlePhoneNumberChange(event) {
        this.phoneNumber = event.target.value;
        this.loadMessageHistory();
    }

    handleMessageChange(event) {
        this.message = event.target.value.trim();
    }

    handleRadioChange(event) {
        const selectedValue = event.target.value;
        if (selectedValue === this.CONSTANT.AUTOFILL_RADIO_BUTTON) {
            this.showAutofillInput = true;
            this.showManualInput = false;
            this.autoFillPhoneNumber();
        } else if (selectedValue === this.CONSTANT.MANUAL_RADIO_BUTTON) {
            this.showAutofillInput = false;
            this.showManualInput = true;
            this.selectedAutofillPhone = ''; 
            this.phoneNumber = ''; 
            this.messageHistory = [];
        }
    }

    autoFillPhoneNumber() {
        queryPhoneFields({record_Id: this.recordId})
        .then(result => {
            if (result && result.phoneFields) {
                const nonEmptyFields = result.phoneFields.filter(field => field.fieldValue !== undefined && field.fieldValue !== null && field.fieldValue !== '');
                this.phoneOptions = nonEmptyFields.map(field => ({
                    label: field.fieldValue,
                    value: field.fieldValue
                }));
                if (this.phoneOptions.length > 0) {
                    this.selectedAutofillPhone = this.phoneOptions[0].value;
                    this.phoneNumber = this.selectedAutofillPhone;
                    console.log('57this.phoneNumber',this.phoneNumber);
                    this.loadMessageHistory();
                }
            }
        })
        .catch(error => {
            console.error('Error fetching phone fields:', error);
        });
    }

    handleAutofillPhoneChange(event) {
        this.selectedAutofillPhone = event.detail.value;
        console.log('Selected autofill change phone number:', this.selectedAutofillPhone);
        this.phoneNumber = this.selectedAutofillPhone;
        this.loadMessageHistory();
    }

    handleManualPhoneNumberChange(event) {
        this.selectedAutofillPhone = ''; 
        this.phoneNumber = event.target.value;  
        console.log('Entered manual number',this.phoneNumber);
        this.loadMessageHistory();
    }
    

    loadMessageHistory() {
        if (this.phoneNumber) {
            this.messageHistory = [];
            getMessageHistoryByPhoneNumber({ phoneNumber: this.phoneNumber })
                .then(result => {
                    for (let i = 0; i < result.length; i++) {
                        const newMessage = {
                            id: new Date().toDateString(),
                            phoneNumber: result[i].PhoneNumber__c,
                            messageType: result[i].MessageType__c,
                            message: result[i].Message__c,
                            mediaLink: result[i].MediaLink__c,
                            timestamp: result[i].Timestamp__c
                        };
                        this.messageHistory = [...this.messageHistory, newMessage];
                    }
                    console.log('result history related to phone number ',result);
                    console.log('Phone No.-> ' + result[0].PhoneNumber__c);
                    console.log('Message Type.-> ' + result[0].MessageType__c);
                    console.log('Message.-> ' + result[0].Message__c);
                    console.log('Attachment Link.-> ' + result[0].MediaLink__c);
                    console.log('Message Sending time.-> ' + result[0].Timestamp__c);
                })
                .catch(error => {
                    console.log('Not found messages history with this number :', error);
                });
        }
    }
    
    handleUploadFinished(event) {
        this.uploadedFiles = event.detail.files.length;
        this.cvId = event.detail.files[0].contentVersionId;
        this.type = event.detail.files[0].mimeType;
        const toastMessage = `${this.uploadedFiles} File(s) uploaded successfully`;
        this.showToast('SUCCESS', toastMessage, 'success');
    }

    async processMedia() {
        const data = await getPublicUrl({ cvId: this.cvId });
        const messageType = this.type === this.CONSTANT.APPLICATION_PDF ? this.CONSTANT.DOCUMENT : this.CONSTANT.IMAGE;
        this.sendToWhatsApp(messageType, this.message, data);
    }

    sendMessage() {
        console.log('Calling sendMessage method...');
        console.log('Type:', this.type);
        console.log('Selected Phone Type:', this.selectedAutofillPhone);
        if (!this.phoneNumber) {
            this.showToast('Error', this.CONSTANT.ENTER_PHONE_NUMBER, 'error');
            return;
        }

        // Check if the message body is empty and no media is uploaded
        if (!this.message.trim() && !this.cvId) {
            this.showToast('Error', this.CONSTANT.UPLOADFILE_OR_ENTERMESSAGE, 'error');
            return;
        }

        if (this.type === '')  {
            this.sendToWhatsApp('text', this.message);
        } else {
            this.processMedia();
        }
    }

    sendToWhatsApp(messageType, message, mediaLink = '') {
        sendToWhatsApp({
            phoneNumber: this.phoneNumber,  
            messageType,
            message,
            mediaLink,
            mediaCaption: '',
        })
        .then(result => {
            const toastMessage = this.CONSTANT.MESSAGE_SENT_SUCCESSFULLY;
            this.showToast('Success', toastMessage, 'success');
            console.log('Message sent successfully:', result);
            this.clearData();
        })
        .catch(error => {
            const errorMessage = 'failed to sending message: ' + error.message;
            this.showToast('Error', errorMessage, 'error');
            console.error('Error sending message:', error);
        });
    }

    get columns() {
        return [
            { label: 'To Phone Number', fieldName: 'phoneNumber', type: 'text' },
            { label: 'Message Type', fieldName: 'messageType', type: 'text' },
            { label: 'Message', fieldName: 'message', type: 'text' },
            { label: 'Attachment Link', fieldName: 'mediaLink', type: 'url', typeAttributes: { target: '_blank' } },
            { label: 'Date Time', fieldName: 'timestamp', type: 'date', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true } },
        ];
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }

    clearData() {
        this.message = '';
        this.cvId = '';
        this.type = '';
        this.uploadedFiles = '0';
    }
}