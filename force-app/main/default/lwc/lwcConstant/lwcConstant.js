import { LightningElement,api } from 'lwc';

export default class LwcConstant extends LightningElement {
    @api CONSTANT = {
        AUTOFILL_RADIO_BUTTON:'autofill',
        MANUAL_RADIO_BUTTON:'manual',
        APPLICATION_PDF:'application/pdf',
        DOCUMENT:'document',
        IMAGE:'image',
        VIDEO:'video',
        FILES_UPLOADED_SUCCESFULLY:'File(s) uploaded successfully',
        ENTER_PHONE_NUMBER:'Please enter a phone number',
        UPLOADFILE_OR_ENTERMESSAGE:'Please upload a file or enter a message',
        MESSAGE_SENT_SUCCESSFULLY:'Message sent successfully',
        VIDEO_TYPE_MP4:'video/mp4'

    }
}