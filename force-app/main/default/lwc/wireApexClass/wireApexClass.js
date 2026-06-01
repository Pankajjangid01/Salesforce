import { LightningElement, api, wire } from 'lwc';
import getStudents from '@salesforce/apex/StudtentController.getStudents';
export default class WireApexClass extends LightningElement {
    @api recordId;
    students;
    error;
    @wire(getStudents, { stdId: '$recordId' })
    // wiredStudents;  //property to hold the wired data and error
    wiredStudents({ error, data }) {  //function to handle the wired data and error
        if (data) {
            this.students = data;
            this.error = undefined;
        }else if (error) {
            this.error = error;
            this.students = undefined;
        }
    }

    get hasStudents() {
        return this.students && this.students.length > 0;
    }
    // for the property approach
    // get hasStudents() {
    //     return this.students && this.students.length > 0;
    // }
}