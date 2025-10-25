classdef WarningAlert < matlab.unittest.internal.constraints.ActualAlertVisitor
    % WarningAlert - This class is undocumented. It represents a warning.
    
    % Copyright 2015-2020 The MathWorks, Inc.
       
    methods
        
        function alertObj = WarningAlert(warnings)
            alertObj = alertObj@matlab.unittest.internal.constraints.ActualAlertVisitor(warnings);
        end
        
        function tf = isEquivalentTo(alert1, alert2)
             tf = strcmp(alert1.Alert.identifier, alert2.Alert.identifier) &&  isequal(alert1.Alert.arguments, alert2.Alert.arguments);
        end
                              
        function tf = conformsToID(thisAlert, expectedAlertSpec)
            tf = arrayfun(@(x)strcmp(thisAlert.Alert.identifier, x.Identifier), expectedAlertSpec);
        end
        
        function tf = conformsToMessageObject(thisAlert, expectedAlertSpec)
            tf = arrayfun(@(x)strcmp(thisAlert.Alert.identifier, x.Identifier), expectedAlertSpec) & ...
                       arrayfun(@(x)isequal(thisAlert.Alert.arguments, x.Arguments), expectedAlertSpec);
        end
        
        function str = toStringForDisplayID(thisAlert)
            import matlab.unittest.internal.constraints.getIdentifierString;
            str = getIdentifierString(thisAlert.Alert.identifier);
        end
        
        function str = toStringForDisplayMessageObject(thisAlert)
            import matlab.unittest.internal.constraints.createAlertDisplayString;
            
            warningAlert = thisAlert.Alert;
            str = char(createAlertDisplayString(warningAlert.identifier, ...
                warningAlert.message, warningAlert.arguments));
        end
        
        tf = conformsToClass(thisAlert, classes);
        str = toStringForDisplayClass(thisAlert);
    end
end
