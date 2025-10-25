function [T, reader] = parquetread2(filename, opts, ttOpts, args, rowgroupsArg)
%parquetread2   Read a table or timetable from a Parquet file.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        filename
        opts = []
        ttOpts.RowTimes
        ttOpts.SampleRate
        ttOpts.StartTime
        ttOpts.TimeStep
        args.VariableNames
        args.SelectedVariableNames
        args.OutputType
        args.VariableNamingRule
        args.PreserveVariableNames
        args.RowFilter
        rowgroupsArg.RowGroups
    end

    import matlab.io.parquet.internal.makeParquetReadCacher
    reader = makeParquetReadCacher(filename);

    [opts, ttOpts] = makeParquetImportOptions(reader, opts, args, ttOpts);

    rowgroups = listRowGroups(rowgroupsArg, reader);

    reader = applyPredicatePushdown(reader, opts);
    reader = applyProjectionPushdown(reader, opts);

    T = readFromParquetReader(reader, opts, rowgroups);

    T = applyTimetableOpts(T, ttOpts);
end

function [opts, ttOpts] = makeParquetImportOptions(reader, opts, args, ttOpts)
    if isa(opts, "matlab.io.parquet.internal.ParquetImportOptions")
        % ImportOptions was already passed in. Return early without parsing
        % args.
        return;
    end

    % No ParquetImportOptions provided as input. Generate a new one.
    [args, ttOpts] = resolveRowTimesArg(args, ttOpts);
    args = namedargs2cell(args);
    
    import matlab.io.parquet.internal.detectParquetImportOptions
    opts = detectParquetImportOptions(reader, args{:});
end

function rowgroups = listRowGroups(rowgroupsArg, reader)
    import matlab.io.parquet.internal.validators.validateRowGroups

    if isfield(rowgroupsArg, "RowGroups")
        % Validate and return.
        rowgroups = validateRowGroups(rowgroupsArg.RowGroups, reader.InternalReader);
    else
        % Just return 1:NumRowGroups.
        rowgroups = 1:reader.InternalReader.NumRowGroups;
    end
end

function reader = applyPredicatePushdown(reader, opts)

    isDefaultFilter = opts.TabularBuilder.IsTrivialFilter;
    isTrivialFilter = @(filter) numel(constrainedVariableNames(filter)) == 0;
    isFilteringAlreadyDone = reader.IsRowGroupFilteringDone;

    if isDefaultFilter || isTrivialFilter(opts.TabularBuilder.OriginalRowFilter) || isFilteringAlreadyDone
        return; % No additional disk filtering to be done.
    end

    % filterRowGroups needs variable names from the original file. Map
    % these names and cache them.
    if isTrivialFilter(reader.ParquetFileRowFilter)
        parquetFileSelectedVariableNames = opts.ParquetFileVariableNames(opts.TabularBuilder.SelectedVariableIndices);
        reader.ParquetFileRowFilter = replaceVariableNames(opts.TabularBuilder.OriginalRowFilter, opts.TabularBuilder.OriginalSelectedVariableNames, parquetFileSelectedVariableNames);
    end

    import matlab.io.parquet.internal.filter.filterRowGroups
    rowgroups = 1:reader.InternalReader.NumRowGroups;
    rowgroups = filterRowGroups(reader, reader.ParquetFileRowFilter, rowgroups, reader.InternalReader);

    % Cache the filtered rowgroup list so that it can be re-used on
    % subsequent reads by the datastore.
    reader.selectRowGroups(rowgroups);
end

function reader = applyProjectionPushdown(reader, opts)
    internalReader = reader.InternalReader;
    parquetFileSelectedVariableNames = opts.ParquetFileVariableNames(opts.TabularBuilder.SelectedVariableIndices);

    % For performance, only set this when the names don't already match.
    if ~isequaln(internalReader.SelectedVariableNames, parquetFileSelectedVariableNames)
        internalReader.SelectedVariableNames = parquetFileSelectedVariableNames;
    end

    % Avoid a potentially expensive setdiff() if all names were found.
    if numel(internalReader.SelectedVariableNames) == numel(parquetFileSelectedVariableNames)
        return;
    end

    % Error if all requested names were not found in the file.
    missingSelectedVariables = setdiff(parquetFileSelectedVariableNames, internalReader.SelectedVariableNames);
    if ~isempty(missingSelectedVariables)
        % Some selected variables could not be found in this file.
        msgID = "MATLAB:io:parquet:validation:SelectedVariableNotFound";
        variables = strjoin(missingSelectedVariables, ", ");
        error(message(msgID, variables, string(reader.Filename)));
    end
end

function T = readFromParquetReader(reader, opts, rowgroups)

    % Narrow the rowgroups list based on the rowfilter.
    if reader.IsRowGroupFilteringDone
        rowgroupsToReadMask = ismember(rowgroups, reader.FilteredRowGroups);
        rowgroups = rowgroups(rowgroupsToReadMask);

        % Just return the cached empty if there are no rowgroups to
        % that match the filter condition.
        if isempty(rowgroups)
            T = cacheEmptyTableSchema(reader, opts);
            return;
        end
    end

    mlarrowData = reader.InternalReader.readRowGroups(rowgroups);

    T = unwrapAndBuildTable(mlarrowData, opts.TabularBuilder, opts.ArrowTypeConversionOptions);
end

function T = cacheEmptyTableSchema(reader, opts)

    % Return the cached empty table if it was already stored.
    if width(reader.TableSchema) > 0
        T = reader.TableSchema;
        return;
    end

    % Cache an empty table, which is useful to avoid
    % re-reading and marshaling skipped rowgroups.
    mlarrowData = reader.InternalReader.readRowGroups(double.empty(0, 1));
    T = unwrapAndBuildTable(mlarrowData, opts.TabularBuilder, opts.ArrowTypeConversionOptions);
    reader.TableSchema = T;
end

function T = unwrapAndBuildTable(mlarrowData, builder, arrowOpts)

    % Call into mlarrow to convert to MATLAB datatypes.
    % Set assembleTable to false to reduce table construction overhead.
    C = matlab.io.arrow.arrow2matlab(mlarrowData, builder.PreserveVariableNames, arrowOpts, false);

    % Call into TabularBuilder/buildSelected.
    T = builder.buildSelected(C{:});
end

function T = applyTimetableOpts(T, ttOpts)
    if numel(fieldnames(ttOpts)) > 0
        ttOpts = namedargs2cell(ttOpts);
        T = table2timetable(T, ttOpts{:});
    end
end

function [builderOpts, t2ttOpts] = resolveRowTimesArg(builderOpts, t2ttOpts)
    % RowTimes could potentially be handled by either TimetableBuilder or
    % by table2timetable. It needs to be placed in the correct opts struct
    % depending on its datatype.
    mustUseTable2Timetable = any(isfield(t2ttOpts, ["StartTime" "SampleRate" "TimeStep"])) ...
                          || (isfield(t2ttOpts, "RowTimes") && (isdatetime(t2ttOpts.RowTimes) || isduration(t2ttOpts.RowTimes)));

    if mustUseTable2Timetable
        % Force TabularBuilder to read a table so that table2timetable can
        % be called later.
        builderOpts.OutputType = "table";
    else
        % Either no timetable conversion param provided, or just RowTimes provided.
        if isfield(t2ttOpts, "RowTimes")
            % Move RowTimes to the TabularBuilder opts struct.
            builderOpts.RowTimes = t2ttOpts.RowTimes;
            t2ttOpts = rmfield(t2ttOpts, "RowTimes");
        end
    end
end