function tt = syncevents(tt,defaultLabel,nvPairs)
%

% Copyright 2022-2024 The MathWorks, Inc.

arguments
    tt
    defaultLabel = []
    nvPairs.EventDataVariables
end

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.isText

if ~tt.rowDim.hasEvents
    error(message("MATLAB:eventtable:NoAttachedEvents"));
end

et = tt.rowDim.timeEvents;
[isInstant,endOrLengthVar] = hasInstantEvents(et);

% Get the subset of variables from the eventtable that need to be included in
% the output.
if isfield(nvPairs,'EventDataVariables')
    et = et(:,nvPairs.EventDataVariables);
elseif ~isInstant
    % Delete the length/end var from the eventtable.
    et.(endOrLengthVar) = [];
end

% If we are working with instant events then outerjoin will handle things from
% here. However, outerjoin cannot handle time periods, so "expand" out the
% events that happen during the times present in tt before calling outerjoin.
if ~isInstant
    et = expandEventRows(et,tt);
end

% Keep track of the location of the EventLabelsVariable in et and the number of
% variables in tt before doing the join. This info is needed if the
% defaultLabels arugment is supplied.
nvarsTT = tt.varDim.length;
labelsVarLoc = et.varDim.eventLabelsIdx;

% Convert et to a timetable and do a left outerjoin since we want to preserve
% all the rows in the timetable and only align rows in our eventtable that have
% matching event times with the timetable.
et = convertToTimetable(et);
[tt,ttLocs,eventLocs] = outerjoin(tt,et,LeftKeys=tt.metaDim.labels{1},RightKeys=et.metaDim.labels{1},Type="left");

% If defaultLabel is supplied and EventLabelsVariable is being sync'd in the
% output, then use the defaultLabel for all the non-event rows.
if ~isequal(defaultLabel,[]) && labelsVarLoc ~= 0
    labelsVarLoc = nvarsTT + labelsVarLoc;
    if isText(tt.data{labelsVarLoc}) && isScalarText(defaultLabel)
        % For text labels, the defaultLabel must be scalar text.
        if iscellstr(tt.data{labelsVarLoc})
            % Allow char row vector (or '') or scalar string defaultLabel when the
            % labels variable is a cellstr. Convert those values to a cellstr before
            % doing the assignment.
            defaultLabel = cellstr(defaultLabel);
        end
    elseif ~isscalar(defaultLabel)
        % Otherwise defaultLabel must be a scalar value.
        error(message("MATLAB:eventtable:NonScalarLabel"));
    end
    tt.data{labelsVarLoc}(eventLocs == 0) = defaultLabel;
end

% Outerjoin would have sorted the rowtimes and changed the row order. Sort
% ttLocs to figure out how tt's rows need to be reordered to get the original
% row order back. Since we are doing a left outerjoin, ttLocs should have all
% non-zero values (since the output contains all rows from tt).
[~,reord] = sort(ttLocs);
tt = tt(reord,:);

function out = expandEventRows(et,tt)
% For time period events, expand out the rows for events that occur during the
% times present in tt, so that outerjoin can align them up while joining. In
% essense it is trying to create an eventtable with instantaneous events that
% could represent the same events as the current time period eventtable, and
% then use that "instantaneous" eventtable for the outerjoin.

% Each event row might match zero or more rows in the timetable. Call
% eventtimes2inds to find out how many and what rows in the timetable match the
% event times. Use that information to create duplicate copies of the matching
% event rows. We duplicate the event row once for each unique matching row time
% in tt.
[eventTimes,eventEndTimes] = eventIntervalTimes(tt.rowDim.timeEvents); % et has the right rows but lacks some vars
rowSubsCell = tt.rowDim.eventtimes2timetablesubs(eventTimes,eventEndTimes);
ttRowTimes = tt.rowDim.labels;
etInds = [];
for i = 1:et.rowDim.length
    rowSubsCell{i} = unique(ttRowTimes(rowSubsCell{i})); % logical -> time
    etInds = [etInds; repmat(i,length(rowSubsCell{i}),1)]; %#ok<AGROW>
end
out = et(etInds,:);

% If the result is non-empty, then update the rowtimes of the eventtable to the
% matching rowtimes in the timetable. This way we can 'sync' the timetable and
% eventtable with an outerjoin.
if out.rowDim.length > 0
    rowTimes = vertcat(rowSubsCell{:});
    out.rowDim = out.rowDim.setLabels(rowTimes);
end
