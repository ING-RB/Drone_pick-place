define(function() { return {
    "family" : "studio_data",
    "modelVersion" : "1.0",
    "packages" : {
        "studio" : {
            "packages" : {
                "data" : {
                    "primitiveTypes" : {
                        "PropertyValue" : {}
                    },
                    "classes" : {
                        "ContextData" : {
                            "properties" : {
                                "activeContexts" : { "type" : "StdString","lower" : "0","upper" : "*", "isOrdered" : true, "isUnique" : false },
                                "properties" : { "type" : "Property","lower" : "0","upper" : "*", "opposite" : "owner", "qualifiedBy" : "name", "isComposite" : true, "isOrdered" : true, "isUnique" : true }
                            },
                            
                            
                            
                            "isAbstract":false
                        },
                        "Property" : {
                            "properties" : {
                                "name" : { "type" : "StdString","lower" : "1","upper" : "1", "isOrdered" : true, "isUnique" : true },
                                "value" : { "type" : "PropertyValue","lower" : "1","upper" : "1", "isOrdered" : true, "isUnique" : true },
                                "owner" : { "type" : "ContextData","lower" : "0","upper" : "1", "opposite" : "properties", "isOrdered" : true, "isUnique" : true }
                            },
                            
                            
                            
                            "isAbstract":false
                        }
                    }
                }
            }
        }
    }
}; 
});
