({
    /**
     * Creates a mock component for testing
     */
    createMockComponent: function() {
        return {
            get: function(attribute) {
                return this[attribute];
            },
            set: function(attribute, value) {
                this[attribute] = value;
            }
        };
    },
    
    /**
     * Creates a mock event for testing
     */
    createMockEvent: function() {
        return {
            getSource: function() {
                return {
                    get: function(attribute) {
                        return this[attribute];
                    }
                };
            },
            preventDefault: function() {},
            stopPropagation: function() {}
        };
    },
    
    /**
     * Creates a mock helper for testing
     */
    createMockHelper: function() {
        return {
            getRecordType: function(recordId) {
                if (!recordId) return null;
                var prefix = recordId.substring(0, 3);
                var prefixMap = {
                    '00Q': 'Lead',
                    '006': 'Opportunity',
                    '001': 'Account',
                    '003': 'Contact'
                };
                return prefixMap[prefix] || null;
            }
        };
    },
    
    /**
     * Asserts that two values are equal
     */
    assertEquals: function(expected, actual, message) {
        if (expected !== actual) {
            throw new Error(message || 'Expected ' + expected + ' but got ' + actual);
        }
    },
    
    /**
     * Asserts that a value is not null
     */
    assertNotNull: function(value, message) {
        if (value === null || value === undefined) {
            throw new Error(message || 'Expected value to not be null');
        }
    },
    
    /**
     * Asserts that a value is true
     */
    assertTrue: function(value, message) {
        if (value !== true) {
            throw new Error(message || 'Expected value to be true');
        }
    },
    
    /**
     * Asserts that a value is false
     */
    assertFalse: function(value, message) {
        if (value !== false) {
            throw new Error(message || 'Expected value to be false');
        }
    }
}) 