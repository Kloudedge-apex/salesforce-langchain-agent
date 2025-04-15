({
    /**
     * Initialize the component
     */
    doInit: function(component, event, helper) {
        // Get the record ID from the page
        var recordId = component.get("v.recordId");
        if (recordId) {
            // Determine the record type based on the ID prefix
            var recordType = helper.getRecordType(recordId);
            component.set("v.recordType", recordType);
        }
    },
    
    /**
     * Generate an email draft based on the record type
     */
    generateEmail: function(component, event, helper) {
        // Set loading state
        component.set("v.isLoading", true);
        component.set("v.error", "");
        component.set("v.emailDraft", "");
        
        var recordId = component.get("v.recordId");
        var recordType = component.get("v.recordType");
        
        // Call the appropriate Apex method based on record type
        var action;
        if (recordType === "Lead") {
            action = component.get("c.generateEmailForLead");
            action.setParams({
                leadId: recordId
            });
        } else if (recordType === "Opportunity") {
            action = component.get("c.generateEmailForOpportunity");
            action.setParams({
                opportunityId: recordId
            });
        } else {
            component.set("v.isLoading", false);
            component.set("v.error", "Unsupported record type: " + recordType);
            return;
        }
        
        // Set callbacks
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if (result.success) {
                    component.set("v.emailDraft", result.emailDraft);
                } else {
                    component.set("v.error", result.error || "Failed to generate email draft");
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    var errorMessage = "";
                    for (var i = 0; i < errors.length; i++) {
                        errorMessage += errors[i].message + "\n";
                    }
                    component.set("v.error", errorMessage);
                } else {
                    component.set("v.error", "Unknown error occurred");
                }
            }
            
            // Reset loading state
            component.set("v.isLoading", false);
        });
        
        // Enqueue the action
        $A.enqueueAction(action);
    },
    
    /**
     * Copy the email draft to clipboard
     */
    copyToClipboard: function(component, event, helper) {
        var emailDraft = component.get("v.emailDraft");
        if (emailDraft) {
            // Create a temporary textarea element
            var textarea = document.createElement("textarea");
            textarea.value = emailDraft;
            document.body.appendChild(textarea);
            
            // Select and copy the text
            textarea.select();
            document.execCommand("copy");
            
            // Remove the temporary element
            document.body.removeChild(textarea);
            
            // Show a toast notification
            var toastEvent = $A.get("e.force:showToast");
            if (toastEvent) {
                toastEvent.setParams({
                    title: "Success",
                    message: "Email draft copied to clipboard",
                    type: "success"
                });
                toastEvent.fire();
            }
        }
    }
}) 