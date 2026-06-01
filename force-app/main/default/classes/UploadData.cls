public with sharing class UploadData {
    @AuraEnabled
    public static void uploadCSV(String csvData){
        List<Account> accounts = new List<Account>();
        List<String> rows = csvData.split('\n');
        List<String> headers = rows[0].split(',');
        for(Integer i = 1; i < rows.size(); i++){
            List<String> cols = rows[i].split(',');
            Account acc = new Account();
            for(Integer j = 0; j < headers.size(); j++){
                String fieldName = headers[j].trim();
                String value = '';
                if(j < cols.size()){
                    value = cols[j].trim();
                }
                acc.put(fieldName, value);
            }
            accounts.add(acc);
        }
        if(!accounts.isEmpty()){
            insert accounts;
        }
    }
}