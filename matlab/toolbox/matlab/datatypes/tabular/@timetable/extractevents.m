function [et, tt] = extractevents(tt,rows,eventArgs,dataArgs)
%

% Copyright 2022-2024 The MathWorks, Inc. 

arguments
    tt timetable
    rows
    eventArgs.EventLabels
    eventArgs.EventLabelsVariable
    eventArgs.EventLengths
    eventArgs.EventLengthsVariable
    eventArgs.EventEnds
    eventArgs.EventEndsVariable
    dataArgs.EventDataVariables
    dataArgs.PreserveEventVariables
end

import matlab.internal.datatypes.isText

if isfield(dataArgs,"PreserveEventVariables")
    if ~(any(isfield(eventArgs,["EventLabelsVariable","EventLengthsVariable","EventEndsVariable"])) || ...
            isfield(dataArgs,"EventDataVariables"))
        error(message("MATLAB:eventtable:ExtracteventsMissingEventVariables"));
    elseif nargout < 2
        error(message("MATLAB:eventtable:ExtracteventsMissingSecondOutput"));
    end
end

% Get the list of variables that need to be selected from the input timetable.
eventVars = [];
dataVars = [];
if isfield(dataArgs,"EventDataVariables")
    dataVars = tt.varDim.subs2inds(dataArgs.EventDataVariables);
    eventVars = dataVars;
end
if isfield(eventArgs,"EventLabelsVariable")
    labelsVar = tt.varDim.subs2inds(eventArgs.EventLabelsVariable);
    eventVars = [labelsVar eventVars];
    if ~isText(eventArgs.EventLabelsVariable)
        % When args goes into eventtable, any numeric or logical variable
        % indices need to be varnames otherwise they point to the wrong vars in
        % the subscripted tt.
        eventArgs.EventLabelsVariable = tt.varDim.labels(labelsVar);
    end
    if any(ismember(labelsVar,dataVars))
        % labelsVar cannot be present in the dataVars
        error(message("MATLAB:eventtable:ConflictingEventAndDataVars","EventLabelsVariable"));
    end
end
if isfield(eventArgs,"EventLengthsVariable")
    lengthsVar = tt.varDim.subs2inds(eventArgs.EventLengthsVariable);
    eventVars = [lengthsVar eventVars];
    if ~isText(eventArgs.EventLengthsVariable)
        % When args goes into eventtable, any numeric or logical variable
        % indices need to be varnames otherwise they point to the wrong vars in
        % the subscripted tt.
        eventArgs.EventLengthsVariable = tt.varDim.labels(lengthsVar);
    end
    if any(ismember(lengthsVar,dataVars))
        % lengthsVar cannot be present in the dataVars
        error(message("MATLAB:eventtable:ConflictingEventAndDataVars","EventLengthsVariable"));
    end
end
if isfield(eventArgs,"EventEndsVariable")        
    endsVar = tt.varDim.subs2inds(eventArgs.EventEndsVariable);
    eventVars = [endsVar eventVars];
    if ~isText(eventArgs.EventEndsVariable)
        % When args goes into eventtable, any numeric or logical variable
        % indices need to be varnames otherwise they point to the wrong vars in
        % the subscripted tt.
        eventArgs.EventEndsVariable = tt.varDim.labels(endsVar);
    end
    if any(ismember(endsVar,dataVars))
        % endsVar cannot be present in the dataVars
        error(message("MATLAB:eventtable:ConflictingEventAndDataVars","EventEndsVariable"));
    end
end

% Convert NV pair args to a cell array. We would simply forward these to the
% call to eventtable ctor and let it handle the error checks for invalid
% combinations.
args = namedargs2cell(eventArgs);

if iscategorical(rows)
    % ROWS must be a vector with the same height as TT.
    if ~(tt.rowDim.length==length(rows) && isvector(rows))
        error(message("MATLAB:eventtable:InvalidLabelsCategorical"));
    end
    if isfield(eventArgs,"EventLabels") || isfield(eventArgs,"EventLabelsVariable")
        % Categorical inputs are used as event labels so these cannot be paired
        % with other ways of supplying event labels.
        error(message("MATLAB:eventtable:CategoricalAndLabels"));
    end
    eventRows = ~ismissing(rows);
    args = [args {"EventLabels" rows(eventRows)}];
else
    try
        eventRows = tt.subs2inds(rows,'rowDim');
    catch ME
        throw(addCause(MException(message("MATLAB:eventtable:MustBeCategoricalOrTime")),ME));
    end
end

% Call the eventtable ctor on the subset timetable with the provided eventArgs.
et = eventtable(tt(eventRows,eventVars),args{:});

if ~isfield(dataArgs,"PreserveEventVariables") || ~dataArgs.PreserveEventVariables
    % Delete all the event related variables from the original timetable.
    tt(:,eventVars) = [];
end
