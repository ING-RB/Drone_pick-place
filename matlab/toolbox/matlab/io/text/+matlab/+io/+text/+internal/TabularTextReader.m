classdef TabularTextReader < handle
%TABULARTEXTREADER Reads data from a tabular text file as a
%   table, array, or cell array.

%   Copyright 2019-2022 The MathWorks, Inc.

    properties(Access = private)
        Parser
        Builder
        Source

        Filename                            % File to read data from
        OutputType                          % Type of data to return. Can be 'table', 'matrix' or 'cell'
        DateLocale                          % Locale for reading dates

        EndOfDatalines                      % Specifies if there is more data to read
        Offset                              % File offset to start reading from
        CurrentLine                         % Last line read
        MaxRowsToRead(1, 1) double = inf    % Number of rows to read in one read call

        ReadVariableNames = false           % Specifies if variable names have been read
        ReadVariableDescriptions = false    % Specifies if variable descriptions have been read
        ReadVariableUnits = false           % Specifies if variable units have been read
    end

    properties(GetAccess = public, SetAccess = private)
        Options                             % Import options controlling data import process
        SelectedIDs                         % Indices of the selected variables to read

        RowNamesAsVariables                 % Specifies if variable containing the row names was already part of the selected variable names
        RowNamesID                          % Index of the variable containing the row names. Set to -1 if row names are not being read

        VariableNames                       % Cell array of all the variable names read
        VariableDescriptions                % Cell array of variable descriptions
        VariableUnits                       % Cell array of variable units
        NumVars                             % Number of expected variables
    end

    properties(Dependent = true, Access = {?matlab.io.text.internal.TabularTextReader,...
        ?matlab.io.internal.builders.Builder})
        SelectedVariableNames               % Returns the Selected Variable Names
    end

    methods(Access = public)
        function rdr = TabularTextReader(opts, args)
            % TABULARTEXTREADER Constructs a TabularTextReader object.

            rdr.Filename = args.Filename;
            rdr.OutputType = args.OutputType;
            rdr.DateLocale = args.DateLocale;
            rdr.MaxRowsToRead = args.MaxRowsToRead;

            if strcmpi(opts.Encoding, 'system')
                opts.Encoding = matlab.internal.i18n.locale.default.Encoding;
            elseif opts.Encoding == ""
                fid = fopen(rdr.Filename);
                if fid < 0
                    % Unable to open the file for reading the encoding, use UTF-8
                    opts.Encoding = "UTF-8";
                else
                    [~, ~, ~, opts.Encoding] = fopen(fid);
                    fclose(fid);
                end
            end

            rdr.Options = opts;
            if isscalar(rdr.Options.DataLines) ...
                && ~ismissing(rdr.Options.DataLines)
                rdr.Options.DataLines = [rdr.Options.DataLines, inf];
            end

            rdr.CurrentLine = 0;
            rdr.Offset = 0;
            rdr.EndOfDatalines = false;

            rdr.initRowNames();
            rdr.initTextParser(args);
            rdr.initTextSource(rdr.Filename, opts.Encoding);
            rdr.Builder = matlab.io.internal.builders.Builder.getBuilder(rdr.OutputType, args);
        end

        function [names, origVarNames] = readVariableNames(rdr)
        % READVARIABLENAMES Reads the variable names if the line specified
        %   is greater than 0 and if the OutputType is 'table'. This method
        %   both returns the names as a cell array and sets
        %   the VariableNames property.

            line = rdr.Options.VariableNamesLine;
            origVarNames = [];
            if line > 0 && strcmpi(rdr.OutputType, 'table')
                names = rdr.Parser.getTextLine(rdr.Source, line);
                names((numel(names)+1):rdr.NumVars) = {''};
                if numel(names) > numel(rdr.NumVars)
                    origVarNames = names;
                end
                rdr.VariableNames = names;
                names = names(rdr.SelectedIDs);
            else
                names = rdr.Options.fast_var_opts.OptionsStruct.Names;
                rdr.VariableNames = names;
                names = names(rdr.SelectedIDs);
            end
            rdr.ReadVariableNames = true;
        end

        function units = readVariableUnits(rdr)
        % READVARIABLEUNITS Reads the variable units if the
        %   line specified is greater than 0 and if the OutputType is
        %   'table'. This method both returns the units as a cell
        %   array and sets the VariableUnits property.

            line = rdr.Options.VariableUnitsLine;
            units = rdr.readMetaLine(line);
            rdr.VariableUnits = units;
            rdr.ReadVariableUnits = true;
        end

        function descr = readVariableDescriptions(rdr)
        % READVARIABLEDESCRIPTIONS Reads the variable descriptions if the
        %   line specified is greater than 0 and if the OutputType is
        %   'table'. This method both returns the descriptions as a cell
        %   array and sets the VariableDescriptions property.

            line = rdr.Options.VariableDescriptionsLine;
            descr = rdr.readMetaLine(line);
            rdr.VariableDescriptions = descr;
            rdr.ReadVariableDescriptions = true;
        end

        function [data, info] = read(rdr)
        % READ Reads data from a file according to the import options. If
        % the MaxRowsRead property is set to inf, it reads the entire file.
        % Otherwise, it reads up to MaxRowsRead from the file. The Offset
        % property specifies at what offset from the origin to start
        % reading from. The CurrentLine specifies the last line read.

            datalines = rdr.Options.DataLines;
            % If datalines is set to <missing>, do not read data from the
            % file.
            if ismissing(datalines)
                data_untreated = cell(0);
                info.EndOfDataLines = true;
            else
                datalines = updateDatalines(rdr.CurrentLine + 1, datalines);
                args = struct('DataLines',datalines,'MaxRowsRead', rdr.MaxRowsToRead, 'Offset', rdr.Offset);
                [data_untreated, rowsRead, bytesRead, EOF] = rdr.Parser.getDataLines(rdr.Source, args);

                rdr.CurrentLine = rdr.CurrentLine + rowsRead; % last line read

                % If EOF has not been reached and the last line read is less
                % than the last data line, there is more data left to read
                if ~EOF && rdr.CurrentLine < rdr.Options.DataLines(end)
                    rdr.Offset = bytesRead;
                    info.EndOfDataLines = false;
                    rdr.EndOfDatalines = false;
                else % no more data left to read
                    rdr.CurrentLine = -1;
                    rdr.Offset = -1;
                    info.EndOfDataLines = true;
                    rdr.EndOfDatalines = true;
                end
            end

            info.omitrows = rdr.Parser.getOmitRows() + 1;
            info.omitvars = find(ismember(rdr.SelectedIDs, rdr.Parser.getOmitVars() + 1));

            data = rdr.Builder.build(rdr, data_untreated, info.omitrows, info.omitvars);

            % Removes the extra column if the the Variable containing row
            % names was added to the SelectedVariableNames
            omittedSize = size(data_untreated);
            if rdr.RowNamesID > 0 && ~rdr.RowNamesAsVariables
                omittedSize(2) = omittedSize(2) - 1;
            end
            info.Omitted = false(omittedSize);
            info.Omitted(:,info.omitvars) = true;
            if istable(data) && height(data)==0 && numel(data_untreated) < width(data)
                % For extra table variables convert to double.
                for i = numel(data_untreated)+1:width(data)
                    data.(i) = double.empty(0,1);
                end
            end
        end

        function reset(rdr)
        % RESET Resets the reader to its initial state so that it starts
        %   reading from the beginning of the file.

            rdr.CurrentLine = 0;
            rdr.Offset = 0;
            rdr.EndOfDatalines = false;
        end

    end

    methods
        function varNames = get.VariableNames(rdr)
        % Returns all variable names read, including any extra names.
        %   If they have not been read from the file yet, the method
        %   readVariableNames is called.
            if ~rdr.ReadVariableNames
                rdr.readVariableNames();
            end
            varNames = rdr.VariableNames;
        end

        function sVarNames = get.SelectedVariableNames(rdr)
        % Returns the selected variable names. If they have not been read
        %   from the file yet, readVariableNames is called.

            if ~rdr.ReadVariableNames
                rdr.readVariableNames();
            end
            sVarNames = rdr.VariableNames(rdr.SelectedIDs);
        end

        function varUnits = get.VariableUnits(rdr)
        % Returns the variable units. If they have not been read from the
        %   file yet, readVariableUnits is called.

            if ~rdr.ReadVariableUnits
                rdr.readVariableUnits();
            end
            varUnits = rdr.VariableUnits;
        end

        function varDescr = get.VariableDescriptions(rdr)
        % Returns the variable descriptions. If they have not been read
        %   from the file yet, readVariableDescriptions is called.

            if ~rdr.ReadVariableDescriptions
                rdr.readVariableDescriptions();
            end
            varDescr = rdr.VariableDescriptions;
        end
    end

    methods(Access = private)
        function initTextSource(rdr, fname, encoding)
            rdr.Source = matlab.io.text.internal.TextSourceWrapper();
            matlab.io.text.internal.openTextSourceFromFile(rdr.Source, fname, encoding);
        end

        function initTextParser(rdr,args)
        % INITTEXTPARSER Initializes the matlab.io.text.Parser that
        %   actually reads the text from the file.

            numVars = rdr.Options.fast_var_opts.numVars;
            rdr.Parser = rdr.Options.getParser(args);
            rdr.SelectedIDs = rdr.Options.selectedIDs;
            if numVars > 0
                if strcmp(rdr.OutputType, 'matrix') && ~isempty(rdr.SelectedIDs)
                    optionsStruct = repmat(rdr.Options.fast_var_opts.getVarOptsStruct(rdr.SelectedIDs(1)), 1, numVars);
                else
                    optionsStruct = rdr.Options.fast_var_opts.getVarOptsStruct(1:numVars);
                end
                rdr.Parser.setVariables(optionsStruct);
            end
            rdr.Parser.setSelectedVariables(rdr.SelectedIDs);
            rdr.NumVars = numVars;
        end

        function initRowNames(rdr)
        % INITROWNAMES Determines if the variable/column that contains the
        %   row names is already being read or if it needs to be added to
        %   the list of variables that are being read in.

            rowNamesID = rdr.Options.RowNamesColumn;
            if rowNamesID > 0 && strcmp(rdr.OutputType, 'table')

                % check if the variable that contains the row names is
                % within the SelectedVariableNames list.
                [isSelected, selectedID] = ismember(rdr.Options.VariableNames(rowNamesID), rdr.Options.SelectedVariableNames);
                if isSelected
                   rdr.RowNamesID = selectedID;
                   rdr.RowNamesAsVariables = true; % row name already being read
                else

                    % variable that contains the row names is not currently
                    % within the SelectedVariableNames list, so we add it
                    % as the first variable
                    rdr.Options.SelectedVariableNames = [rdr.Options.SelectedVariableNames rdr.Options.VariableNames(rowNamesID)];
                    rdr.RowNamesID = numel(rdr.Options.SelectedVariableNames);
                    rdr.RowNamesAsVariables = false;
                end
            else
                % Row names are not being read in
                rdr.RowNamesAsVariables = false;
                rdr.RowNamesID = -1;
            end

            % Modifies the VariableType of the Variable that contains
            % the row names if it is not set to 'char' or 'string'
            if rdr.Options.RowNamesColumn ~= 0 && ~any(strcmp(rdr.Options.VariableTypes(rdr.Options.RowNamesColumn),...
                    {'char', 'string'}))
                rdr.Options.VariableTypes(rdr.Options.RowNamesColumn) = {'char'};
            end
        end

        function data = readMetaLine(rdr,line)
            % reads a text meta-data line and extracts the selected IDs
            % from that line.

            if line > 0 && strcmp(rdr.OutputType, 'table')
                numVars = rdr.NumVars;
                data = repmat({''},1,numVars);
                raw_data = rdr.Parser.getTextLine(rdr.Source, line);
                % Extend or clip the data to fit the number of variables
                n = min(numel(raw_data),numVars);
                data(1:n) = raw_data(1:n);

                idx = rdr.SelectedIDs;
                % This is the number of selected variables, the metadata
                % lines should be empty, or number of elements == n
                n_act = size(data,2);
                idx(idx>n_act) = [];
                data = data(idx);
            else
                data = {};
            end
        end
    end
end

function datalines = updateDatalines(startLine, datalines)
% UPDATEDATALINES Shifts the values of datalines if we are not reading from
% the beginning of the file.
%
% For example, if the startLine is 5 and the value of datalines in the
% Import Options is [1 20; 25 inf], the datalines that should be passed to
% getDataLines() is [1 16; 21 inf] (shifted by 4)

    % ensures start line cannot be less than the first number in dataLines.
    startLine = max(startLine, datalines(1));

    % on first read, do not need to shift datalines
    if startLine == datalines(1)
        return;
    end

    temp = reshape(datalines', 1, []);
    idx = find(temp >= startLine);
    row = ceil(idx(1) / 2);

    % lines to skip to reach next interval
    linesToSkip = max(datalines(row, 1) - startLine, 0);
    datalines(1:row-1, :) = [];
    datalines = datalines - (startLine - 1);

    % accounts for the number of lines between the current line and the
    % next line of data
    datalines(1, 1) = 1 + linesToSkip;
end
