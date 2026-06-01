import { LightningElement } from 'lwc';

export default class ConditionalRendering extends LightningElement {

    isContentVisible = false;

    contacts = [
        {
            id: 1,
            name: 'John Doe',
            email: 'john.doe@example.com'
        },
        {
            id: 2,
            name: 'Jane Smith',
            email: 'jane.smith@example.com'
        }
    ];

    handleCheckboxChange(event) {

        this.isContentVisible =
            event.target.checked;

    }
}