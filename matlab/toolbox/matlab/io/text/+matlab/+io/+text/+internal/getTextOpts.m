function opts = getTextOpts(filename,emptyColType,args)
%   This function is called from readtable and detectImportOptions, and in
%   turn calls detectFormatOptions to return the datatypes, and construct the
%   Import Options object.

%   Copyright 2017-2022 The MathWorks, Inc.

    import matlab.io.internal.utility.validateAndEscapeCellStrings;
    import matlab.io.internal.utility.validateAndEscapeStrings;
    additionalArgs = {};
    detectionHints = {};
    names = fieldnames(args);

    locale = {};
    Encoding = 'UTF-8';
    numVars = [];
    readVarNames = true;
    for f = 1 : size(names,1)
        if strcmpi(names{f},'DatetimeLocale')
            locale = args.DatetimeLocale;
        elseif strcmpi(names{f},'Encoding')
            Encoding = args.Encoding;
        elseif strcmpi(names{f},'NumHeaderLines')
            if ~isempty(args.NumHeaderLines)
                detectionHints{end + 1} = 'NumHeaderLines'; %#ok<*AGROW>
                detectionHints{end + 1} = args.NumHeaderLines;
            end
        elseif strcmpi(names{f},'NumVariables')
            numVars = args.NumVariables;
            if ~isempty(numVars)
                detectionHints{end + 1} = 'NumVariables';
                detectionHints{end + 1} = numVars;
            end
        elseif strcmpi(names{f},'ReadVariableNames')
            readVarNames = args.(names{f});
        else
            additionalArgs{end + 1} = names{f};
            additionalArgs{end + 1} = args.(names{f});
        end
    end
    % The options need to have the property value of encoding == to 'system' if
    % a user passes in 'system', otherwise, set the ecoding specifically to
    % what was used to detect other parameters.
    useSystemEncoding = false;
    if isequal(Encoding,"system")
        useSystemEncoding = true;
        Encoding = matlab.internal.i18n.locale.default.Encoding;
    end
    
    if isempty(locale)
        locale = matlab.internal.datetime.getDefaults('locale');
    end

    BOM = matlab.io.text.internal.checkBOMFromFilename(filename);
    if ~isempty(BOM.Encoding)
        if ~any(names == "Encoding") || (args.Encoding == "system")
            % If no encoding was specified or 'system' was specified,
            % and the file contains a BOM, use the implied encoding.
            Encoding = BOM.Encoding;
        elseif ~isequal(args.Encoding, BOM.Encoding)
            % Alternatively, if an encoding was specified and it
            % conflicts with the supplied encoding, issue a warning
            matlab.io.internal.utility.warnOnBOMmismatch(BOM,args.Encoding);
        end
    end

    % detectFormatOptions returns a detection strategy struct.
    textSource = matlab.io.text.internal.TextSourceWrapper();
    matlab.io.text.internal.openTextSourceFromFile(textSource, filename, Encoding);
    strategy = matlab.io.text.internal.detectFormatOptions(textSource, ...
        detectionHints{:}, additionalArgs{:},...
        'DateLocale',locale);

    if strcmp(strategy.Mode,'Delimited')
        
        opts = matlab.io.text.DelimitedTextImportOptions(...
            'NumVariables',size(strategy.Types,2),...
            'Encoding',Encoding,...
            additionalArgs{:});
        opts.Delimiter = strategy.Delimiter;
        c = compose(opts.Delimiter); % get the actual characters, not the escape sequences
        scalar_delims = (strlength(c)==1);
        if any(scalar_delims) % Remove scalar whitespace values which were delimiters
            opts.Whitespace = setdiff(sprintf(opts.Whitespace),[c{scalar_delims}]);
        end
        
    elseif strcmp(strategy.Mode,'SpaceAligned')
        
        opts = matlab.io.text.DelimitedTextImportOptions(...
            'NumVariables',size(strategy.Types,2),...
            'Encoding',Encoding,...
            additionalArgs{:});
        opts.Delimiter = {' ','\t'};
        opts.ConsecutiveDelimitersRule = 'join';
        opts.LeadingDelimitersRule = 'ignore';
        opts.Whitespace = '\b'; %Using textscan defaults for compatibility

    elseif strcmp(strategy.Mode,'FixedWidth')
        
        opts = matlab.io.text.FixedWidthImportOptions(...
            'NumVariables',numel(strategy.Widths),...
            'Encoding',Encoding,...
            additionalArgs{:}, ...
            'VariableWidths',strategy.Widths);
        
    else % Line reader
        opts = matlab.io.text.DelimitedTextImportOptions(...
            'NumVariables',1,...
            'Encoding',Encoding,...
            additionalArgs{:});
        opts.Delimiter = {','};
        strategy.NumHeaderLines = 0;
        strategy.Types = 2;
    end

    ids = strategy.Types;
    ids(1:strategy.NumHeaderLines,:) = [];

    tdto.EmptyColumnType = emptyColType;
    tdto.DetectVariableNames = ~isfield(args,'ReadVariableNames');
    tdto.ReadVariableNames = readVarNames;
    tdto.MetaRows = [];
    tdto.DetectMetaRows = true;
    results = matlab.io.internal.detectTypes(ids,tdto);
    
    types = results.Types;
    metaRows = results.MetaRows;
    emptyColIdx = results.EmptyTrailing;
    
    index = find(ismember(types, {'hexadecimal', 'binary'}));
    if ~isempty(index)
        types(index) = {'char'};
    end
    if strcmp(strategy.Mode,'FixedWidth')
        % Collapse the total width of all trailing empty columns into the
        % width of the last non-empty column. This makes the width of the
        % last non-empty column extend to the end of the line.
        opts.VariableWidths(emptyColIdx-1) = sum(opts.VariableWidths(emptyColIdx-1:end));
        % Drop all trailing empty columns.
        opts.VariableNames(emptyColIdx:end) = [];
    end
    types(emptyColIdx:end) = [];
    opts = opts.setvartype(1:numel(types),types);


    opts.DataLines = [strategy.NumHeaderLines + 1 + metaRows, inf];
    opts.VariableNamesLine = (metaRows > 0) * (strategy.NumHeaderLines + 1);

    if (metaRows > 0)
        rdr = matlab.io.text.internal.TabularTextReader(opts,...
            struct('Filename',filename,...
                   'OutputType','table',...
                   'DateLocale',locale,...
                   'MaxRowsToRead',inf));
        numNames = numel(opts.VariableNames);
        names = matlab.lang.makeValidName(rdr.readVariableNames());
        names = matlab.lang.makeUniqueStrings(names,{'RowNames','Properties'},namelengthmax);
        idx = 1:min(numNames,numel(names));
        opts.VariableNames(idx) = names(idx);
    end

    if ~isempty(numVars)
        opts.VariableNames = opts.VariableNames(1:min([numel(opts.VariableNames),numVars]));
        opts.ExtraColumnsRule = 'ignore';
    end

    % set back to literal 'system'
    if useSystemEncoding
        opts.Encoding = 'system';
    end

end
