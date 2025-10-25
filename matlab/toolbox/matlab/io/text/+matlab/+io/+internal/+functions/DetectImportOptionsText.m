classdef DetectImportOptionsText < matlab.io.internal.functions.ExecutableFunction ...
        & matlab.io.internal.shared.DelimitedTextInputs ...
        & matlab.io.internal.shared.FixedWidthInputs ...
        & matlab.io.internal.shared.TextInputs ...
        & matlab.io.internal.shared.TreatAsMissingInput ...
        & matlab.io.internal.shared.NumericVarOptsInputs ...
        & matlab.io.internal.functions.TableMetaDataFromDetection  ...
        & matlab.io.internal.functions.AcceptsDurationType ...
        & matlab.io.internal.shared.RangeInput ...
        & matlab.io.internal.shared.PreserveVariableNamesInput ...
        & matlab.io.internal.shared.HexBinaryType
    %
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    methods
        function opts = execute(func,supplied)
            if strcmp(func.DatetimeType,'exceldatenum')
                error(message('MATLAB:textio:detectImportOptions:ExcelDateWithText'));
            end
            
            if supplied.DataLines
                error(message('MATLAB:textio:textio:UnknownParameter','DataLines'));
            end

            % Only 'column-select' (A:B) ranges are supported
            % in conjunction with NumHeaderLines.
            if supplied.NumHeaderLines && supplied.Range && ~isColumnSelectRange(func.Range)
                error(message('MATLAB:spreadsheet:sheet:NumHeaderLinesAndRange'));
            end
            
            checkWrongParamsWrongType(supplied);
            checkDelimitedFixedWidthWrongParams(func,supplied);
            opts = func.getTextOpts(supplied);
            
            if opts.VariableNamesLine == 0
                opts = useGeneratedNames(opts,opts.RowNamesColumn);
            end
            
        end
        
        % -----------------------------------------------------------------
        function rhs = setRowNamesColumn(~,rhs)
        end
    end
    
    methods (Access=private)
        function func = removeBOM(func,supplied)
            BOM = matlab.io.text.internal.checkBOMFromFilename(char(func.LocalFileName));
            if ~isempty(BOM.Encoding)
                if ~supplied.Encoding || (func.Encoding == "system") || isempty(func.Encoding)
                    % If no encoding was specified or 'system' was specified,
                    % and the file contains a BOM, use the implied encoding.
                    func.Encoding = BOM.Encoding;
                elseif ~isequal(func.Encoding, BOM.Encoding)
                    % Alternatively, if an encoding was specified and it
                    % conflicts with the supplied encoding, issue a warning
                    matlab.io.internal.utility.warnOnBOMmismatch(BOM,func.Encoding);
                end
            end
        end

        function [opts,func] = getTextOpts(func,supplied)
            import matlab.io.internal.utility.validateAndEscapeCellStrings;
            import matlab.io.internal.utility.validateAndEscapeStrings;
            func = func.removeBOM(supplied);
            
            % The options need to have the property value of encoding == to 'system' if
            % a user passes in 'system', otherwise, set the ecoding specifically to
            % what was used to detect other parameters.
            useSystemEncoding = strcmp(func.Encoding,'system');
            if useSystemEncoding
                % Using literal 'system' encoding, preserve that, but use the real-value
                % for detection.
                lc = feature('locale');
                func.Encoding = lc.encoding;
            end
            
            opts = func.getOptsFromDetection(supplied);
            opts = func.setVarNames(opts,supplied);
            
            % set back to literal 'system'
            if supplied.Encoding && useSystemEncoding
                opts.Encoding = 'system';
            end
        end
        
        function opts = getOptsFromDetection(func,supplied)
            import matlab.io.text.*
            nRange = [inf inf inf inf];
            if supplied.Range
                % Treat Range as override to num headerlines
                nRange = func.getNumericRange();
                if nRange(1) < inf
                    func.NumHeaderLines = nRange(1)-1;
                    supplied.NumHeaderLines = true;
                end
            end
            
            % If no encoding was specified, use the auto-charset detection
            % capabilities of fopen to determine the file encoding
            if isempty(func.Encoding)
                func.Encoding = func.detectEncodingFromFilename(func.LocalFileName);
            end

            textSource = matlab.io.text.internal.TextSourceWrapper();
            matlab.io.text.internal.openTextSourceFromFile(textSource, func.LocalFileName, func.Encoding);

            s = obj2struct(func,supplied);
            s.DateLocale = func.DateLocale;
            s.LineEnding = func.LineEnding;
            s.FileType   = func.FileType;
            fields = fieldnames(s);
            if any(contains(fields,'VariableWidths'))
                s.VariableWidths = cast(s.VariableWidths,'uint64');
                s.FileType = 'fixedwidth';
            end            
          
		    strat = matlab.io.text.internal.detectFormatOptions(textSource, s);

            if strcmp(strat.Mode,'Delimited')
                opts = DelimitedTextImportOptions;
                opts.Delimiter = strat.Delimiter;
                opts.ConsecutiveDelimitersRule = func.ConsecutiveDelimitersRule;
				opts.TrailingDelimitersRule = 'ignore'; % set TrailingDelimitersRule to 'ignore' instead of its default 'keep'
                opts = func.setTextFileProperties(supplied, opts);

                c = opts.getUnescapedDelimiter(); % get the actual characters, not the escape sequences
                scalar_delims = (strlength(c)==1);
                if any(scalar_delims) % Remove scalar whitespace values which were delimiters
                    whtspc = opts.getUnescapedWhitespace();
                    whtspc(any(whtspc == [c{scalar_delims}]', 1)) = [];
                    opts = opts.setUnescapedWhitespace(whtspc);
                end
  
            elseif strcmp(strat.Mode,'SpaceAligned')
                opts = DelimitedTextImportOptions;
                opts.Delimiter = {' ','\t'};
                opts.ConsecutiveDelimitersRule = 'join';
                opts.LeadingDelimitersRule = 'ignore';
                opts.TrailingDelimitersRule = 'ignore';
                opts = func.setTextFileProperties(supplied, opts);
                
                whtspc = opts.getUnescapedWhitespace();
                whtspc(any(whtspc == char([32 9]'), 1)) = [];
                opts = opts.setUnescapedWhitespace(whtspc);                

            elseif strcmp(strat.Mode,'FixedWidth')
                varOpts = repmat(matlab.io.TextVariableImportOptions,numel(strat.Widths),1);
                opts = FixedWidthImportOptions;
                opts.VariableOptions = varOpts;
                opts.VariableWidths = strat.Widths;
                opts = func.setTextFileProperties(supplied, opts);

            else % Line reader
                opts = delimitedTextImportOptions('NumVariables', 0);
                opts = func.setTextFileProperties(supplied, opts);
                strat.NumHeaderLines = func.NumHeaderLines;
                if strcmp(strat.NumHeaderLines,"auto")
                    strat.NumHeaderLines = 0;
                end
            end
            
            ids = strat.Types;
            numidRows = size(ids,1);
            headerRows = min(numidRows,strat.NumHeaderLines);
            ids(1:headerRows,:) = [];
            
            tdto.EmptyColumnType = func.EmptyColumnType;
            tdto.DetectVariableNames =  ~supplied.ReadVariableNames;
            tdto.ReadVariableNames = func.ReadVariableNames;
            tdto.MetaRows = 0;
            tdto.DetectMetaRows = func.DetectMetaLines;
            results = matlab.io.internal.detectTypes(ids,tdto);
            
            types = results.Types;
            metaRows = results.MetaRows;
            emptyCols = results.EmptyTrailing;

            meta = func.setMetaLocations(supplied, metaRows);
            
            if strcmp(strat.Mode,'FixedWidth')
                w = opts.VariableWidths;
                nOriginal = numel(w);
                w(emptyCols-1) = sum(w(emptyCols-1:end));
                w(emptyCols:end) = [];
                opts.fast_var_opts = opts.fast_var_opts.removeVars(emptyCols:nOriginal);
                opts.VariableWidths = w;
            end
            
            keepTrailingDelims = supplied.TrailingDelimitersRule && ...
                any(strcmp(func.TrailingDelimitersRule, {'keep', 'error'}));
            
            % only remove empty columns if the TrailingDelimitersRule is
            % not supplied or not supplied as keep/error.
            if ~strcmp(strat.Mode, 'Delimited') || ~keepTrailingDelims
                types(emptyCols:end) = [];
            end
            numVars = numel(types);
            
            if supplied.Range
                startCol = nRange(2);
                if ~isfinite(startCol), startCol = 1; end
                endCol = nRange(4);
                % startRow is implicitly set via NumHeaderLines
                endRow = nRange(3);
            else
                startCol = 1;
                endCol = numVars;
                endRow = inf;
            end
            
            if func.HexType == "text"
                types(strcmp(types, 'hexadecimal')) = {func.TextType};
            end

            if func.BinaryType == "text"
                types(strcmp(types, 'binary')) = {func.TextType};
            end

            opts.fast_var_opts = matlab.io.internal.FastVarOpts(numel(types), types);
            
            opts = func.setHexOrBinaryType(supplied,opts,true);
            opts = func.setHexOrBinaryType(supplied,opts,false);

            if meta.RowNames && ~isempty(types)
                opts.RowNamesColumn = startCol;
                opts.fast_var_opts = opts.fast_var_opts.setTypes(startCol, 'char');
                opts.fast_var_opts = opts.fast_var_opts.setProps(startCol, 'Name', 'Row');
            end
            
            if ~func.DetectMetaLines
                metaRows = 0;
            end

            tabularStartLine = strat.NumHeaderLines + 1;
            dataStartLine = tabularStartLine + metaRows;

            % If the number of detected metaRows causes minDataLine to
            % exceed endRow, return an empty table
            if tabularStartLine <= endRow && dataStartLine > endRow
                opts.DataLines = missing;
            else
                opts.DataLines = [dataStartLine, endRow];
            end

            if ~meta.VarNames
                % User specified no variable names line
                varNameLine = 0;
            elseif (metaRows == 0) && meta.VarNames
                % User wanted VariableNamesLine, but none were detected, use
                % first row
                varNameLine = opts.DataLines(1);
                opts.DataLines(1) = opts.DataLines(1) + 1;
            else
                % Nothing specified or detection requested. Use the detected
                % line.
                varNameLine = (metaRows > 0) * (strat.NumHeaderLines + 1);
            end
            opts.VariableNamesLine = varNameLine;
            
            opts = func.setVariableProps(supplied,opts);
            opts = func.setFileProps(supplied,opts);
            
            activeVarIdx = min(startCol,numVars+1):min(endCol,numVars);
            if opts.RowNamesColumn > 0
                % Deselect the RowNamesColumn if set, or detected
                activeVarIdx(activeVarIdx==opts.RowNamesColumn) = [];
            end
            
            % Select the variables by number in the range provided.
            if numVars > 0 && ~isequal(activeVarIdx, 1:numVars)
                % Import Options knows when selected variables has been
                % modified, and it preserves the set, but if not modified,
                % it preserves "all" variable names as selected.
                opts.SelectedVariableNames = activeVarIdx;
            end
        end
        
        function opts = setFileProps(func,supplied,opts)
            isFW = isa(opts,'matlab.io.text.FixedWidthImportOptions');
            for prop = ["RowNamesColumn" "VariableUnitsLine" "VariableDescriptionsLine"]
                if supplied.(prop)
                    opts.(prop) = func.(prop);
                end
            end
            if supplied.EmptyLineRule,opts.EmptyLineRule = func.EmptyLineRule;end
            if supplied.ExtraColumnsRule, opts.ExtraColumnsRule = func.ExtraColumnsRule;end
            if supplied.LeadingDelimitersRule && ~isFW
                opts.LeadingDelimitersRule = func.LeadingDelimitersRule;
            end
            if supplied.TrailingDelimitersRule && ~isFW
                opts.TrailingDelimitersRule = func.TrailingDelimitersRule;
            end
            if supplied.PartialFieldRule && isFW
                opts.PartialFieldRule = func.PartialFieldRule;
            end
        end
        
        function opts = setVarNames(func,opts,supplied)
            if supplied.VariableNamesLine
                opts.VariableNamesLine = func.VariableNamesLine;
            end
            
            if (opts.VariableNamesLine > 0)
                tempOpts = opts;
                % Read all the names regardless of RANGE
                tempOpts.SelectedVariableNames = ':';
                if isa(opts,'matlab.io.text.DelimitedTextImportOptions')
                    % Set temporarily
                    if opts.ConsecutiveDelimitersRule == "error"
                        tempOpts.ConsecutiveDelimitersRule = 'split';
                    end
                    if opts.LeadingDelimitersRule == "error"
                        tempOpts.LeadingDelimitersRule = 'keep';
                    end
                end
                
                rdr = matlab.io.text.internal.TabularTextReader(tempOpts, ...
                    struct('Filename',func.LocalFileName,...
                           'OutputType','table',...
                           'DateLocale',func.DateLocale,...
                           'MaxRowsToRead',inf));
                        
                names = rdr.readVariableNames();
                
                % Avoid normalizing variable names if PreserveVariableNames
                % is set to true.
                nonEmpty = (strlength(names)>0);
                if ~opts.PreserveVariableNames
                    names(nonEmpty) = matlab.lang.makeValidName(names(nonEmpty));
                end
                
                if opts.RowNamesColumn> 0 && opts.RowNamesColumn <= numel(names)
                    % Leave RowNames as Row
                    names{opts.RowNamesColumn} = 'Row';
                end
                opts.fast_var_opts = opts.fast_var_opts.setVarNames(nonEmpty,...
                    matlab.lang.makeUniqueStrings(names(nonEmpty),'',namelengthmax));
            end
            
            if supplied.ExpectedNumVariables
                opts.VariableNames = opts.VariableNames(1:min([numel(opts.VariableNames),func.ExpectedNumVariables]));
                opts.ExtraColumnsRule = 'ignore';
            end
        end
        
        function opts = setTextFileProperties(func, supplied, opts)
            opts.Encoding = func.Encoding; % always set Encoding
            if supplied.CommentStyle
                opts.CommentStyle = func.CommentStyle;
            end
            if supplied.LineEnding
                opts.LineEnding = func.LineEnding;
            end
            if supplied.Whitespace
                opts.Whitespace = func.Whitespace;
            end
            if supplied.PreserveVariableNames
                opts.PreserveVariableNames = func.PreserveVariableNames;
            end
        end        
    end
end

function checkWrongParamsWrongType(supplied)
persistent params
if isempty(params)
    me = {?matlab.io.internal.shared.SpreadsheetInputs,...
        ?matlab.io.internal.parameter.TableIndexProvider,...
        ?matlab.io.internal.parameter.SpanHandlingProvider,...
        ?matlab.io.xml.internal.parameter.AttributeSuffixProvider,...
        ?matlab.io.xml.internal.parameter.DetectNamespacesProvider,...
        ?matlab.io.xml.internal.parameter.ImportAttributesProvider,...
        ?matlab.io.xml.internal.parameter.NodeNameProvider,...
        ?matlab.io.xml.internal.parameter.RowNodeNameProvider,...
        ?matlab.io.xml.internal.parameter.RegisteredNamespacesProvider,...
        ?matlab.io.xml.internal.parameter.RepeatedNodeRuleProvider,...
        ?matlab.io.xml.internal.parameter.SelectorProvider,...
        ?matlab.io.xml.internal.parameter.TableSelectorProvider,...
        ?matlab.io.xml.internal.parameter.RowSelectorProvider,...
        ?matlab.io.json.internal.read.parameter.JSONParsingInputs,...
        ?matlab.io.json.internal.read.parameter.ParsingModeProvider,...
        ?matlab.io.internal.parameter.RowParametersProvider,...
        ?matlab.io.internal.parameter.ColumnParametersProvider};
    
    params = cell(1,8);
    for i = 1:numel(me)
        params{i} = string({me{i}.PropertyList([me{i}.PropertyList.Parameter]).Name});
    end
    params = [params{:}];
end
matlab.io.internal.utility.assertUnsupportedParamsForFileType(params,supplied,'text');

end

function checkDelimitedFixedWidthWrongParams(func, supplied)
% check that unambiguous parameters are passed as input
import matlab.io.internal.utility.assertUnsupportedParamsForFileType;
if strcmp(func.FileType,'fixedwidth')
    assertUnsupportedParamsForFileType(["Delimiter","ConsecutiveDelimitersRule","LeadingDelimitersRule"],supplied,'fixedwidth');
elseif strcmp(func.FileType,'delimitedtext')
    assertUnsupportedParamsForFileType(["VariableWidths", "PartialFieldRule"],supplied,'delimitedtext');
end
end

function tf = isColumnSelectRange(range)
    tf = false;
    range = upper(range);
    columnSelectPattern = asManyOfPattern(characterListPattern("A", "Z")) + ":" + asManyOfPattern(characterListPattern("A", "Z"));
    if matches(range, columnSelectPattern)
        splitRange = split(string(range), ":");
        columnRangeStart = splitRange(1);
        columnRangeEnd = splitRange(2);
        if (strlength(columnRangeStart) <= strlength(columnRangeEnd)) && columnRangeStart <= columnRangeEnd
            tf = true;
        end
    end
end
