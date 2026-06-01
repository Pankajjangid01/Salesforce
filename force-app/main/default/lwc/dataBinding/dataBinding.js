import { LightningElement } from 'lwc';

export default class DataBinding extends LightningElement {

    // ----------------------Getters Approach----------------------
    firstName = '';
    lastName = '';
    // handleNameChange(event) {
    //     const fieldName = event.target.name; // Get the name of the input field
    //     if (fieldName === 'firstName') {
    //         this.firstName = event.target.value;
    //     } else if (fieldName === 'lastName') {
    //         this.lastName = event.target.value;
    //     }
    // }

    // get fullName(){
    //     return `${this.firstName} ${this.lastName}`.toUpperCase();
    // }

    // ----------------------Query Selector Approach----------------------
    // greetings = 'World!';
    // updateGreeting() {
    //     const inputElement = this.template.querySelector('lightning-input');
    //     if (inputElement) {
    //         this.greetings = inputElement.value;
    //     }
    // }

    // ----------------------Query Selector All Approach----------------------
    updateNames() {
        var inputElement = this.template.querySelectorAll('lightning-input');
        inputElement.forEach(input=>{
            if (input.name == 'firstName') {
                this.firstName = input.value;
            }else if (input.name == 'lastName') {
                this.lastName = input.value;
            }
        })
    }
}