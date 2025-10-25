classdef CodeGenerator < matlabshared.mediator.internal.Publisher
    %CODEGENERATOR generates MATLAB code for the Code Log Section of the app
    %for any property setters.

    % Copyright 2021 The MathWorks, Inc.

    properties (SetObservable, AbortSet)
        % Publishing property for setting the read and write terminators.
        ReadTerminator = "LF"
        WriteTerminator = "LF"

        % Publishing property that allows the MATLABCodeGenerator class
        % to publish property setter comment and code.
        PropertyNameValue
    end

    methods
        function generateTerminatorCode(obj, transport)
            if iscell(transport.Terminator)
                obj.ReadTerminator = transport.Terminator{1};
                obj.WriteTerminator = transport.Terminator{2};
            else
                obj.ReadTerminator = transport.Terminator;
                obj.WriteTerminator = transport.Terminator;
            end
        end

        function generatePropertySetterCode(obj, transport, propertyName)
            obj.PropertyNameValue = {propertyName, transport.(propertyName)};
        end
    end
end