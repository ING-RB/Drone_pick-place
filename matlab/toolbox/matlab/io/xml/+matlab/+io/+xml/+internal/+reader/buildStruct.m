function S = buildStruct(S, missingFillValue)
%buildStructV2   Populates datetime, duration, and missing fields post-readstructV2.

%   Copyright 2020-2023 The MathWorks, Inc.

    fn = fieldnames(S);
    for i=1:numel(S)
        for j=1:numel(fn)
            field = S(i).(fn{j});
            if isstruct(field)
                % Recurse...
                S(i).(fn{j}) = matlab.io.xml.internal.reader.buildStruct(field, missingFillValue);
            else
                % Fix primitive datatype dimensions and unwrap datetimes, durations.
                S(i).(fn{j}) = makePrimitiveType(field, missingFillValue);
            end
        end
    end
end

function data = makePrimitiveType(data, missingFillValue)
    if isstring(data)
        % Replace missing/empty string with the missingFillValue
        if (isStringScalar(data) && ismissing(data)) || isempty(data)
            data = missingFillValue;
        end

    elseif isnumeric(data) || islogical(data)
        % Already has correct values, just fall-through.

    elseif isa(data, "matlab.io.struct.internal.read.DatetimeWrapper")
        data = matlab.io.xml.internal.reader.unwrapDatetime(data);

    elseif isa(data, "matlab.io.struct.internal.read.DurationWrapper")
        data = matlab.io.xml.internal.reader.unwrapDuration(data);

    else
        % Unexpected input datatype, error.
        msgid = "MATLAB:io:xml:common:Internal";
        error(message(msgid, "Encountered an unexpected datatype when building struct output."));
    end

    % readstruct reads all primitive vectors as row vectors.
    data = reshape(data, 1, []);
end
