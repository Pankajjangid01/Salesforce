import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import STUDENT_OBJECT from '@salesforce/schema/Student__c';

export default class NewFresherStudent extends NavigationMixin(LightningElement) {

    @wire(getObjectInfo, { objectApiName: STUDENT_OBJECT })
    objectInfo;

    connectedCallback() {
        this.openNewFresherRecord();
    }

    openNewFresherRecord() {
        setTimeout(() => {
            if (this.objectInfo && this.objectInfo.data) {
                const recordTypes = this.objectInfo.data.recordTypeInfos;
                const fresherRTId = Object.keys(recordTypes).find(
                    rtId => recordTypes[rtId].developerName === 'Fresher'
                );

                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: 'Student__c',
                        actionName: 'new'
                    },
                    state: {
                        recordTypeId: fresherRTId,
                        nooverride: '1'
                    }
                });
            }
        }, 500);
    }
}