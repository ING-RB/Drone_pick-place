classdef TerminatorClass < matlabshared.transportapp.internal.utilities.ITestable

    %TERMINATORCLASS provides the getters and setters for the Read and
    %Write Terminators.

    % Copyright 2021 The MathWorks, Inc.

    properties(Constant, Hidden)
        TerminatorDropDownValues = ["CR", "LF", "CR/LF"]
    end

    properties(Access = public)
        ReadTerminator (1, 1) string
        WriteTerminator (1, 1) string
    end

    methods
        function obj = TerminatorClass(readTerminator, writeTerminator)
            obj.ReadTerminator = readTerminator;
            obj.WriteTerminator = writeTerminator;
        end
    end

    %% Getters and Setters
    methods
        function value = get.ReadTerminator(obj)
            value = ...
                internal.matlab.editorconverters.datatype.StringEnumeration ...
                (obj.ReadTerminator, obj.getReadTerminatorDropDownValuesHook());
        end

        function set.ReadTerminator(obj, inspectorValue)
            if isa(inspectorValue, 'internal.matlab.editorconverters.datatype.StringEnumeration')
                if ~isequal(obj.ReadTerminator, inspectorValue.Value)
                    obj.ReadTerminator = inspectorValue.Value;
                end
            else
                obj.ReadTerminator = inspectorValue;
            end
        end

        function value = get.WriteTerminator(obj)
            value = ...
                internal.matlab.editorconverters.datatype.StringEnumeration ...
                (obj.WriteTerminator, obj.getWriteTerminatorDropDownValuesHook());
        end

        function set.WriteTerminator(obj, inspectorValue)
            if isa(inspectorValue, 'internal.matlab.editorconverters.datatype.StringEnumeration')
                if ~isequal(obj.WriteTerminator, inspectorValue.Value)
                    obj.WriteTerminator = inspectorValue.Value;
                end
            else
                obj.WriteTerminator = inspectorValue;
            end
        end
    end

    %% Hook Methods
    methods(Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function values = getReadTerminatorDropDownValuesHook(obj)
            values = obj.TerminatorDropDownValues;
        end

        function values = getWriteTerminatorDropDownValuesHook(obj)
            values = obj.TerminatorDropDownValues;
        end
    end
end