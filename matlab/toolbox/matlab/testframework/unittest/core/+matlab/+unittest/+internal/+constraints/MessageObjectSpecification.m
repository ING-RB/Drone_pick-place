classdef MessageObjectSpecification < matlab.unittest.internal.constraints.ExpectedAlertSpecification
    % MessageObjectSpecification - This class is undocumented. 
    
    % Copyright 2015-2020 The MathWorks, Inc.
    
    properties(Dependent, Access=?matlab.unittest.internal.constraints.ActualAlertVisitor)
        Identifier;
        Arguments;
        Message;
    end
    
    methods(Static)
        function str = formatForDisplay(actualAlert)
            str = actualAlert.toStringForDisplayMessageObject();
        end
    end
    
    methods
        
        function tf = accepts(expectedAlertSpecification, actualAlert)
            tf = actualAlert.conformsToMessageObject(expectedAlertSpecification);
        end
        
        function tf = eq(spec1, spec2)
            tf = strcmp({spec1.Identifier}, {spec2.Identifier}) & ...
                arrayfun(@(x)isequal(x.Arguments, spec2.Arguments), spec1);
        end
        
        function str = toStringForDisplay(spec)
            import matlab.unittest.internal.constraints.createAlertDisplayString;
            str = char(createAlertDisplayString(spec.Identifier, spec.Message, spec.Arguments));
        end
        
        function id = get.Identifier(spec)
            id = spec.Specification.Identifier;
        end
        
        function args = get.Arguments(spec)
            args = spec.Specification.Arguments;
        end
        
        function msg = get.Message(spec)
            msg = getString(spec.Specification);
        end
    end
    
    methods(Access=?matlab.unittest.internal.constraints.ExpectedAlertSpecification)
        function messageObjSpec = MessageObjectSpecification(messageObjects)
            messageObjSpecCell = num2cell(messageObjects);
            messageObjSpec = messageObjSpec@matlab.unittest.internal.constraints.ExpectedAlertSpecification(messageObjSpecCell);
        end
    end
end