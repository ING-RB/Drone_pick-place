classdef DetectImportOptions < matlab.io.internal.functions.AcceptsReadableFilename ...
        & matlab.io.internal.functions.DetectImportOptionsText ...
        & matlab.io.internal.functions.DetectImportOptionsSpreadsheet ...
        & matlab.io.internal.functions.DetectImportOptionsXML ...
        & matlab.io.internal.functions.DetectImportOptionsHTML ...
        & matlab.io.internal.functions.DetectImportOptionsWordDocument ...
        & matlab.io.internal.functions.AcceptsDateLocale ...
        & matlab.io.internal.functions.AcceptsDatetimeTextType ...
        & matlab.io.internal.functions.AcceptsFileType ...
        & matlab.io.internal.functions.AcceptsHexBinaryType ...
        & matlab.io.internal.shared.TreatAsMissingInput ...
        & matlab.io.internal.shared.MissingErrorRulesInputs ...
        & matlab.io.internal.functions.HasAliases
    %
    
    % Copyright 2018-2024 The MathWorks, Inc.
    properties (Constant, Access = protected)
        % required by AcceptsFileType
        SupportedFileTypes = ["text", "spreadsheet", "delimitedtext", "fixedwidth", "xml", "html", "worddocument", "auto"];
    end
    
    properties (Parameter)
        % Supported by all the file types
        EmptyColumnType = 'char';
        NumHeaderLines = 'auto';
        ExpectedNumVariables = 'auto';
    end
    
    properties (Parameter, Hidden)
        EmptyValue = NaN;
        MultipleDelimsAsOne = false;
    end
    
    methods
        function v = getAliases(~)
            import matlab.io.internal.functions.ParameterAlias;
            v = [ParameterAlias("ExpectedNumVariables","NumVariables"),...
                 ParameterAlias("NumHeaderLines","HeaderLines"),...
                 ParameterAlias("TreatAsMissing","TreatAsEmpty")];
        end
    end
    
    methods
        %% Overrides ExecutableFunction to set the value of FileType
        function [func, supplied, additionalArgs] = validate(func,varargin)
            % Need to set FileType before validating the file name so we
            % will pick the correct set of extensions to match against.
            [func,varargin] = extractArg(func,"FileType",varargin,1);
            [func,varargin] = extractArg(func,"WebOptions",varargin,1);
            % Delay selector validation till after FileType is set.
            func.SelectorValidation = "None";

            [func, supplied, additionalArgs] = ...
                validate@matlab.io.internal.functions.ExecutableFunction(func,varargin{:});

            % Use the FileExtension to set the FileType value if its
            % provided as "auto"
            if ~supplied.FileType && matlab.io.internal.common.validators.isGoogleSheet(varargin{1})
                % check for Google sheets
                func.FileType = "spreadsheet";
            else
                if ~supplied.FileType || func.FileType == "auto"
                    func.FileType = func.getFileTypeFromExtension("text");
                end
            end
            
            if (supplied.PreserveVariableNames || supplied.VariableNamingRule)
                supplied.VariableNamingRule = true;
                supplied.PreserveVariableNames = true;
            end

            % Validate selectors after FileType has been resolved.
            func = func.revalidateSelectorsFromFileType(func.FileType);
        end
        
        %% Required by ExecutableFunction
        function opts = execute(func,supplied)
            % Detect the appropriate object by file type
            switch func.FileType
                case {'text','delimitedtext','fixedwidth'}
                    opts = func.execute@matlab.io.internal.functions.DetectImportOptionsText(supplied);
                case 'spreadsheet'
                    opts = func.execute@matlab.io.internal.functions.DetectImportOptionsSpreadsheet(supplied);
                case 'html'
                    if ~supplied.TextType
                        func.TextType = "string";
                    end
                    opts = func.execute@matlab.io.internal.functions.DetectImportOptionsHTML(supplied);
                case 'worddocument'
                    if ~supplied.TextType
                        func.TextType = "string";
                    end
                    opts = func.execute@matlab.io.internal.functions.DetectImportOptionsWordDocument(supplied);
                case 'xml'
                    if ~supplied.TextType
                        func.TextType = "string";
                    end
                    opts = func.execute@matlab.io.internal.functions.DetectImportOptionsXML(supplied);
            end
            
            if supplied.EmptyValue
                sfillValue = struct("FillValue", func.EmptyValue);
                idx = find(ismember(opts.fast_var_opts.Types,["double","auto"]));
                opts.fast_var_opts = opts.fast_var_opts.assignVarOptsProps(sfillValue, "FillValue", idx);
            end
            
            if supplied.MultipleDelimsAsOne
                supplied.ConsecutiveDelimitersRule = true;
                supplied.LeadingDelimitersRule = true;
            end
            
            textType = func.TextType;

            if supplied.DatetimeType
                dtType = func.DatetimeType;
                if dtType =="text"
                    dtType = textType;
                elseif dtType == "exceldatenum"
                    dtType = "double";
                end
                idx = find(opts.VariableTypes == "datetime");
                opts.fast_var_opts = opts.fast_var_opts.setTypes(idx,convertStringsToChars(dtType));
            end
            
            if supplied.DurationType
                if func.DurationType=="text"
                    dtType = textType;
                else
                    dtType = func.DurationType;
                end
                idx = find(opts.VariableTypes == "duration");
                opts.fast_var_opts = opts.fast_var_opts.setTypes(idx,convertStringsToChars(dtType));
            end
            
            % Default TextType for text and spreadsheet is char
            if supplied.TextType && (textType == "string")
                idx = find(opts.VariableTypes == "char");
                if ~isempty(idx)
                    opts.fast_var_opts = opts.fast_var_opts.setTypes(idx,"string");
                end
            end
            
            % Default TextType for XML, HTML, and Word files is string
            if supplied.TextType && (textType == "char")
                idx = find(opts.VariableTypes == "string");
                if ~isempty(idx)
                    opts.fast_var_opts = opts.fast_var_opts.setTypes(idx,"char");
                end
            end
            
            if supplied.ImportErrorRule,  opts.ImportErrorRule  = func.ImportErrorRule;  end
            if supplied.MissingRule,      opts.MissingRule      = func.MissingRule;      end
            if supplied.ExtraColumnsRule, opts.ExtraColumnsRule = func.ExtraColumnsRule; end
            
            % Set PreserveVariableNames on the generated text/spreadsheet
            % opts object, if supplied by the caller
            if (supplied.PreserveVariableNames || supplied.VariableNamingRule)
                opts.PreserveVariableNames = func.PreserveVariableNames;
            end
            
            opts = opts.setUnboundedSelection(true);
            opts = opts.useGeneratedNames(0);
        end
        
    end
    
    methods
        % -----------------------------------------------------------------
        function func = set.EmptyValue(func,rhs)
            if ~isnumeric(rhs) && ~islogical(rhs)
                error(message('MATLAB:textscan:NotNumericScalar','EmptyValue'));
            end
            func.EmptyValue = double(rhs);
        end
        % -----------------------------------------------------------------
        function func = set.NumHeaderLines(func,rhs)
            func.NumHeaderLines = matlab.io.internal.common.validateNonNegativeScalarInt(rhs);
        end
        % -----------------------------------------------------------------
        function func = set.ExpectedNumVariables(func,rhs)
            func.ExpectedNumVariables = matlab.io.internal.common.validateNonNegativeScalarInt(rhs);
        end
        % -----------------------------------------------------------------
        function func = set.EmptyColumnType(func,rhs)
            func.EmptyColumnType = validatestring(strip(rhs),{'char','double'});
        end
        % -----------------------------------------------------------------
        function func = set.MultipleDelimsAsOne(func,rhs)
            
            if ~isscalar(rhs) || ~islogical(rhs)
                error(message('MATLAB:textio:textio:ExpectedScalarLogical'));
            end
            
            func.MultipleDelimsAsOne = rhs;
            
            if rhs
                func.ConsecutiveDelimitersRule = 'join';
                func.LeadingDelimitersRule = 'ignore';
            else
                func.ConsecutiveDelimitersRule = 'split';
                func.LeadingDelimitersRule = 'keep';
            end
        end
    end
    
    methods (Access = {?matlab.io.internal.functions.DetectImportOptionsText,?matlab.io.internal.functions.DetectImportOptionsSpreadsheet,...
            ?matlab.io.internal.functions.DetectImportOptionsXML,?matlab.io.internal.functions.DetectImportOptionsHTML,...
            ?matlab.io.internal.functions.DetectImportOptionsWordDocument, ?matlab.io.internal.functions.ReadMatrix})
        % -----------------------------------------------------------------
        function opts = setVariableProps(func,supplied,opts)
            % Set the numeric only properties
            types = opts.fast_var_opts.Types;
            isNumericVar = (types == "double");
            if any(isNumericVar)
                props = ["DecimalSeparator","ThousandsSeparator","ExponentCharacter", "TrimNonNumeric"];
                props = getSuppliedProperties(props, supplied);
                if ~isempty(props)
                    opts.fast_var_opts = opts.fast_var_opts.assignVarOptsProps(func, props, isNumericVar);
                end
            end
            % Set the duration DecimalSeparator
            isDurationVar = (types == "duration");
            if supplied.DecimalSeparator && any(isDurationVar)
                opts.fast_var_opts = opts.fast_var_opts.assignVarOptsProps(func, "DecimalSeparator", isDurationVar);
            end
            
            % set the common properties which can be passed in to
            % detectImportOptions.
            props = ["TreatAsMissing","EmptyFieldRule","QuoteRule",...
                "Prefixes","Suffixes"];
            props = getSuppliedProperties(props, supplied);
            if ~isempty(props)
                opts.fast_var_opts = opts.fast_var_opts.assignVarOptsProps(func, props, 1:opts.fast_var_opts.numVars);
            end
            
            isDateVar = (types == "datetime");
            if supplied.DateLocale
                opts.DefaultDatetimeLocale = func.DateLocale;
                if any(isDateVar)
                    sDateTimeLocale = struct("DatetimeLocale", func.DateLocale);
                    opts.fast_var_opts = opts.fast_var_opts.assignVarOptsProps(sDateTimeLocale, "DatetimeLocale", isDateVar);
                end
            end
        end
    end
    
    methods (Static)
        % Error for Parameters of the wrong FileType with a more helpful
        % error message
        function assertArgsForFileTypes(filetype,supplied)
            
            switch filetype
                case 'text'
                    names = matlab.io.internal.functions.DetectImportOptionsText().ParameterNames;
                case 'spreadsheet'
                    names = matlab.io.internal.functions.DetectImportOptionsSpreadsheet().ParameterNames;
            end
            
            supplied = rmfield(supplied,[names, "Filename"]);
            matlab.io.internal.utility.assertUnsupportedParamsForFileType(fieldnames(supplied),supplied,filetype);
        end
    end
end
% =========================================================================
function suppliedProperties = getSuppliedProperties(props, supplied)
suppliedProperties = string.empty;
for i = 1:numel(props)
    if supplied.(props(i))
        suppliedProperties(end + 1) = props(i);  %#ok<AGROW>
    end
end
end
