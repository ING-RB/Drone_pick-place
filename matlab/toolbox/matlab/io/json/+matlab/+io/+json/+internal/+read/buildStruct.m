function S = buildStruct(S, missingFillValue)
%buildStruct   Replaces the string(missing) values with missingFillValue.

%   Copyright 2023-2024 The MathWorks, Inc.

    fn = fieldnames(S);
    for i=1:numel(S)
        for j=1:numel(fn)
            field = S(i).(fn{j});
            if isstruct(field)
                % Recurse struct
                S(i).(fn{j}) = matlab.io.json.internal.read.buildStruct(field, missingFillValue);
            elseif iscell(field)
                % Recurse cell
                S(i).(fn{j}) = replaceMissingCell(field, missingFillValue);
            else
                % Check for leaf nodes to contain string(missing) and
                % replace
                S(i).(fn{j}) = makePrimitiveType(field, missingFillValue);
            end
        end
    end
end

function data = makePrimitiveType(data, missingFillValue)
    if isstring(data)
        % Replace missing/empty string with the missingFillValue
        if (isStringScalar(data) && ismissing(data))
            data = missingFillValue;
        elseif all(ismissing(data))
            % Should be a missing array, not a string array.
            N = numel(data);
            data = missingFillValue;
            data(N) = missingFillValue;
        end

    elseif isnumeric(data) || islogical(data)
        % Already has correct values, just fall-through.

    elseif isa(data, "matlab.io.struct.internal.read.DatetimeWrapper")
        data = matlab.io.xml.internal.reader.unwrapDatetime(data);

    elseif isa(data, "matlab.io.struct.internal.read.DurationWrapper")
        data = matlab.io.xml.internal.reader.unwrapDuration(data);

    end

    % readstruct reads all primitive vectors as row vectors.
    data = reshape(data, 1, []);
end

function C = replaceMissingCell(C, missingFillValue)
% Replace any cell elements with missing string using missingFillValue
    for i = 1:numel(C)
        if iscell(C{i})
            % Recurse cell
            C{i} = replaceMissingCell(C{i}, missingFillValue);
        elseif isstruct(C{i})
            % Recurse struct
            C{i} = matlab.io.json.internal.read.buildStruct(C{i}, missingFillValue);
        else
            % Check for leaf nodes to contain string(missing) and
            % replace
            C{i} = makePrimitiveType(C{i}, missingFillValue);
        end

    end
end
