classdef ReferenceTopicInput
    properties
        ArgName (1,1) string = "";
        Topic (1,1) string = "";
        IsVariable (1,1) logical = false
        VariableName (1,1) string = "";
    end

    methods
        function obj = ReferenceTopicInput(inputs, workspaceVars)
            arguments
                inputs cell;
                workspaceVars struct;
            end
            stringInputs = strings(0);
            for i = 1:numel(inputs)
                input = inputs{i};
                if ischar(input)
                    input = strip(string(input));
                elseif ~isstring(input)
                    if isscalar(inputs)
                        % input is a variable.
                        obj.Topic = string(class(input));
                        obj.IsVariable = true;
                        return;
                    else
                        multiVar = MException(message('MATLAB:doc:MustBeSingleNonText'));
                        multiVar.throwAsCaller;
                    end
                end
                stringInputs = [stringInputs, input(:)']; %#ok<AGROW>
            end
            stringInputs(stringInputs=="") = [];
            if isempty(stringInputs)
                obj(1) = [];
            else
                obj.ArgName = join(stringInputs);
                [obj.Topic, obj.IsVariable, obj.VariableName] = matlab.internal.help.getClassNameFromWS(obj.ArgName, workspaceVars, true);
                obj.Topic = erase(obj.Topic, "/" + textBoundary("end"));
            end
        end
    end

    methods
        function preferArgName = isArgNamePreferred(obj)
            preferArgName = obj.ArgName ~= "" && obj.ArgName ~= obj.VariableName;
        end
    end
end

%   Copyright 2021-2024 The MathWorks, Inc.
