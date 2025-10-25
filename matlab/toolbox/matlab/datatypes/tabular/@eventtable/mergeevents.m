function et = mergeevents(et1,et2)
% MERGEEVENTS Merge the event data present in two separate event tables.
% This function is for internal use only and will change in a future release.
% Do not use this function.

%   Copyright 2022 The MathWorks, Inc.

    try
        if isequaln(et1,et2)
            % If both eventtables are the same, then return one of them
            % as the output since there is no "merging" required. This
            % essentially preserves the original eventtable as it is whereas
            % calling outerjoin on the same eventtable would change it in
            % certain cases like unsorted rows, duplicate rows, etc.
            et = et1;
            return
        end

        if ~(isequal(et1.varDim.eventLabelsVariable, et2.varDim.eventLabelsVariable) ...
              && isequal(et1.varDim.eventLengthsVariable, et2.varDim.eventLengthsVariable)...
              && isequal(et1.varDim.eventEndsVariable, et2.varDim.eventEndsVariable))
            % All eventtables must have the same values for the tagged variables.
            error(message("MATLAB:eventtable:DifferentTaggedVariables"));
        end

        % The merge operation is basically doing an outerjoin on the times and
        % other variables that are common between the two eventtables. This
        % operation creates a superset eventtable that has the union of all the
        % events and event specific metadata from both the input eventtables.
        commonVars = intersect(et1.varDim.labels,et2.varDim.labels);     
        et = outerjoin(et1,et2, ...
            LeftKeys=[et1.metaDim.labels(1) commonVars], ...
            RightKeys=[et2.metaDim.labels(1) commonVars],...
            MergeKeys=true);
    
        % Manually reset vars until outerjoin is patched.
        et = setEventVars(et,et1.varDim);
    catch ME
        % Throw a general message explaining what happens in mergeevents and add
        % the actual exception from outerjoin as CausedBy to provide more
        % specific details.
        throwAsCaller(addCause(MException(message('MATLAB:eventtable:CannotMergeEvents')),ME));
    end   
end

function et = setEventVars(et,refVarDim)

    varDim = et.varDim;
    if refVarDim.hasEventLabels && matches(refVarDim.eventLabelsVariable,varDim.labels)
        varDim = varDim.setEventLabelsVariable(refVarDim.eventLabelsVariable,et.data);
    end

    if refVarDim.hasEventLengths && matches(refVarDim.eventLengthsVariable,varDim.labels)
        varDim = varDim.setEventLengthsVariable(refVarDim.eventLengthsVariable,et.data,class(et.rowDim.labels));
    end

    if refVarDim.hasEventEnds && matches(refVarDim.eventEndsVariable,varDim.labels)
        varDim = varDim.setEventEndsVariable(refVarDim.eventEndsVariable,et.data,et.rowDim.labels);
    end
    et.varDim = varDim;
end