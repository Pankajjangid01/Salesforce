import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// import NAME_FIELD from '@salesforce/schema/Account.Name';
// import PHONE_FIELD from '@salesforce/schema/Account.Phone';

const FIELDS = [
    'Student__c.Name__c',
    'Student__c.Father_Name__c',
    'Student__c.Mother_Name__c',
    'Student__c.Phone__c',
];
export default class StudentLwc extends LightningElement {
    // name = 'John Doe';
    // company = 'Acme Corporation';
    // position = 'Software Engineer';
    // salary = '$100,000';
    @api recordId;
    // @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    get name() {
        return this.record.data.fields.Name__c.value
        // return this.record.data ? getFieldValue(this.record.data, NAME_FIELD) : '';
        // return getFieldValue(this.record.data, FIELDS);
    }

    get phone() {
        return this.record.data.fields.Phone__c.value
        // return this.record.data ? getFieldValue(this.record.data, PHONE_FIELD) : '';
        // return getFieldValue(this.record.data, PHONE_FIELD);
    }
    get fatherName() {
        return this.record.data.fields.Father_Name__c.value
    }
   get motherName() {
    return this.record.data
        ? this.record.data.fields.Mother_Name__c.value
        : '';
}
}