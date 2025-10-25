classdef DetectImportOptionsHTML < matlab.io.internal.functions.ExecutableFunction & ...
        matlab.io.xml.internal.parameter.TableSelectorProvider & ...
        matlab.io.internal.parameter.ColumnParametersProvider & ...
        matlab.io.internal.parameter.RowParametersProvider & ...
        matlab.io.internal.parameter.SpanHandlingProvider & ...
        matlab.io.internal.parameter.TableIndexProvider & ...
        matlab.io.internal.shared.HexBinaryType & ...
        matlab.io.internal.functions.TableMetaDataFromDetection
    % This class is undocumented and will change in a future release.

    %   Copyright 2021-2024 The MathWorks, Inc.

    properties
       HTMLDocument
    end
    methods
        function opts = execute(func, supplied)

            if strcmp(func.DatetimeType,'exceldatenum')
                error(message('MATLAB:textio:detectImportOptions:ExcelDateWithHTML'));
            end

            checkWrongParamsWrongType(supplied);

            assertMutualIndexVsSelector(supplied);

            if ~supplied.VariableNamingRule && ~supplied.PreserveVariableNames
                func.PreserveVariableNames = true;
            end

            htmlData = fileread(func.Filename);
            func.HTMLDocument = matlab.io.xmltree.internal.XMLTree.fromHTML(htmlData);

            detectedOpts = matlab.io.html.internal.detection.detect(func.HTMLDocument,func.getOptionsForDetection(),supplied);

            % Validate that the detected selectors are valid XPath expressions.
            % Note: Certain Unicode characters in detected XPaths can lead
            % to a validation failure.
            % This is a known limitation.
            % func.validateDetectedSelectors(supplied, detectedOpts);

            rowNamesColumn = func.RowNamesColumn;
            if supplied.ReadRowNames && func.ReadRowNames && rowNamesColumn == 0
                % User didn't define a rownamesColumn, but called readtable with ReadRowNames
                rowNamesColumn = 1;
            elseif supplied.ReadRowNames && ~func.ReadRowNames && rowNamesColumn > 0
                % User specified a RowNamesColumn, but asked readtable not to import it.
                % set the RowNames back to default
                rowNamesColumn = 0;
            end

            func.RowNamesColumn = rowNamesColumn;
            if rowNamesColumn > 0
                detectedOpts.SelectedVariables(rowNamesColumn) = false;
            end

            opts = buildOptsFromDetection(detectedOpts, supplied, func);
            % opts = func.setNonDetectionProperties(opts);
            opts = func.setVariableProps(supplied, opts);
        end
    end

    methods (Access = private)
        function st = getOptionsForDetection(func)
            st = func;
            if ismissing(st.TableSelector) || isempty(st.TableSelector)
                st.TableSelector = "(//TABLE)[" + func.TableIndex + "]";
            end
        end
    end

end

function opts = buildOptsFromDetection(detectedOpts, supplied, func)
    opts = matlab.io.html.HTMLImportOptions(...
        'NumVariables',numel(detectedOpts.VariableNames));
    forwardThese = intersect(properties(opts),properties(func));
    for k=1:numel(forwardThese)
      opts.(forwardThese{k}) = func.(forwardThese{k});
    end
    for passThrough=["VariableNamesRow","TableSelector","DataRows"]
      if isfield(detectedOpts,passThrough)
        opts.(passThrough) = detectedOpts.(passThrough);
      end
    end
    if ~supplied.VariableNamingRule && ~supplied.PreserveVariableNames
        func.PreserveVariableNames = true;
        opts.PreserveVariableNames = true;
    end

    types = cellstr(detectedOpts.Types);

    if func.HexType == "text"
        types(strcmp(types, 'hexadecimal')) = {func.TextType};
    end

    if func.BinaryType == "text"
        types(strcmp(types, 'binary')) = {func.TextType};
    end

    opts.fast_var_opts = matlab.io.internal.FastVarOpts(numel(types), types);

    opts = func.setHexOrBinaryType(supplied,opts,true);
    opts = func.setHexOrBinaryType(supplied,opts,false);

    opts.VariableNames = makeVariableNames(func, ...
        detectedOpts.VariableNames);
    opts.SelectedVariableNames = opts.VariableNames(detectedOpts.SelectedVariables);
end

function variableNames = makeVariableNames(func, variableNames)
    % Unique-ify variable names upto namelengthmax.
    if ~func.PreserveVariableNames
        variableNames = matlab.lang.makeValidName(variableNames);
    end
    variableNames = matlab.lang.makeUniqueStrings(variableNames, {}, namelengthmax);
end

function assertMutualIndexVsSelector(supplied)
    if supplied.TableIndex && supplied.TableSelector
        error(message("MATLAB:io:xml:detection:MutuallyExclusiveParameters","TableIndex","TableSelector"));
    end
end

function checkWrongParamsWrongType(supplied)
    persistent params
    if isempty(params)
        me = {?matlab.io.xml.internal.parameter.AttributeSuffixProvider,...
              ?matlab.io.xml.internal.parameter.ImportAttributesProvider,...
              ?matlab.io.xml.internal.parameter.RegisteredNamespacesProvider,...
              ?matlab.io.xml.internal.parameter.RepeatedNodeRuleProvider,...
              ?matlab.io.xml.internal.parameter.NodeNameProvider,...
              ?matlab.io.xml.internal.parameter.RowNodeNameProvider,...
              ?matlab.io.xml.internal.parameter.SelectorProvider,...
              ?matlab.io.xml.internal.parameter.RowSelectorProvider,...
              ?matlab.io.json.internal.read.parameter.JSONParsingInputs,...
              ?matlab.io.json.internal.read.parameter.ParsingModeProvider,...
              ?matlab.io.internal.shared.DelimitedTextInputs,...
              ?matlab.io.internal.shared.FixedWidthInputs,...
              ?matlab.io.internal.shared.TextInputs,...
              ?matlab.io.internal.shared.SpreadsheetInputs,...
              ?matlab.io.internal.shared.RangeInput};
        params = cell(1, numel(me));
        for i = 1:numel(me)
            params{i} = string({me{i}.PropertyList([me{i}.PropertyList.Parameter]).Name});
        end
        params = [params{:}];
        %  matlab.io.internal.shared.TextInputs defines RowNamesColumn and ExtraColumnsRule
        % as "parameter" properties. These parameters are supported for HTML files, so
        % remove them from the list of unsupported parameters.
        params(params == "RowNamesColumn" | params == "ExtraColumnsRule") = [];
        params = ["ExpectedNumVariables" "MultipleDelimsAsOne" "NumHeaderLines" params];
        params = cellstr(params);
    end
    matlab.io.internal.utility.assertUnsupportedParamsForFileType(params,supplied,'html');
end
