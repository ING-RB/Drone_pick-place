classdef SelectorProviderShared < matlab.io.internal.FunctionInterface
%

% Copyright 2024 The MathWorks, Inc.

    properties (Access = protected, Transient)
        SelectorValidation (1, 1) matlab.io.xml.internal.parameter.SelectorValidation = "XPath";
    end

    methods (Access = protected)
        function validateSelectors(obj, selector, errMsg, property)
            import matlab.io.xml.internal.parameter.SelectorValidation;

            if isstring(selector) && isscalar(selector) && ismissing(selector)
                return; % Default value is missing scalar string, no need to validate.
            end

            if obj.SelectorValidation == SelectorValidation.XPath
                validateXPath(selector, errMsg, property);
            elseif obj.SelectorValidation == SelectorValidation.JSONPointer
                matlab.io.json.internal.validateSelector(selector);
            end % else SelectorValidation.None is a no-op.
        end

        function rhs = convertToString(obj, rhs)
            rhs = convertCharsToStrings(rhs);
            if isa(rhs,'missing')
                rhs = string(rhs);
            end
        end

        function obj = updateSelectorValidationFromFileType(obj, fileType)
            import matlab.io.xml.internal.parameter.SelectorValidation;

            if fileType == "json"
                obj.SelectorValidation = SelectorValidation.JSONPointer;
            else
                obj.SelectorValidation = SelectorValidation.XPath;
            end
        end

        function obj = revalidateSelectorsFromFileType(obj, fileType)

            obj = obj.updateSelectorValidationFromFileType(fileType);

            % Re-set all the selectors to perform validation again.
            obj.TableSelector = obj.TableSelector;
            obj.RowSelector = obj.RowSelector;
            obj.VariableSelectors = obj.VariableSelectors;
            obj.VariableUnitsSelector = obj.VariableUnitsSelector;
            obj.VariableDescriptionsSelector = obj.VariableDescriptionsSelector;
            obj.RowNamesSelector = obj.RowNamesSelector;
        end
    end
end

function validateXPath(selector, errMsg, property)
    try
        % Accepts only one xpath at a time
        matlab.io.xml.internal.xpath.validate(selector);
    catch ME
        if strcmpi(ME.identifier, "MATLAB:io:xml:xpath:InvalidXPathDatatype")
            error(message(errMsg, property));
        else
            throw(ME);
        end
    end
end
