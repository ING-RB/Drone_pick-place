classdef ExceptionAlert < matlab.unittest.internal.constraints.ActualAlertVisitor
    % ExceptionAlert - This class is undocumented. It represents an exception.
    
    % Copyright 2015-2020 The MathWorks, Inc.
    
    properties(Dependent, Access=private)
        MetaClass;
    end
    
    methods
        function alertObj = ExceptionAlert(exceptions)
            alertObj = alertObj@matlab.unittest.internal.constraints.ActualAlertVisitor(exceptions);
        end
        
        function metaClass = get.MetaClass(thisAlert)
            metaClass = metaclass(thisAlert.Alert);
        end
        
        function tf = isEquivalentTo(alert1, alert2)
            tf = isequal(alert1.Alert.identifier, alert2.Alert.identifier) &&  isequal(alert1.Alert.arguments, alert2.Alert.arguments);
        end
        
        function tf = conformsToID(thisAlert, expectedAlertSpec)
            tf = arrayfun(@(x)strcmp(thisAlert.Alert.identifier, x.Identifier), expectedAlertSpec);
        end
        
        function tf = conformsToMessageObject(thisAlert, expectedAlertSpec)
            tf = strcmp(thisAlert.Alert.identifier, {expectedAlertSpec.Identifier}) & ...
                 arrayfun(@(x)isequal(x.Arguments, thisAlert.Alert.arguments), expectedAlertSpec);
        end
        
        function str = toStringForDisplayID(thisAlert)
            import matlab.unittest.internal.constraints.getIdentifierString;
            str = getIdentifierString(thisAlert.Alert.identifier);
        end
        
        function str = toStringForDisplayMessageObject(thisAlert)
            import matlab.unittest.internal.constraints.createAlertDisplayString;
            
            exceptionAlert = thisAlert.Alert;
            str = char(createAlertDisplayString(exceptionAlert.identifier, ...
                exceptionAlert.message, exceptionAlert.arguments));
        end
        
        function tf = conformsToClass(thisAlert, expectedAlertSpec)
            import matlab.unittest.internal.constraints.ExceptionAlert;
            tf = reshape([meta.class.empty, thisAlert.MetaClass], size(thisAlert)) <= ...
                reshape([meta.class.empty, expectedAlertSpec.MetaClass], size(expectedAlertSpec));
        end
        
        function str = toStringForDisplayClass(thisAlert)
            classInfo = metaclass(thisAlert.Alert);
            str = ['?' classInfo.Name];
        end
        
    end
end

