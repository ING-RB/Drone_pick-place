function validateEventLabels(labels,errorClass)
% VALIDATEEVENTLABELS Validates that the event labels variable has compatible
% size and type. Labels must not be timestamps, tabulars, char matrices, or
% empties.

%   Copyright 2022-2023 The MathWorks, Inc.

labelsClass = class(labels);

if isa(labels,"tabular")
    % A nested tabular variable is not allowed as the Event Labels
    % Variable.
    throwAsCaller(MException(message(append("MATLAB:",errorClass,":InvalidLabelsVariableTabular"))));
elseif matches(labelsClass,["datetime","duration","calendarDuration"])
    % datetime, duration, or calendarDuration variables are not
    % allowed as the Event Labels Variable. Creating an
    % eventfilter with these label types would be unuseable.
    throwAsCaller(MException(message(append("MATLAB:",errorClass,":InvalidLabelsVariableTime"))))
elseif isequal(labelsClass,"char")
    if ~isrow(labels)
        % char matrix values are not allowed as the Event Labels Variable.
        % String arrays should be used instead.
        throwAsCaller(MException(message(append("MATLAB:",errorClass,":InvalidLabelsVariableChar"))));
    end
elseif ~iscolumn(labels)
    % Event labels variable must be a column vector. Certain callers that
    % columnize non-column vector (e.g. eventtable ctor) for convenience, should
    % do so before calling validateEventLabels.
    throwAsCaller(MException(message(append("MATLAB:",errorClass,":InvalidLabelsVariableSize"))));
end
