function tab = construct(tbOpts, ttbOpts, tabOpts)
%TabularBuilder.construct   Constructs a TabularBuilder from args.
%
%   tbOpts must be an args struct for TableBuilder.
%   ttbOpts must be an args struct for TimetableBuilder.
%   tabOpts must be an args struct for TabularBuilder.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        tbOpts  (1, 1) struct
        ttbOpts (1, 1) struct
        tabOpts (1, 1) struct
    end

    % Convert OutputType to either "table" or "timetable".
    outputType = validateOutputTypeAtConstruction(tabOpts, ttbOpts);

    % A TableBuilder needs to be constructed regardless of whether
    % OutputType is "table" or "timetable".
    builder = matlab.io.internal.common.builder.TableBuilder.construct(tbOpts);

    if outputType == "timetable"
        % Convert into TimetableBuilder with the rest of the options.
        args = namedargs2cell(ttbOpts);
        builder = matlab.io.internal.common.builder.TimetableBuilder(args{:}, TableBuilder=builder);
    else
        % If OutputType is not timetable, but timetable parameters were
        % specified, error out recommending the use of OutputType="timetable"
        % instead.
        if numel(fieldnames(ttbOpts)) > 0
            msgid = "MATLAB:io:common:builder:UseOutputTypeTimetable";
            error(message(msgid));
        end
    end

    % Construct the TabularBuilder and return.
    tab = matlab.io.internal.common.builder.TabularBuilder();
    tab.Options.UnderlyingBuilder = builder;
    tab.Options.OutputType = outputType;
end

function outputType = validateOutputTypeAtConstruction(tabOpts, ttbOpts)
    import matlab.io.internal.common.builder.TabularBuilder.validateOutputType

    % If OutputType isn't specified, default it to "auto".
    if ~isfield(tabOpts, "OutputType")
        tabOpts.OutputType = "auto";
    end

    % Force OutputType to be either "table" or "timetable".
    if tabOpts.OutputType == "auto"
        % Use OutputType=table if there are no timetable-related arguments.
        if numel(fieldnames(ttbOpts)) == 0
            outputType = "table";
        else
            outputType = "timetable";
        end
    else
        % Validate the user-provided input and convert to string.
        outputType = validateOutputType(tabOpts.OutputType);
    end
end