classdef InformalSuiteCreationOptions
    %

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Modifier;
        IncludeSubfolders;
        IncludeInnerNamespaces;
        IncludeReferencedProjects;
        InvalidFileFoundAction;
    end

    properties
        ExternalParameters
    end

    methods
        function options = InformalSuiteCreationOptions(namedargs)
            arguments
                namedargs.Modifier = matlab.unittest.internal.selectors.NeverFilterSelector;
                namedargs.IncludeSubfolders = false;
                namedargs.IncludeInnerNamespaces = false;
                namedargs.IncludeReferencedProjects = false;
                namedargs.InvalidFileFoundAction = "warn";
                namedargs.ExternalParameters = matlab.unittest.parameters.Parameter.empty(1,0);
            end

            fields = string(fieldnames(namedargs));
            for idx = 1:numel(fields)
                thisField = fields(idx);
                options.(thisField) = namedargs.(thisField);
            end
        end
    end
end

% LocalWords:  Subfolders namedargs
