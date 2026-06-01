import { api, wire, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import STUDENT_OBJECT from '@salesforce/schema/Student__c';

export default class StudentManager extends NavigationMixin(LightningElement) {
    @api recordId;
    showModal = false;
    selectedRecordTypeId;
    recordTypeOptions = [];

    @wire(getObjectInfo, { objectApiName: STUDENT_OBJECT})
    objectInfoHandler({ data, error }) {
        if (data) {
            console.log("printing data----->>>>>>",data);
            const recordTypes = data.recordTypeInfos;
            this.recordTypeOptions =
                Object.keys(recordTypes)
                    .filter(recordTypeId =>
                        !recordTypes[recordTypeId].master
                    )
                    .map(recordTypeId => ({
                        label:
                            recordTypes[recordTypeId].name,
                        value: recordTypeId
                    }));
        } else if (error) {
            console.log(error);
        }
    }
    openModal() {
        this.showModal = true;
    }
    closeModal() {
        this.showModal = false;
    }
    handleRecordTypeChange(event) {this.selectedRecordTypeId =event.detail.value;}

    handleNext() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Student__c',
                actionName: 'new'
            },
            state: {
                recordTypeId:
                    this.selectedRecordTypeId
            }

        });
        this.showModal = false;
    }

    handleDelete() {
        if (!this.recordId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Delete Failed',
                    message:
                        'No student record selected',
                    variant: 'error'
                })
            );
            return;
        }

        deleteRecord(this.recordId)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message:
                            'Student deleted successfully',
                        variant: 'success'
                    })
                );
                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: 'Student__c',
                        actionName: 'list'
                    },
                    state: {
                        filterName: 'Recent'
                    }
                });
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Delete Failed',
                        message:
                            error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}