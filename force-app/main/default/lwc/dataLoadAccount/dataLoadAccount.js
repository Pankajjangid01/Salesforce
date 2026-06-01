import { LightningElement } from 'lwc';
import uploadCSV from '@salesforce/apex/UploadData.uploadCSV';

export default class DataLoadAccount extends LightningElement {
    handleFile(event){
        const file = event.target.files[0];
        const reader = new FileReader();
        reader.onload = () => {
            const csvData = reader.result;
            uploadCSV({ csvData })
            .then(() => {
                console.log('Accounts Inserted');
            })
            .catch(error => {
                console.error(error);
            });
        };
        reader.readAsText(file);
    }
}