classdef varNamesWithEventsDim < matlab.internal.tabular.private.varNamesDim
    %VARNAMESWITHEVENTSDIM Internal class to represent a eventtable's variables dimension.

    % This class is for internal use only and will change in a
    % future release.  Do not use this class.

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties(GetAccess=public, SetAccess=private)
        eventLabelsVariable = [];
        eventLengthsVariable = [];
        eventEndsVariable = [];

        % These properties are not Dependent (even though they could be) for
        % performance reasons. These need to be checked frequently and checking
        % for a logical property is faster than doing an isempty on the
        % event*Variable property. Since the SetAccess is private, we can easily
        % maintain the correct state for these whenever any of the above
        % properties are set/unset.
        hasEventLabels = false;
        hasEventLengths = false;
        hasEventEnds = false;
    end

    properties(Dependent)
        % The labels/lengths/ends var names in eventLabelsVariable, etc. work as subscripts for
        % those tagged vars regardless of those vars' positions in the event table; they can be
        % moved but the names are still valid. On the other hand, these index properties would
        % need to be kept in sync if the tagged vars move. Instead they are dependent.
        eventLabelsIdx;
        eventLengthsIdx;
        eventEndsIdx;
    end

    %===========================================================================
    methods
        function obj = varNamesWithEventsDim(varDim)
          obj = moveProps(obj,varDim,1:varDim.length,1:varDim.length);
          obj.labels = varDim.labels;
          obj.length = varDim.length;
        end

        %-----------------------------------------------------------------------
        function obj = createLike(obj,varargin)
            obj = obj.createLike@matlab.internal.tabular.private.varNamesDim(varargin{:});
            obj.eventLabelsVariable = [];
            obj.hasEventLabels = false;
            obj.eventLengthsVariable = [];
            obj.hasEventLengths = false;
            obj.eventEndsVariable = [];
            obj.hasEventEnds = false;
        end
    
        %-----------------------------------------------------------------------
        function s = getProperties(obj)
            % Same order as varNamesDim.propertyNames
            s = getProperties@matlab.internal.tabular.private.varNamesDim(obj);
            s.EventLabelsVariable = obj.eventLabelsVariable;
            s.EventLengthsVariable = obj.eventLengthsVariable;
            s.EventEndsVariable = obj.eventEndsVariable;
        end

        %-----------------------------------------------------------------------
        function obj = deleteFrom(obj,toDelete)
            obj = obj.deleteFrom@matlab.internal.tabular.private.varNamesDim(toDelete);
            obj = validateEventProps(obj);
        end

        %-----------------------------------------------------------------------
        function obj = selectFrom(obj,toSelect)
            obj = obj.selectFrom@matlab.internal.tabular.private.varNamesDim(toSelect);
            obj = validateEventProps(obj);
        end

        %-----------------------------------------------------------------------
        function target = mergeProps(target,source,fromLocs)
            target = target.mergeProps@matlab.internal.tabular.private.varNamesDim(source,fromLocs);
            % When merging two varNamesWithEventsDim, they must both either have
            % the same variables tagged as the respective Event*Variable
            % property or both of them must have that property unset. If the
            % source varDim does not have any variables then no merging/checks are
            % done, making mergeProps a no-op. If source is a vanilla varDim,
            % then we dont need to do any merging.
            if isa(source,'matlab.internal.tabular.private.varNamesWithEventsDim') && source.length > 0
                % If we are merging a tagged variable from the fromLocs of
                % source, the get its variable name, otherwise leave it as [].
                % If the tagged variable is not within the fromLocs it is
                % equivalent to that variable being unset in the source.
                if source.hasEventLabels && any(source.eventLabelsIdx == fromLocs)
                    sourceLabelsVar = source.eventLabelsVariable;
                else
                    sourceLabelsVar = [];
                end

                if source.hasEventLengths && any(source.eventLengthsIdx == fromLocs)
                    sourceLengthsVar = source.eventLengthsVariable;
                    mergingLengthsVarFromSource = true;
                else
                    sourceLengthsVar = [];
                    mergingLengthsVarFromSource = false;
                end

                if source.hasEventEnds && any(source.eventEndsIdx == fromLocs)
                    sourceEndsVar = source.eventEndsVariable;
                    mergingEndsVarFromSource = true;
                else
                    sourceEndsVar = [];
                    mergingEndsVarFromSource = false;
                end

                % EventLabelsVariable
                if ~isequal(target.eventLabelsVariable, sourceLabelsVar)
                    % source and target have different values for the
                    % EventLabelsVariable property, which means they either have
                    % different variables tagged as the labels or we have a mix
                    % of tagged and untagged EventLabelsVariable. This should
                    % result in an error.
                    error(message("MATLAB:table:cat:MergeDifferentEventVars","EventLabelsVariable"));
                end

                % EventLengthsVariable
                if ~isequal(target.eventLengthsVariable, sourceLengthsVar)
                    % source and target have different values for the
                    % EventLengthsVariable property, which means they either have
                    % different variables tagged as the lengths or we have a mix
                    % of tagged and untagged EventLengthsVariable. This should
                    % result in an error.
                    if target.hasEventEnds || mergingEndsVarFromSource
                        % This is the case where one varDim has lengths tagged
                        % and the other one has ends tagged. Throw a more
                        % specific error for this case.
                        error(message("MATLAB:table:cat:CannotMixEndsAndLengths"));
                    else
                        error(message("MATLAB:table:cat:MergeDifferentEventVars","EventLengthsVariable"));
                    end
                end

                % EventEndsVariable
                if ~isequal(target.eventEndsVariable, sourceEndsVar)
                    % source and target have different values for the
                    % EventEndsVariable property, which means they either have
                    % different variables tagged as the ends or we have a mix
                    % of tagged and untagged EventEndsVariable. This should
                    % result in an error.
                    if target.hasEventLengths || mergingLengthsVarFromSource
                        % This is the case where one varDim has lengths tagged
                        % and the other one has ends tagged. Throw a more
                        % specific error for this case.
                        error(message("MATLAB:table:cat:CannotMixEndsAndLengths"));
                    else
                        error(message("MATLAB:table:cat:MergeDifferentEventVars","EventEndsVariable"));
                    end
                end
            end
        end

        %-----------------------------------------------------------------------
        function target = moveProps(target,source,fromLocs,toLocs)
            target = target.moveProps@matlab.internal.tabular.private.varNamesDim(source,fromLocs,toLocs);
            target = target.moveEventProps(source,fromLocs,toLocs);
        end

        %-----------------------------------------------------------------------
        function target = moveEventProps(target,source,fromLocs,toLocs)
            % When moving properties from one varNamesWithEventsDim to another,
            % the general rule is that moving over a tagged variable from the
            % source's fromLocs overwrites a tagged variable in the target's
            % toLocs. We still need to check for any conflicts in the target's
            % tagged variables that arises from this move. See comments below
            % for more details.
            if isa(source,'matlab.internal.tabular.private.varNamesWithEventsDim')
                % Find out which event vars need to be moved from the source
                % varDim.
                movingLabelsVarFromSource = source.hasEventLabels && any(source.eventLabelsIdx == fromLocs);
                movingLengthsVarFromSource = source.hasEventLengths && any(source.eventLengthsIdx == fromLocs);
                movingEndsVarFromSource = source.hasEventEnds && any(source.eventEndsIdx == fromLocs);

                if movingLabelsVarFromSource % EventLabelsVariable
                    if ~target.hasEventLabels || any(target.eventLabelsIdx == toLocs)
                        % Either target does not have an EventLablesVariable or
                        % we are overwriting one that is within the toLocs. So
                        % copy that information from the source.
                        target.eventLabelsVariable = source.eventLabelsVariable;
                        target.hasEventLabels = true;
                    else % target has a labels variable outside toLocs
                        if matches(target.eventLabelsVariable, source.eventLabelsVariable)
                            % target's EventLabelsVariable is outside toLocs and
                            % we are trying to add a new EventLabelsVariable
                            % with the same name but at a different location,
                            % this means that target now contains two variables
                            % with the same name, which is an error. This would
                            % either have been caught before this or will be
                            % caught later on. Let it pass through so that
                            % caller can throw a more specific error.
                        else
                            % target now contains two different variables that
                            % both need to be tagged as the labels variables,
                            % which is an error.
                            error(message("MATLAB:table:cat:MoveDifferentEventVars","EventLabelsVariable"));
                        end
                    end
                end

                if movingLengthsVarFromSource % EventLengthsVariable
                    if target.hasEventEnds % target has EventEnds defined
                        if any(target.eventEndsIdx == toLocs)
                            % An existing EventEndsVariable within toLocs is being
                            % overwritten here, so untag that and use the
                            % source's EventLengthsVariable instead as the
                            % tagged time period variable.
                            target.eventLengthsVariable = source.eventLengthsVariable;
                            target.hasEventLengths = true;
                            target.eventEndsVariable = [];
                            target.hasEventEnds = false;
                        else
                            % target's EventEndsVariables is outside toLocs and
                            % source is trying to add an EventLengthsVariable,
                            % this is not allowed.
                            error(message("MATLAB:table:cat:CannotMixEndsAndLengths"));
                        end  
                    elseif target.hasEventLengths % target has EventLengths defined.
                        if any(target.eventLengthsIdx == toLocs)
                            % target's EventLengthsVariable is in toLocs, so that gets
                            % overwritten by source's EventLengthsVariable.
                            target.eventLengthsVariable = source.eventLengthsVariable;
                            target.hasEventLengths = source.hasEventLengths;
                        else
                            if matches(target.eventLengthsVariable, source.eventLengthsVariable)
                                % target's EventLengthsVariable is outside toLocs and
                                % we are trying to add a new EventLengthsVariable
                                % with the same name but at a different location,
                                % this means that target now contains two variables
                                % with the same name, which is an error. This would
                                % either have been caught before this or will be
                                % caught later on. Let it pass through so that
                                % caller can throw a more specific error.
                            else
                                % target now contains two different variables that
                                % both need to be tagged as the lengths variables,
                                % which is an error.
                                error(message("MATLAB:table:cat:MoveDifferentEventVars","EventLengthsVariable"));
                            end
                        end
                    else % No EventEnds or EventLengths
                        % target does not have anything tagged, so copy that
                        % over from source.
                        target.eventLengthsVariable = source.eventLengthsVariable;
                        target.hasEventLengths = true;
                    end
                end

                if movingEndsVarFromSource % EventEndsVariable
                    if target.hasEventLengths
                        % target has EventLengths defined, so it cannot have
                        % EventEnds.
                        if any(target.eventLengthsIdx == toLocs)
                            % An existing EventLengthsVariable within toLocs is
                            % being overwritten here, so untag that and use the
                            % source's EventLengthsVariable instead as the
                            % tagged time period variable.
                            target.eventEndsVariable = source.eventEndsVariable;
                            target.hasEventEnds = true;
                            target.hasEventLengths = false;
                        else
                            % target's EventLengthsVariables is outside toLocs and
                            % source is trying to add an EventEndsVariable,
                            % this is not allowed.
                            error(message("MATLAB:table:cat:CannotMixEndsAndLengths"));
                        end  
                    elseif target.hasEventEnds
                        % target has EventEnds defined.
                        if any(target.eventEndsIdx == toLocs)
                            % target's EventEndsVariable is in toLocs, so that gets
                            % overwritten by source's EventEndsVariable.
                            target.eventEndsVariable = source.eventEndsVariable;
                            target.hasEventEnds = true;
                        else
                            if matches(target.eventEndsVariable, source.eventEndsVariable)
                                % target's EventEndsVariable is outside toLocs and
                                % we are trying to add a new EventEndsVariable
                                % with the same name but at a different location,
                                % this means that target now contains two variables
                                % with the same name, which is an error. This would
                                % either have been caught before this or will be
                                % caught later on. Let it pass through so that
                                % caller can throw a more specific error.
                            else
                                % target now contains two different variables that
                                % both need to be tagged as the ends variables,
                                % which is an error.
                                error(message("MATLAB:table:cat:MoveDifferentEventVars","EventEndsVariable"));
                            end
                        end
                    else % No EventEnds or EventLengths
                        % target does not have anything tagged, so copy that
                        % information over from source.
                        target.eventEndsVariable = source.eventEndsVariable;
                        target.hasEventEnds = true;
                    end
                end
                % We might have moved certain properties but those variables
                % names might no longer exist, so call validateEventProps to
                % clear out any such assigned properties.
                target = validateEventProps(target);
            end
        end

        %-----------------------------------------------------------------------
        function target = fillEmptyProps(target,source,fromLocs,toLocs)
            target = target.fillEmptyProps@matlab.internal.tabular.private.varNamesDim(source,fromLocs,toLocs);
            % If the source contains events, move those separately. Note
            % that this condition exists here because the source might
            % *not* contain events, and we prefer to contain all
            % event-specific code in this class.
            if isa(source,"matlab.internal.tabular.private.varNamesWithEventsDim")
                target = target.moveEventProps(source,fromLocs,toLocs);
            end
        end

        %-----------------------------------------------------------------------
        function obj = copyEventProps(obj,source)
            % COPYEVENTPROPS Copy event vars related properties from another
            % varNamesWithEventsDim object without any kind of validation.
            obj.eventLabelsVariable = source.eventLabelsVariable;
            obj.eventLengthsVariable = source.eventLengthsVariable;
            obj.eventEndsVariable = source.eventEndsVariable;
            obj.hasEventLabels = source.hasEventLabels;
            obj.hasEventLengths = source.hasEventLengths;
            obj.hasEventEnds = source.hasEventEnds;
        end

        %-----------------------------------------------------------------------
        function obj = setLabels(obj,varargin)
            obj = obj.setLabels@matlab.internal.tabular.private.varNamesDim(varargin{:});
            obj = validateEventProps(obj);
        end
    
        %-----------------------------------------------------------------------
        function obj = setEventLabelsVariable(obj, varName, tData)
            % SETEVENTLABELSVARIABLE Tag the Labels Variable in an eventtable

            if isnumeric(varName) && isequal(varName,[])
                obj.eventLabelsVariable = [];
                obj.hasEventLabels = false;
                return
            end
            try
                i = obj.subs2inds(varName);
                if ~isscalar(i)
                    error(message("MATLAB:eventtable:NonScalarEventVars","EventLabelsVariable"))
                end

                % Validate event labels variable
                matlab.internal.tabular.validateEventLabels(tData{i},"eventtable")

                obj.eventLabelsVariable = obj.labels{i};
                obj.hasEventLabels = true;
            catch ME
                throwAsCaller(ME);
            end
        end
  
        %-----------------------------------------------------------------------
        function obj = setEventLengthsVariable(obj, varName, tData, rowTimesType)
            % SETEVENTLENGTHSVARIABLE Tag the Lengths Variable in an eventtable
            if isnumeric(varName) && isequal(varName,[])
                obj.eventLengthsVariable = [];
                obj.hasEventLengths = false;
                return
            end

            try
                i =  obj.subs2inds(varName);
                if ~isscalar(i)
                    error(message("MATLAB:eventtable:NonScalarEventVars","EventLengthsVariable"))
                end

                % Validate the event lengths variable
                matlab.internal.tabular.validateEventLengths(tData{i},rowTimesType);

                obj.eventLengthsVariable = obj.labels{i};
                obj.hasEventLengths = true;
                obj.eventEndsVariable = []; % An eventtable cannot have both tagged lengths and ends.
                obj.hasEventEnds = false;
            catch ME
                throwAsCaller(ME);
            end
        end

        %-----------------------------------------------------------------------
        function obj = setEventEndsVariable(obj, varName, tData, rowTimesData)
            % SETEVENTENDSVARIABLE Tag the Ends Variable in an eventtable.
            if isnumeric(varName) && isequal(varName,[])
                obj.eventEndsVariable = [];
                obj.hasEventEnds = false;
                return
            end

            try
                i =  obj.subs2inds(varName);
                if ~isscalar(i)
                    error(message("MATLAB:eventtable:NonScalarEventVars","EventEndsVariable"))
                end

                % Validate the event ends variable
                matlab.internal.tabular.validateEventEnds(tData{i},rowTimesData);

                obj.eventEndsVariable = obj.labels{i};
                obj.hasEventEnds = true;
                obj.eventLengthsVariable = []; % An eventtable cannot have both tagged lengths and ends.
                obj.hasEventLengths = false;
            catch ME
                throwAsCaller(ME);
            end
        end
        
        %-----------------------------------------------------------------------
        function i = get.eventLabelsIdx(obj)
            if obj.hasEventLabels
                i = find(matches(obj.labels,obj.eventLabelsVariable));
            else
                i = 0;
            end
        end

        %-----------------------------------------------------------------------
        function i = get.eventLengthsIdx(obj)
            if obj.hasEventLengths
                i = find(matches(obj.labels,obj.eventLengthsVariable));
            else
                i = 0;
            end
        end

        %-----------------------------------------------------------------------
        function i = get.eventEndsIdx(obj)
            if obj.hasEventEnds
                i = find(matches(obj.labels,obj.eventEndsVariable));
            else
                i = 0;
            end
        end

        %-----------------------------------------------------------------------
        function propNames = propertyNames(obj)
            propNames = obj.propertyNames@matlab.internal.tabular.private.varNamesDim();
            propNames = [propNames;{'EventLabelsVariable'; 'EventLengthsVariable'; 'EventEndsVariable'}];
        end

        %-----------------------------------------------------------------------
        function obj = copyTags(obj,a_varDim,b_varDim,leftVars,rightVars,c_rowDim,c_data)
            % Manually copy any tagged properties that might have been 
            % missed (in a join operation). Start by copying any tagged 
            % variables from the left input if those variables are still
            % present in the output.
            a_varDimTmp = a_varDim.selectFrom(leftVars);
            if a_varDimTmp.hasEventLabels && ismember(a_varDimTmp.eventLabelsVariable,obj.labels) && ~obj.hasEventLabels
                obj = obj.setEventLabelsVariable(a_varDimTmp.eventLabelsVariable,c_data);
            end
            if a_varDimTmp.hasEventLengths && ismember(a_varDimTmp.eventLengthsVariable,obj.labels) && ~obj.hasEventLengths
                obj = obj.setEventLengthsVariable(a_varDimTmp.eventLengthsVariable,c_data,class(c_rowDim.labels));
            end
            if a_varDimTmp.hasEventEnds && ismember(a_varDimTmp.eventEndsVariable,obj.labels) && ~obj.hasEventEnds
                obj = obj.setEventEndsVariable(a_varDimTmp.eventEndsVariable,c_data,c_rowDim.labels);
            end

            if isa(b_varDim,"matlab.internal.tabular.private.varNamesWithEventsDim")
                % Error if the inputs contain incompatible tagged
                % properties.
                if (a_varDim.hasEventLengths && b_varDim.hasEventEnds) || (a_varDim.hasEventEnds && b_varDim.hasEventLengths)
                    error(message("MATLAB:table:cat:CannotMixEndsAndLengths"));
                end

                % Repeat the process with the tagged variables from the right.
                b_varDimTmp = b_varDim.selectFrom(rightVars);
                if b_varDimTmp.hasEventLabels && ismember(b_varDimTmp.eventLabelsVariable,obj.labels) && ~obj.hasEventLabels
                    obj = obj.setEventLabelsVariable(b_varDimTmp.eventLabelsVariable,c_data);
                end
                if b_varDimTmp.hasEventLengths && ismember(b_varDimTmp.eventLengthsVariable,obj.labels) && ~obj.hasEventLengths
                    obj = obj.setEventLengthsVariable(b_varDimTmp.eventLengthsVariable,c_data,class(c_rowDim.labels));
                end
                if b_varDimTmp.hasEventEnds && ismember(b_varDimTmp.eventEndsVariable,obj.labels) && ~obj.hasEventEnds
                    obj = obj.setEventEndsVariable(b_varDimTmp.eventEndsVariable,c_data,c_rowDim.labels);
                end
            end
        end
    end

    methods (Access=protected)
        function obj = validateEventProps(obj)
            % VALIDATEEVENTPROPS Checks if tagged variables still exist in
            % the eventtable when the varDim shrinks in size.

            if obj.hasEventLabels && ~matches(obj.eventLabelsVariable,obj.labels)
                obj.eventLabelsVariable = [];
                obj.hasEventLabels = false;
            end
            
            if obj.hasEventLengths && ~matches(string(obj.eventLengthsVariable),obj.labels)
                obj.eventLengthsVariable = [];
                obj.hasEventLengths = false;
            end

            if obj.hasEventEnds && ~matches(obj.eventEndsVariable,obj.labels)
                obj.eventEndsVariable = [];
                obj.hasEventEnds = false;
            end
        end

    end

end