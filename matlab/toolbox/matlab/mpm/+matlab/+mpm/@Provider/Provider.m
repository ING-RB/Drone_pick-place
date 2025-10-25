classdef (Sealed) Provider  <  matlab.mixin.CustomCompactDisplayProvider
    properties
        Name {mustBeTextScalar} = ""
        Organization {mustBeTextScalar} = ""
        Email {mustBeTextScalar} = ""
        URL {mustBeTextScalar} = ""
    end
    methods
        function obj = Provider(opts)
            arguments
                opts.Name {mustBeTextScalar}
                opts.Organization {mustBeTextScalar}
                opts.Email {mustBeTextScalar}
                opts.URL {mustBeTextScalar}
            end

            fieldnames = ["Name" "Organization" "Email" "URL"];

            for field = fieldnames
                if isfield(opts, field)
                    obj.(field) = opts.(field);
                end
            end
        end

        function rep = compactRepresentationForSingleLine(obj,displayConfiguration,width)
            providerAsStrings = arrayfun(@(x) providerToString(x), obj, UniformOutput=false);

            rep = widthConstrainedDataRepresentation(obj, displayConfiguration, width, ...
                                                     StringArray=providerAsStrings, ...
                                                     Annotation=annotationForDisplay(obj,displayConfiguration), ...
                                                     AllowTruncatedDisplayForScalar = true);
        end

        function annotation = annotationForDisplay(obj, displayConfiguration)
            import matlab.display.DimensionsAndClassNameRepresentation;

            dimAndClsName = DimensionsAndClassNameRepresentation(obj, displayConfiguration);
            annotation = dimAndClsName.DimensionsString + " " + dimAndClsName.ClassName;
        end

        function dispName = providerToString(provider)
            if ~strcmp(provider.Name, "") && ~strcmp(provider.Organization, "")
                dispName = sprintf('%s(%s)', provider.Name, provider.Organization);
            elseif ~strcmp(provider.Name, "")
                dispName = provider.Name;
            elseif ~strcmp(provider.Organization, "")
                dispName = provider.Organization;
            elseif ~strcmp(provider.Email, "")
                dispName = provider.Email;
            elseif ~strcmp(provider.URL, "")
                dispName = provider.URL;
            else
                dispName = '""';
            end
        end

    end
end

%   Copyright 2024 The MathWorks, Inc.
