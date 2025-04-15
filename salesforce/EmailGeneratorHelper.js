({
    /**
     * Determine the record type based on the ID prefix
     * @param {String} recordId - The Salesforce record ID
     * @return {String} - The record type (Lead, Opportunity, etc.)
     */
    getRecordType: function(recordId) {
        if (!recordId) {
            return null;
        }
        
        // Extract the first 3 characters of the ID to determine the object type
        var prefix = recordId.substring(0, 3);
        
        // Map of ID prefixes to object types
        var prefixMap = {
            '00Q': 'Lead',
            '006': 'Opportunity',
            '001': 'Account',
            '003': 'Contact'
        };
        
        return prefixMap[prefix] || null;
    }
}) 