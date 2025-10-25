classdef (Sealed) CellBuilder < matlab.io.internal.builders.ArrayBuilder
% CELLBUILDER constructs a cell array based on the data read from a tabular
% text file.

%   Copyright 2019-2023 The MathWorks, Inc. 
    
    properties(Access = private)
        DateLocale      % locale used for importing dates.
        DatetimeType    % output type for imported date and time data 
        DurationType    % output type of duration data 
        TextType        % type for imported text data
    end
    
    methods
        function builder = CellBuilder(args)
        % CELLBUILDER Constructs a CellBuilder. Assumes all input has been
        %   validated prior to construction.
        
            builder.DateLocale = args.DateLocale;
            builder.DatetimeType = args.DatetimeType;
            builder.DurationType = args.DurationType;
            builder.TextType = args.TextType;
        end
        
        function data = build(builder, reader, data_untreated, omit_rows, omit_vars)
        % BUILD Constructs and returns a cell array based on the untreated
        %   data.
            
            % most of the construction is done by the build method of
            % ArrayBuilder
            data = build@matlab.io.internal.builders.ArrayBuilder(builder, reader, data_untreated, omit_rows, omit_vars);
            
            % converts the array data into a cell array
            if isempty(data)
                if reader.Options.AddedExtraVar
                    data = cell.empty(0, 0);
                    return;
                end
                numVariableNames = sum(~cellfun(@isempty, reader.VariableNames));
                numSelectedIDs = numel(reader.SelectedIDs);
                data = cell.empty(0, min(numVariableNames, numSelectedIDs));
                return;
            end
            
            matdata = data_untreated{1};
            if isfield(matdata,'types')
                types = matdata.types;
                if ~isempty(types)
                    if strcmp(reader.Options.ExtraColumnsRule,'addvars')
                        [~,i] = setdiff(reader.Options.VariableNames,reader.Options.SelectedVariableNames);
                        i = i(i <= numel(types)); % Remove indicies that exceed the length of 'types'
                        types(:,i) = []; % Remove unselected types.
                    else
                        types = types(:,reader.SelectedIDs);
                    end
                end
                types = matlab.io.internal.builders.Builder.removeOmittedRowsAndVars(types,...
                    omit_rows, omit_vars);
                data = builder.convertcells(data, types);
            end
        end
        
        function data = convertcells(builder, data, types)
        % CONVERTCELLS converts each column in data to the appropriate type
        %   specified in the types array.
        
            enum.NUMBER = matlab.io.spreadsheet.internal.Sheet.NUMBER;
            enum.STRING = matlab.io.spreadsheet.internal.Sheet.STRING;
            enum.DATETIME = matlab.io.spreadsheet.internal.Sheet.DATETIME;
            enum.BOOLEAN = matlab.io.spreadsheet.internal.Sheet.BOOLEAN;
            enum.EMPTY = matlab.io.spreadsheet.internal.Sheet.EMPTY;
            enum.BLANK = matlab.io.spreadsheet.internal.Sheet.BLANK;
            enum.ERROR = matlab.io.spreadsheet.internal.Sheet.ERROR;
            enum.DURATION = matlab.io.spreadsheet.internal.Sheet.DURATION;
            
            isempt = (types == enum.EMPTY);
            isnum = (types == enum.NUMBER);
            istext = (types == enum.STRING);
            isdt = (types == enum.DATETIME);
            isdur = (types == enum.DURATION);
            isblank = (types == enum.BLANK);
            iserr = (types == enum.ERROR);
            
            % Convert numeric values
            if any(isnum,'all')
                data(isnum) = replace(data(isnum), ["d", "D"], "e");
                nums = str2double(data(isnum));
                data(isnum) = num2cell(nums);
            end
            
            % Convert text values.
            if any(istext,'all')
                if strcmp(builder.TextType,'string')
                    strings = string(data(istext));
                    data(istext) = num2cell(strings);
                end
            end
            
            % Convert datetime values.
            if any(isdt,'all')
                if strcmp(builder.DatetimeType,'datetime')
                    times = data(isdt);
                    for i = 1:length(times)
                        
                        times{i} = datetime(times{i},'locale',builder.DateLocale);
                    end
                    
                    data(isdt) = times;
                elseif strcmp(builder.TextType,'string')
                    times = string(data(isdt));
                    data(isdt) = num2cell(times);
                end
            end
            
            % Convert duration values.
            if any(isdur,'all')
                if strcmp(builder.DurationType,'duration')
                    durs = data(isdur);
                    for i = 1:length(durs)
                        durs{i} = duration(durs{i});
                    end
                    data(isdur) = durs;
                elseif strcmp(builder.TextType,'string')
                    durs = string(data(isdur));
                    data(isdur) = num2cell(durs);
                end
            end
            
            data(isblank|isempt|iserr) = {missing}; 
        end        
    end
end

