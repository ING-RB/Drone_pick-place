classdef (Abstract, AllowedSubclasses = {?matlab.io.internal.builders.TableBuilder,...
        ?matlab.io.internal.builders.ArrayBuilder}) Builder
% BUILDER Declares interface for builders used by tabular data readers.

%   Copyright 2019 The MathWorks, Inc.

    methods (Abstract)
        % BUILD This method takes in the untreated data returned by a data
        %   reader as well as a list of the rows and variables that should
        %   be omitted and constructs either a table, array or cell array.
        [data] = build(builder, reader, data_untreated, omit_rows, omit_vars)   
    end
    
    methods(Static)
        function builder = getBuilder(outputType, args)
        % GETBUILDER Returns the appropriate builder based on the value of
        %   outputType. outputType can either be 'table', 'matrix' or
        %   'cell'.
            switch outputType
                case 'table'
                    builder = matlab.io.internal.builders.TableBuilder();
                case 'matrix'
                    builder = matlab.io.internal.builders.ArrayBuilder();
                otherwise % 'cell'
                    % Only CellBuilder's constructor accepts input
                    builder = matlab.io.internal.builders.CellBuilder(args);
            end
        end
       
        function extracols = processExtra(extra, height, fill, vopt)
            extradata = extra.ExtraData;
            switch vopt.Type
                case 'char'
                    fill = {fill};
                case 'string'
                    if isempty(fill)
                        fill = string(missing);
                    else
                        fill = string(fill);
                    end
                case 'datetime'
                    extradata =  matlab.io.internal.builders.Builder.processDates(extradata,...
                        vopt.DatetimeFormat,vopt.InputFormat,vopt.TimeZone);
                    stFill.Data = fill;
                    stFill.Format = '';
                    fill =  matlab.io.internal.builders.Builder.processDates(stFill,...
                        vopt.DatetimeFormat,vopt.InputFormat,vopt.TimeZone);
                case 'duration'
                    extradata = matlab.io.internal.builders.Builder.processTimes(extradata,...
                        vopt.DurationFormat,vopt.InputFormat);
                    fill = matlab.io.internal.builders.Builder.processTimes(fill,...
                        vopt.DurationFormat,vopt.InputFormat);
                case 'categorical'
                    if isempty(fill)
                        fill = categorical(missing);
                    end
                    extradata = matlab.io.internal.builders.Builder.processCats(extradata,...
                        vopt.Ordinal,vopt.Protected);
            end
            extracols = repmat(fill, height, extra.MaxColSize);
            currentElement = 1;
            for i = 1:length(extra.Rows)
                for j = 1:extra.NumElementsPerRow(i)
                    extracols(extra.Rows(i),j) = extradata(currentElement);
                    currentElement = currentElement+1;
                end
            end 
        end
        
        function data = processDates(data,fmt,inputfmt,tzID)
            % Transform dates from internal representation
            if fmt == "default" || fmt == "defaultdate"
                % mimic the behavior of datetime's constructor when the
                % nv-pair Format is supplied as "default" or "defaultdate".
                fmt = '';
            elseif fmt == "preserveinput"
                fmt = inputfmt;
                if isempty(fmt)
                    fmt = data.Format;
                end
            end
            data = datetime.fromMillis(data.Data,fmt,tzID);
        end
        
        function data = processCats(inputs,isOrdinal,isProtected)
            % Transform categorical data from internal representation
            cdata = inputs{1};
            if numel(inputs) == 2 % { cdata, category names }
                % Category names were pre-defined so the IDS are 1:N
                cats = inputs{2};
                ids  = 1:numel(cats);
            else % { cdata, ids , category names}
                ids  = inputs{2};
                cats = inputs{3};
            end
            % Optimally create the final array
            data = categorical(cdata,ids,cats,'Ordinal',isOrdinal,'Protected',isProtected);
        end

        function data = processTimes(data,fmt,inputFmt)
            % transform duration data to duration array
            if strcmp(fmt,'default')
                if isempty(inputFmt)
                    fmt = duration.getFractionalSecondsFormat(data,'hh:mm:ss');
                else
                    fmt = inputFmt;
                end
            end
            data = milliseconds(data);
            data.Format = fmt;
        end
        
        function data = removeOmittedRowsAndVars(data, omit_rows, omit_vars)
        % Removes the rows and variables that need be omitted from the data. 
            if ~isempty(omit_rows(:))
                data(omit_rows,:) = [];
            end
            if ~isempty(omit_vars(:))
                data(:,omit_vars) = [];
            end
        end
    end
end
