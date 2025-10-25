classdef DetectImportOptionsXML < matlab.io.internal.functions.ExecutableFunction ...
        & matlab.io.internal.functions.TableMetaDataFromDetection ...
        & matlab.io.internal.shared.CommonVarOpts ...
        & matlab.io.internal.shared.TreatAsMissingInput ...
        & matlab.io.internal.shared.PreserveVariableNamesInput ...
        & matlab.io.internal.shared.MissingErrorRulesInputs ...
        & matlab.io.internal.shared.HexBinaryType ...
        & matlab.io.xml.internal.parameter.SelectorProvider ...
        & matlab.io.xml.internal.parameter.RowSelectorProvider ...
        & matlab.io.xml.internal.parameter.TableSelectorProvider ...
        & matlab.io.xml.internal.parameter.NodeNameProvider ...
        & matlab.io.xml.internal.parameter.RowNodeNameProvider ...
        & matlab.io.xml.internal.parameter.ImportAttributesProvider ...
        & matlab.io.xml.internal.parameter.AttributeSuffixProvider ...
        & matlab.io.xml.internal.parameter.RepeatedNodeRuleProvider ...
        & matlab.io.xml.internal.parameter.DetectNamespacesProvider ...
        & matlab.io.xml.internal.parameter.RegisteredNamespacesProvider
    %

    %   Copyright 2020-2024 The MathWorks, Inc.

    properties
       XMLDocumentObject = matlab.io.xml.internal.Document();
    end

    methods
        function opts = execute(func, supplied)

            if strcmp(func.DatetimeType,'exceldatenum')
                error(message('MATLAB:textio:detectImportOptions:ExcelDateWithXML'));
            end

            checkWrongParamsWrongType(supplied);

            assertMutualNodeNameVsSelectors(supplied);

            func.XMLDocumentObject.readFile(func.Filename);
            
            detectedOpts = matlab.io.xml.internal.detection.detect(func.XMLDocumentObject,func.getOptionsForDetection());
            
            % Validate that the detected selectors are valid XPath expressions.
            % Note: Certain Unicode characters in detected XPaths can lead
            % to a validation failure.
            % This is a known limitation.
            func.validateDetectedSelectors(supplied, detectedOpts);

            % Need to convert types to the "DatetimeType" etc.

            opts = buildOptsFromDetection(detectedOpts, supplied, func);
            opts = func.setNonDetectionProperties(opts);
            opts = func.setVariableProps(supplied, opts);
        end
    end

    methods (Access = private)
        function opts = setNonDetectionProperties(func,opts)
            opts.MissingRule = func.MissingRule;
            opts.ImportErrorRule = func.ImportErrorRule;
            opts.RepeatedNodeRule = func.RepeatedNodeRule;
            opts.VariableUnitsSelector = func.VariableUnitsSelector;
            opts.VariableDescriptionsSelector = func.VariableDescriptionsSelector;
        end

        function st = getOptionsForDetection(func)
            st = struct();
            st.VariableSelectors    = func.VariableSelectors;
            st.VariableNodeNames    = func.VariableNodeNames;
            st.TableSelector        = func.TableSelector;
            st.TableNodeName        = func.TableNodeName;
            st.RowSelector          = func.RowSelector;
            st.RowNodeName          = func.RowNodeName;
            st.AttributeSuffix      = func.AttributeSuffix;
            st.ImportAttributes     = func.ImportAttributes;
            st.DetectNamespaces     = func.DetectNamespaces;
            st.RegisteredNamespaces = func.RegisteredNamespaces;
            
            % type specific name-value pairs that affect variable type
            % detection
            st.DateLocale         = string(func.DateLocale);
            st.DecimalSeparator   = string(func.DecimalSeparator);
            st.ThousandsSeparator = string(func.ThousandsSeparator);
            st.ExponentCharacter  = string(func.ExponentCharacter);
            st.TrimNonnumeric     = func.TrimNonNumeric;
        end
    end
    
    methods (Static, Access = private)
        function validateDetectedSelectors(supplied, detectedOpts)
            if ~supplied.TableSelector
                try
                    matlab.io.xml.internal.xpath.validate(detectedOpts.TableSelector);
                catch ME
                    error(message('MATLAB:io:xml:detection:DetectedUnsupportedSelector', "TableSelector", detectedOpts.TableSelector));
                end
            end

            if ~supplied.RowSelector
                try
                    matlab.io.xml.internal.xpath.validate(detectedOpts.RowSelector);
                catch ME
                    error(message('MATLAB:io:xml:detection:DetectedUnsupportedSelector', "RowSelector", detectedOpts.RowSelector));
                end
            end

            if ~supplied.VariableSelectors
                variableSelectors = detectedOpts.VariableSelectors;
                for idx = 1:length(variableSelectors)
                    try
                        matlab.io.xml.internal.xpath.validate(variableSelectors(idx));
                    catch ME
                        error(message('MATLAB:io:xml:detection:DetectedUnsupportedSelector', "VariableSelectors", variableSelectors(idx)));
                    end
                end
            end
        end
    end
    
    methods (Access = protected)
        function validateVariableSelectorsSize(~, ~)
        % no-op
        end
    end
end

function opts = buildOptsFromDetection(detectedOpts,supplied,func)
    [rowNamesSelector, detectedOpts] = getRowNamesSelector(func.ReadRowNames,...
        func.RowNamesSelector, detectedOpts);

    opts = matlab.io.xml.XMLImportOptions('NumVariables',numel(detectedOpts.VariableTypes));    
    opts.RowNamesSelector = rowNamesSelector;
    types = cellstr(detectedOpts.VariableTypes);        
    
    if func.HexType == "text"
        types(strcmp(types, 'hexadecimal')) = {func.TextType};
    end

    if func.BinaryType == "text"
        types(strcmp(types, 'binary')) = {func.TextType};
    end

    opts.fast_var_opts = matlab.io.internal.FastVarOpts(numel(types), types);

    variableNames = processAttributes( ...
        detectedOpts.VariableNames, func.AttributeSuffix, func.ReadVariableNames);

    % Store the variable names without the leading '@' char as the
    % original names found by detection.
    opts.DetectedVariableNames = variableNames;

    if (supplied.VariableNamingRule || supplied.PreserveVariableNames)
        if func.VariableNamingRule ~= "preserve"
            % Make the variable names valid MATLAB identifiers too
            variableNames = matlab.lang.makeValidName(variableNames);
        end
    end

    % Need to make the VariableNames unique and truncate to namelengthmax
    % before setting on the ImportOptions object.
    opts.VariableNames = matlab.lang.makeUniqueStrings(variableNames, {}, namelengthmax);

    opts = func.setHexOrBinaryType(supplied,opts,true);
    opts = func.setHexOrBinaryType(supplied,opts,false);

    opts.TableSelector        = detectedOpts.TableSelector;
    opts.RowSelector          = detectedOpts.RowSelector;
    opts.VariableSelectors    = detectedOpts.VariableSelectors;
    opts.VariableTypes        = opts.fast_var_opts.Types;
    opts.RegisteredNamespaces = detectedOpts.RegisteredNamespaces;
    
    if ~detectedOpts.TableDetected && ~suppliedDetectHints(supplied)
        oldState = warning("off", "backtrace");
        cleanup = onCleanup(@()warning(oldState));
        warning(message("MATLAB:io:xml:detection:NoTableDetectedWarning", func.InputFilename));
    end
end

function variableNames = processAttributes(variableNames, attributeSuffix, readVariableNames)

    % Strip the '@' character
    isAttribute = startsWith(variableNames, "@");
    variableNames(isAttribute) = strip(variableNames(isAttribute), 'left', '@');

    if readVariableNames
        % Call makeUniqueStrings to resolve conflicts between attributes before the attribute suffix
        % is added.
        % Don't truncate upto namelengthmax here, since that will be
        % handled separately with variable names later. We need to make
        % sure that these names are full-length so they can be stored in
        % the VariableDescriptions property appropriately if truncation has
        % to happen later.
        variableNames(isAttribute) = matlab.lang.makeUniqueStrings(variableNames(isAttribute));
    else
        % ReadVariableNames == false
        numvars = numel(variableNames);
        variableNames = compose("Var%d", 1:numvars);
    end

    % Append the attributeSuffix
    if ~ismissing(attributeSuffix)
        variableNames(isAttribute) = variableNames(isAttribute) + attributeSuffix;
    end
end

function [rowNamesSelector, detectedOpts] = getRowNamesSelector(readRowNames, rowNamesSelector, detectedOpts)
    if readRowNames
        % only modify rowNamesSelector and detectedOpts
        % if readRowNames is true
        if ismissing(rowNamesSelector)
            % The RowNamesSelector nv-pair was not supplied, so use the
            % first detected "variable" as the row names selector.
            if ~isempty(detectedOpts.VariableSelectors)
                rowNamesSelector = detectedOpts.VariableSelectors(1);
                detectedOpts.VariableSelectors(1) = [];
                detectedOpts.VariableTypes(1) = [];
                detectedOpts.VariableNames(1) = [];
            else
                % zero variables were detected, so set rowNamesSelector to
                % missing
                rowNamesSelector = string(missing);
            end
        end
    end
end


function assertMutualNodeNameVsSelectors(supplied)
    if supplied.VariableNodeNames && supplied.VariableSelectors
        % Can't use the loop below because of the plural
        error(message("MATLAB:io:xml:detection:MutuallyExclusiveParameters","VariableNodeNames","VariableSelectors"));
    end
    for p = ["Table","Row"]
        nn = p + "NodeName";
        s = p + "Selector";
        if supplied.(nn) && supplied.(s)
            error(message("MATLAB:io:xml:detection:MutuallyExclusiveParameters",nn,s));
        end
    end
end

function checkWrongParamsWrongType(supplied)
    persistent params
    if isempty(params)

            me = { ...
                ?matlab.io.internal.shared.DelimitedTextInputs, ...
                ?matlab.io.internal.shared.FixedWidthInputs, ...
                ?matlab.io.internal.shared.TextInputs,...
                ?matlab.io.internal.shared.SpreadsheetInputs, ...
                ?matlab.io.json.internal.read.parameter.ParsingModeProvider ...
                ?matlab.io.json.internal.read.parameter.JSONParsingInputs, ...
                ?matlab.io.internal.parameter.RowParametersProvider, ...
                ?matlab.io.internal.parameter.SpanHandlingProvider, ...
                ?matlab.io.internal.parameter.ColumnParametersProvider, ...
                ?matlab.io.internal.shared.RangeInput ...
            };

            for i = 1:numel(me)
                params{i} = string({me{i}.PropertyList([me{i}.PropertyList.Parameter]).Name});
            end
        params = ["Encoding", "ExpectedNumVariables", "MultipleDelimsAsOne", "NumHeaderLines", params{:}];
    end
    matlab.io.internal.utility.assertUnsupportedParamsForFileType(params,supplied,'xml')
end

function tf = suppliedDetectHints(supplied)
    suppliedHints = [supplied.TableNodeName, supplied.TableSelector,...
        supplied.RowNodeName, supplied.TableNodeName,...
        supplied.VariableNodeNames, supplied.VariableSelectors];
    tf = any(suppliedHints);
end
