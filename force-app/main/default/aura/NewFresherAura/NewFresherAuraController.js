({
    doInit : function(component, event, helper) {

        const pageRef = component.get("v.pageReference");

        let recordTypeName = 'Fresher';

        if(pageRef && pageRef.state && pageRef.state.c__rtName){
            recordTypeName = pageRef.state.c__rtName;
        }

        var action = component.get("c.getRecordTypeId");

        action.setParams({
            objectName : 'Student__c',
            developerName : recordTypeName
        });

        action.setCallback(this, function(response) {

            const rtId = response.getReturnValue();

            const createRecordEvent =
                $A.get("e.force:createRecord");

            createRecordEvent.setParams({
                entityApiName: 'Student__c',
                recordTypeId: rtId
            });

            createRecordEvent.fire();

        });

        $A.enqueueAction(action);
    }
})