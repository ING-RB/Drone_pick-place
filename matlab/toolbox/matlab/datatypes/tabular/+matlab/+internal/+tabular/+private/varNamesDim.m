classdef  (AllowedSubclasses = ?matlab.internal.tabular.private.varNamesWithEventsDim)  varNamesDim < matlab.internal.tabular.private.tabularDimension
    %VARNAMESDIM Internal class to represent a tabular's variables dimension.

    % This class is for internal use only and will change in a
    % future release.  Do not use this class.

    %   Copyright 2016-2023 The MathWorks, Inc.

    properties(Constant, GetAccess=public)
        labelType = "text";
        requireLabels = true;
        requireUniqueLabels = true;
        DuplicateLabelExceptionID = 'MATLAB:table:DuplicateVarNames';
        reservedNames = {'VariableNames' 'RowNames' 'Properties' ':'};
    end

    properties(GetAccess=public, SetAccess=private)
        descrs = {}
        units = {}
        continuity = []; % Empty 0x0 enum
        customProps = struct;

        % Having no descrs/units is not the same as a zero-length dimension that
        % has zero descrs/units.
        hasDescrs = false
        hasUnits = false
        hasContinuity = false
        hasCustomProps = false
    end

    properties(GetAccess=public, SetAccess=protected)
        labels
    end

    %===========================================================================
    methods
        function obj = varNamesDim(length,labels)
            import matlab.internal.datatypes.isCharStrings
            import matlab.internal.tabular.private.varNamesDim

            if nargin == 0
                length = 0;
                labels = cell(1,0);
            elseif nargin == 1
                labels = varNamesDim.dfltLabels(1:length);
            else
                % This is the relevant parts of validateAndAssignLabels
                if ~(isCharStrings(labels,true,true) && all(strlength(labels) > 0, 'all')) % require cellstr, allow whitespace but not zero-length empties
                    error(message('MATLAB:table:InvalidVarNames'));
                end
                labels = labels(:)'; % a row vector, conveniently forces any empty to 0x1
                varNamesDim.makeValidName(labels,'error');
                obj.checkDuplicateLabels(labels);
            end
            obj = obj.init(length,labels);
        end

        %-----------------------------------------------------------------------
        function obj = init(obj,dimLength,dimLabels,varDescriptions,varUnits,varContinuity,customPropStruct)

            obj = init@matlab.internal.tabular.private.tabularDimension(obj,dimLength,dimLabels);

            % Set the properties provided. For performance, first check the new
            % value is different from the current one, and avoid error checking
            % because the new values are ASSUMED already verified by the caller
            turnOffErrorCheck = true;
            if (nargin>=4) && ~isequal(obj.descrs, varDescriptions)
                obj = obj.setDescrs(varDescriptions, turnOffErrorCheck);
            end

            if (nargin>=5) && ~isequal(obj.units, varUnits)
                obj = obj.setUnits(varUnits, turnOffErrorCheck);
            end

            if (nargin>=6) && ~isequal(obj.continuity, varContinuity)
                obj = obj.setContinuity(varContinuity, turnOffErrorCheck);
            end

            if (nargin>=7)
                obj = obj.setCustomProps(customPropStruct);
            end
        end

        %-----------------------------------------------------------------------
        function obj = createLike(obj,dimLength,dimLabels,validateLabels)
            if nargin < 3
                obj = obj.createLike@matlab.internal.tabular.private.tabularDimension(dimLength);
            elseif nargin < 4
                obj = obj.createLike@matlab.internal.tabular.private.tabularDimension(dimLength,dimLabels);
            else
                obj = obj.createLike@matlab.internal.tabular.private.tabularDimension(dimLength,dimLabels,validateLabels);
            end
            obj.hasUnits = false;
            obj.units = {};
            obj.hasDescrs = false;
            obj.descrs = {};
            obj.hasContinuity = false;
            obj.continuity =  [];
            obj.hasCustomProps = false;
            obj.customProps = struct;
        end

        %-----------------------------------------------------------------------
        function labels = defaultLabels(obj,indices)
            if nargin < 2
                indices = 1:obj.length;
            end
            labels = obj.dfltLabels(indices);
        end

        %-----------------------------------------------------------------------
        function obj = lengthenTo(obj,maxIndex,newLabels)
            newIndices = (obj.length+1):maxIndex;
            if nargin < 3
                % Create default names for the new vars, making sure they don't conflict with
                % existing names.
                newLabels = obj.dfltLabels(newIndices);
                newLabels = matlab.lang.makeUniqueStrings(newLabels,obj.labels,namelengthmax);
                obj.labels(1,newIndices) = newLabels(:);
            else
                % Assume that newLabels has already been checked by validateNativeSubscripts as
                % names, and that the new names don't conflict with existing names. But still have
                % to make sure the names are legal.
                obj.makeValidName(newLabels,'error');

                obj.labels(1,newIndices) = newLabels(:);
            end
            obj.length = maxIndex;

            % Per-var properties need to be lengthened.
            if obj.hasDescrs, obj.descrs(1,newIndices) = {''}; end
            if obj.hasUnits, obj.units(1,newIndices) = {''}; end
            if obj.hasContinuity, obj.continuity(1,newIndices) = 'unset'; end
            if obj.hasCustomProps
                import matlab.internal.datatypes.defaultarrayLike
                f = fieldnames(obj.customProps);
                for i = 1:numel(f)
                    if ~isequal(size(obj.customProps.(f{i})),[0,0])
                        obj.customProps.(f{i})(1,newIndices) = defaultarrayLike([1,numel(newIndices)],'Like', obj.customProps.(f{i}),false);
                    end
                end
            end
        end

        %-----------------------------------------------------------------------
        function obj = shortenTo(obj,maxIndex)
            % Reuse deleteFrom to shorten the per-var properties.
            obj = obj.deleteFrom((maxIndex+1):obj.length);
        end

        %-----------------------------------------------------------------------
        function [indices,numIndices,maxIndex,isLiteralColon,isLabels,updatedObj] ...
                = subs2inds(obj,subscripts,subsType)
        %SUBS2INDS Convert table subscripts (labels, logical, numeric) to indices.

        import matlab.internal.datatypes.isColon

        try
            oldLength = obj.length;

            if nargin < 3, subsType = matlab.internal.tabular.private.tabularDimension.subsType_reference; end


            % Let the superclass handle the (rest of the) real work.
            [indices,numIndices,maxIndex,isLiteralColon,isLabels,updatedObj] = ...
                obj.subs2inds@matlab.internal.tabular.private.tabularDimension(subscripts,subsType);

            % We will check that any new variables are added contiguously by checking
            % that 'indices' contains an index for every variable between oldLength and
            % max(indices). For example, if oldLength is 3 and max(indices) is 6, then
            % 'indices' should contain at least 4, 5, and 6 or else the new table will
            % contain undefined variables at indices 4 and 5.
            if isnumeric(subscripts)
                if maxIndex > oldLength
                    if any(diff(unique([oldLength reshape(indices(indices>oldLength),1,[])])) > 1)
                        error(message('MATLAB:table:DiscontiguousVars'));
                    end
                end

            % Translate logical and ':' to indices, since table var indexing is not done by
            % the built-in indexing code
            elseif islogical(indices)
                indices = find(indices);

                % This check is identical to the numeric case above.
                % Merging this logical code branch into the numeric one
                % incurs an unnecessary 'islogical' call in the numeric
                % case, with an extremely small but noticeable performance
                % cost. DO NOT merge these branches unless this extra
                % cost can be avoided.
                if maxIndex > oldLength
                    if any(diff(unique([oldLength reshape(indices(indices>oldLength),1,[])])) > 1)
                        error(message('MATLAB:table:DiscontiguousVars'));
                    end
                end

            elseif isColon(indices)
                indices = 1:obj.length;
            elseif isa(indices,'matlab.internal.ColonDescriptor')
                indices = indices(:)';
            end
        catch ME
            throwAsCaller(ME)
        end
        end

        %-----------------------------------------------------------------------
            function obj = selectFrom(obj,toSelect)
                %SELECTFROM Return a subset of a tableDimProps for the specified indices.
                % The indices might be out of order or repeated, that's OK.
                obj = obj.selectFrom@matlab.internal.tabular.private.tabularDimension(toSelect);

                % Var-based or properties need to be selected. Make sure they stay
                % row vectors, even if selectFrom is empty.
                if obj.hasDescrs, obj.descrs = obj.descrs(1,toSelect); end
                if obj.hasUnits, obj.units = obj.units(1,toSelect); end
                if obj.hasContinuity, obj.continuity = obj.continuity(1,toSelect); end
                if obj.hasCustomProps
                    p = fieldnames(obj.customProps);
                    for i = 1:numel(p)
                        if ~isempty(obj.customProps.(p{i})) % leave alone props that are []
                            obj.customProps.(p{i}) = obj.customProps.(p{i})(1,toSelect);
                        end
                    end
                end
            end

            %-----------------------------------------------------------------------
            function obj = deleteFrom(obj,toDelete)
                %DELETEFROM Return a subset of a tableDimProps with the specified indices removed.
                obj = obj.deleteFrom@matlab.internal.tabular.private.tabularDimension(toDelete);

                % Var-based or properties need to be shrunk.
                if obj.hasDescrs, obj.descrs(toDelete) = []; end
                if obj.hasUnits, obj.units(toDelete) = []; end
                if obj.hasContinuity, obj.continuity(toDelete) = []; end
                if obj.hasCustomProps
                    p = fieldnames(obj.customProps);
                    for i = 1:numel(p)
                        if ~isempty(obj.customProps.(p{i}))
                            obj.customProps.(p{i})(toDelete) = [];
                        end
                    end
                end
            end

            %-----------------------------------------------------------------------
            function obj = assignInto(obj,obj2,assignInto)
                obj = obj.assignInto@matlab.internal.tabular.private.tabularDimension(obj2,assignInto);
                obj = obj.moveProps(obj2,1:obj2.length,assignInto);
            end

            %-----------------------------------------------------------------------
            function s = getProperties(obj)
                % Same order as varNamesDim.propertyNames
                s.VariableNames = obj.labels;
                s.VariableUnits = obj.units;
                s.VariableDescriptions =  obj.descrs;
                s.VariableContinuity = obj.continuity;
                s.VariableCustomProperties = obj.customProps;
            end

            %-----------------------------------------------------------------------
            function target = moveProps(target,source,fromLocs,toLocs)
                import matlab.tabular.Continuity

                if target.hasUnits
                    if source.hasUnits
                        % Replace the specified target units with the source's
                        target.units(toLocs) = source.units(fromLocs);
                    else
                        % Replace the specified target units with defaults
                        target.units(toLocs) = {''};
                    end
                elseif source.hasUnits
                    % Create property in target, assign source values into it
                    target.units = repmat({''},1,target.length);
                    target.units(toLocs) = source.units(fromLocs);
                    target.hasUnits = true;
                else
                    % Neither has units, leave it alone
                end
                if target.hasDescrs
                    if source.hasDescrs
                        % Replace the specified target descrs with the source's
                        target.descrs(toLocs) = source.descrs(fromLocs);
                    else
                        % Replace the specified target descrs with defaults
                        target.descrs(toLocs) = {''};
                    end
                elseif source.hasDescrs
                    % Create property in target, assign source descrs into it
                    target.descrs = repmat({''},1,target.length);
                    target.descrs(toLocs) = source.descrs(fromLocs);
                    target.hasDescrs = true;
                else
                    % Neither has descrs, leave it alone
                end
                if target.hasContinuity
                    if source.hasContinuity
                        % Replace the specified target descrs with the source's
                        target.continuity(toLocs) = source.continuity(fromLocs);
                    else
                        % Replace the specified target descrs with defaults
                        target.continuity(toLocs) = 'unset';
                    end
                elseif source.hasContinuity
                    % Create property in target, assign source descrs into it
                    target.continuity = repmat(Continuity.unset,1,target.length);
                    target.continuity(toLocs) = source.continuity(fromLocs);
                    target.hasContinuity = true;
                else
                    % Neither has continuity, leave it alone
                end
                % CustomProperties
                % For CustomProps in target tCP:
                % * If source also has them, just copy over for specific locations
                % * If source is empty or doesn't have property, replace with default values in
                % specific locations
                % For CustomProperties in Source but not target:
                % * create default of the right length, and copy over values
                % * If it's empty, just copy it over
                import matlab.internal.datatypes.defaultarrayLike
                tn = fieldnames(target.customProps);
                sn = fieldnames(source.customProps);
                fn = [tn; sn];
                try
                    for ii = 1:numel(fn) % in target
                        if isfield(source.customProps, fn{ii}) %  in source
                            if ~isequal(size(source.customProps.(fn{ii})),[0,0]) % not empty [] in source
                                if ~isfield(target.customProps, fn{ii}) || isequal(size(target.customProps.(fn{ii})),[0,0]) % not in target or [] in target: fill target's vars with source's default
                                    target.customProps.(fn{ii}) = defaultarrayLike([1,target.length],'like', source.customProps.(fn{ii}),false);
                                end
                                % whether or not source field is in target, now copy over source data
                                target.customProps.(fn{ii})(toLocs) = source.customProps.(fn{ii})(fromLocs);
                            else % empty [] in source
                                if ~isfield(target.customProps, fn{ii}) || isequal(size(target.customProps.(fn{ii})),[0,0]) % not in target or [] in target: create name and [] in target
                                    target.customProps.(fn{ii}) = [];
                                else % Target has data: Lengthen if necessary, filling with target defaults.
                                    target.customProps.(fn{ii})(toLocs) = defaultarrayLike([1,1],'like', target.customProps.(fn{ii}),false);
                                end
                            end
                        else % in target, not in source
                            if ~isequal(size(target.customProps.(fn{ii})),[0,0]) % Target has data: Lengthen if necessary, filling with target defaults.
                                target.customProps.(fn{ii})(toLocs) = defaultarrayLike([1,1],'like', target.customProps.(fn{ii}),false);
                                % (else: empty in target, not in source: no-op)
                            end
                        end
                    end
                catch ME
                    throw(addCause(MException(message('MATLAB:table:CustomProperties:IncompatibleTypes',class(target.customProps.(fn{ii})),class(source.customProps.(fn{ii})),fn{ii})),ME))
                end
                target.hasCustomProps = (numel(fn) > 0);
            end

            %-----------------------------------------------------------------------
            function target = mergeProps(target,source,fromLocs)
                % Copy the source's per-var properties to the target if the target
                % doesn't have them. If the source has the properties set but it is
                % an object of length zero, then fill the target's properties with
                % default values.
                import matlab.tabular.Continuity

                source_len = source.length;
                target_len = target.length;
                if ~target.hasDescrs && source.hasDescrs
                    if source_len == 0
                        newDescrs = repmat({''},1,target_len);
                    else
                        newDescrs = source.descrs(fromLocs);
                    end
                    target = target.setDescrs(newDescrs);
                end
                if ~target.hasUnits && source.hasUnits
                    if source_len == 0
                        newUnits = repmat({''},1,target_len);
                    else
                        newUnits = source.units(fromLocs);
                    end
                    target = target.setUnits(newUnits);
                end
                if ~target.hasContinuity && source.hasContinuity
                    if source_len == 0
                        newContinuity = repmat(Continuity.unset,1,target_len);
                    else
                        newContinuity = source.continuity(fromLocs);
                    end
                    target = target.setContinuity(newContinuity,false);
                end
                p = fieldnames(source.customProps);
                for ii = 1:numel(p)
                    % Only promote the source's if the target doesn't have the
                    % custom property or it's empty.
                    if ~isfield(target.customProps,p{ii}) || isequal(size(target.customProps.(p{ii})), [0,0])
                        % Handle existing but empty properties in source
                        if isempty(source.customProps.(p{ii})) % leave alone props that are []
                            target = target.setCustomProp(source.customProps.(p{ii}),p{ii});
                        else
                            target = target.setCustomProp(source.customProps.(p{ii})(fromLocs),p{ii});
                        end
                    end
                end
            end

            %-----------------------------------------------------------------------
            function target = fillEmptyProps(target,source,fromLocs,toLocs) % merge specified variable properties only
                import matlab.tabular.Continuity

                % The indices in fromLocs and toLocs may contain 0 because row
                % times can be used as a key variable in
                % join/innerjoin/outerjoin, which will be converted to 0 by
                % subs2inds before being passed in. Remove any 0s and remove
                % the corresponding index from the other indices.
                idxToDelete = (fromLocs == 0) | (toLocs == 0);
                fromLocs(idxToDelete) = [];
                toLocs(idxToDelete) = [];

                if isempty(fromLocs) || isempty(toLocs)
                    % no-op for empty to/from locs
                    return
                end

                if target.hasUnits
                    % only merge for empty target locs
                    if source.hasUnits
                        idx = cellfun(@(x)isempty(x),target.units(toLocs));
                        % Replace the specified target units with the source's
                        target.units(toLocs(idx)) = source.units(fromLocs(idx));
                    end
                elseif source.hasUnits
                    % Create property in target, assign source values into it
                    target.units = repmat({''},1,target.length);
                    target.units(toLocs) = source.units(fromLocs);
                    target.hasUnits = true;
                else
                    % Neither has units, leave it alone
                end
                if target.hasDescrs
                    if source.hasDescrs
                        idx = cellfun(@(x)isempty(x),target.descrs(toLocs));
                        % Replace the specified target descrs with the source's
                        target.descrs(toLocs(idx)) = source.descrs(fromLocs(idx));
                    end
                elseif source.hasDescrs
                    % Create property in target, assign source descrs into it
                    target.descrs = repmat({''},1,target.length);
                    target.descrs(toLocs) = source.descrs(fromLocs);
                    target.hasDescrs = true;
                else
                    % Neither has descrs, leave it alone
                end
                if target.hasContinuity
                    if source.hasContinuity
                        idx = arrayfun(@(x)(x == 'unset'),target.continuity(toLocs));
                        % Replace the specified target descrs with the source's
                        target.continuity(toLocs(idx)) = source.continuity(fromLocs(idx));
                    end
                elseif source.hasContinuity
                    % Create property in target, assign source descrs into it
                    target.continuity = repmat(Continuity.unset,1,target.length);
                    target.continuity(toLocs) = source.continuity(fromLocs);
                    target.hasContinuity = true;
                else
                    % Neither has continuity, leave it alone
                end

                import matlab.internal.datatypes.defaultarrayLike
                tn = fieldnames(target.customProps);
                sn = fieldnames(source.customProps);
                fn = [tn; sn];
                try
                    for i = 1:numel(fn)
                        if isfield(target.customProps,fn{i}) % in target
                            if isfield(source.customProps,fn{i}) && ~isequal(size(source.customProps.(fn{i})),[0,0]) % non-empty in source: find elements to move and move them.
                                idx = isEmptyElem(target.customProps.(fn{i})(toLocs));
                                % Replace the specified target customProps with the source's
                                target.customProps.(fn{i})(toLocs(idx)) = source.customProps.(fn{i})(fromLocs(idx));
                                % (else: empty or not present in source: no-op)
                            end
                        else % in source, not in target: create field in the target, assign source into it
                            if ~isequal(size(source.customProps.(fn{i})),[0,0]) % source is not []
                                target.customProps.(fn{i}) = defaultarrayLike([1,target.length],'like',source.customProps.(fn{i}));
                                target.customProps.(fn{i})(toLocs) = source.customProps.(fn{i})(fromLocs);
                            else % source is [], copy the name and [].
                                target.customProps.(fn{i}) = source.customProps.(fn{i});
                            end
                        end
                    end
                    target.hasCustomProps = (numel(fn) > 0);
                catch ME
                    throw(addCause(MException(message('MATLAB:table:CustomProperties:IncompatibleTypes',class(target.customProps.(fn{i})),class(source.customProps.(fn{i})),fn{i})),ME))
                end
            end
            
            %-----------------------------------------------------------------------
            function obj = copyTags(obj,~,~,~,~,~,~)
                % This is a no-op for table and timetable.
            end

            %-----------------------------------------------------------------------
            function obj = setDescrs(obj,newDescrs,noErrorCheck)
                if (nargin<3) || (nargin==3 && ~noErrorCheck)
                    if ~matlab.internal.datatypes.isText(newDescrs,true) % require a cell array, allow empty character vectors in that cell array
                        error(message('MATLAB:table:InvalidVarDescr'));
                    elseif ~isempty(newDescrs) && numel(newDescrs) ~= obj.length
                        error(message('MATLAB:table:IncorrectNumberOfVarDescrs'));
                    end
                end

                if isstring(newDescrs)
                    newDescrs = cellstr(newDescrs);
                end
                if obj.length == 0 && isequal(size(newDescrs),[1 0])
                    % leave a 1x0 cell alone for a table with no vars
                    obj.hasDescrs = true;
                elseif isempty(newDescrs)
                    newDescrs = {}; % for cosmetics
                    obj.hasDescrs = false;
                else
                    newDescrs = strtrim(newDescrs(:))'; % a row vector
                    obj.hasDescrs = true;
                end
                obj.descrs = newDescrs;
            end

            %-----------------------------------------------------------------------
            function obj = setCustomProp(obj,newProp,name,noErrorCheck)
                if (nargin<4) || (nargin==4 && ~noErrorCheck)
                    if isa(newProp,'tabular')
                        % Do not allow tables as a per-variable custom property.
                        % It's not really a row vector.
                        cls = class(newProp);
                        cls(1) = upper(cls(1));
                        error(message('MATLAB:table:TableAsPerVarProp',cls))
                    elseif isa(newProp,'char')
                        error(message('MATLAB:table:CharAsPerVarProp'))
                    end
                    % Require per-var prop to be a matrix.
                    % Turning it into a vector and empty cases are handled later.
                    if ~(isvector(newProp) || isequal(size(newProp), [0,0]))
                        error(message('MATLAB:table:IncorrectNumberOfVarCustomProps',name))
                    end
                end

                if obj.length == 0 && isequal(size(newProp),[1 0])
                    % leave a 1x0 cell alone for a table with no vars
                elseif isequal(size(newProp), [0 0])
                    newProp = []; % for cosmetics
                elseif numel(newProp) ~= obj.length
                    error(message('MATLAB:table:IncorrectNumberOfVarCustomProps',name))
                else
                    newProp = newProp(:)'; % row vector
                end
                obj.hasCustomProps = true;
                obj.customProps.(name) = newProp;
            end

            %-----------------------------------------------------------------------
            function obj = setCustomProps(obj,customPropStruct)
                % SETCUSTOMPROPS directly assigns customPropStruct into the
                % customProps property, updates the instance's state
                % accordingly. It does NOT perform error-check on
                % customPropStruct.
                if isstruct(customPropStruct) && isscalar(customPropStruct)
                    obj.customProps = customPropStruct;
                    obj.hasCustomProps = ~isempty(fieldnames(customPropStruct));
                end
            end

            %-----------------------------------------------------------------------
            function obj = setUnits(obj,newUnits,noErrorCheck)
                if (nargin<3) || (nargin==3 && ~noErrorCheck)
                    if ~matlab.internal.datatypes.isText(newUnits,true) % require a cell array, allow empty character vectors
                        error(message('MATLAB:table:InvalidUnits'));
                    elseif ~isempty(newUnits) && numel(newUnits) ~= obj.length
                        error(message('MATLAB:table:IncorrectNumberOfUnits'));
                    end
                end

                if isstring(newUnits)
                    newUnits = cellstr(newUnits);
                end
                if obj.length == 0 && isequal(size(newUnits),[1 0])
                    % leave a 1x0 cell alone for a table with no vars
                    obj.hasUnits = true;
                elseif isempty(newUnits)
                    newUnits = {}; % for cosmetics
                    obj.hasUnits = false;
                else
                    newUnits = strtrim(newUnits(:))'; % a row vector
                    obj.hasUnits = true;
                end
                obj.units = newUnits;
            end

            function obj = setContinuity(obj,newContinuity,noErrorCheck)
                import matlab.tabular.Continuity
                import matlab.internal.datatypes.isText

                if (nargin < 3) || ~noErrorCheck
                    if ~matlab.internal.datatypes.isText(newContinuity,true) && ...
                            ~isa(newContinuity,'matlab.tabular.Continuity') && ...
                            ~(isequal(newContinuity,[]) && isnumeric(newContinuity)) % [] is allowed for 'clearing' the entire property
                    error(message('MATLAB:table:InvalidContinuityAssignment'));
                    end

                    if ~isempty(newContinuity) && numel(newContinuity) ~= obj.length
                        error(message('MATLAB:table:IncorrectNumberOfContinuity'));
                    end
                end
                if  obj.length == 0 && isequal(size(newContinuity),[1 0])
                    obj.hasContinuity = true;
                    if isText(newContinuity,true) % char vector is not allowed
                        newContinuity = Continuity(newContinuity);
                    end

                elseif isempty(newContinuity) && (isnumeric(newContinuity) || isa(newContinuity,'matlab.tabular.Continuity') || iscell(newContinuity))
                    newContinuity = []; %convert {}, 0x0 Continuity to []
                    obj.hasContinuity = false;
                else
                    newContinuity = newContinuity(:)'; %convert everything to row vector
                    % Convert the character vectors to the enumeration class
                    if isText(newContinuity,true) % char vector is not allowed
                        try
                            newContinuity = Continuity(newContinuity);
                        catch
                            % The RHS was text, but not accepted. Throw an error that list valid
                            % values as text, and avoids mentioning matlab.tabular.Continuity.
                            error(message('MATLAB:table:InvalidContinuityValue'));
                        end
                    end
                    obj.hasContinuity = true;
                end
                obj.continuity = newContinuity;
            end

            function obj = addprop(obj,name)
                assert(~isfield(obj.customProps,name)) % Duplicate checking should already be done.
                obj.customProps.(name) = [];
                obj.hasCustomProps = true;
            end

            function obj = rmprop(obj,names)
                obj.customProps = rmfield(obj.customProps, names);
                obj.hasCustomProps = numel(fieldnames(obj.customProps)) > 0;
            end
        
            function propNames = propertyNames(obj)
                % Conceptually, VariableTypes is a per-variable property,
                % but it's implemented in tabular.
                propNames = {'VariableNames'; 'VariableDescriptions'; 'VariableUnits'; 'VariableTypes'; 'VariableContinuity'};
            end

            function tf = hasNonEmptyUnits(obj)
                % HASNONEMPTYUNITS returns a logical vector indicating which
                % variables have the VariableUnits set to a non-empty value.
                % This is mainly used by tabular math VariableUnits helpers.
                if obj.hasUnits
                    tf = strlength(obj.units) > 0;
                else
                    tf = false(1,obj.length);
                end
            end
    end

        %===========================================================================
        methods (Access=protected)
            function obj = 	validateAndAssignLabels(obj,newLabels,varIndices,fullAssignment,fixDups,fixEmpties,fixIllegal)
                import matlab.internal.datatypes.isScalarText
                import matlab.internal.datatypes.isText

                if ~fullAssignment && isScalarText(newLabels) && (fixEmpties || (newLabels ~= ""))
                    % Accept one character vector for (partial) assignment to one name, allow empty character vectors per caller.
                    newLabels = {newLabels};
                elseif isText(newLabels,true)
                    if ~fixEmpties && matches("",newLabels)
                        error(message('MATLAB:table:ZeroLengthVarname'));
                    end
                    % Accept a cellstr, allow empty character vectors per caller.
                    newLabels = newLabels(:)'; % a row vector, conveniently forces any empty to 0x1
                else
                    error(message('MATLAB:table:InvalidVarNames'));
                end

                if fixEmpties
                    % Fill in empty names if allowed, and make them unique with respect
                    % to the other new names. If not allowed, an error was already thrown.
                    % This is here to fill in missing variable names when reading from a file.
                    [newLabels,wasEmpty] = fillEmptyNames(newLabels,varIndices);
                    newLabels = matlab.lang.makeUniqueStrings(newLabels,wasEmpty,namelengthmax);
                end

                switch convertStringsToChars(fixIllegal)
                    case {true, 'fixIllegal'}
                        exceptionMode = 'warnSavedLegacy';
                    case {false, 'errorIllegal'}
                        exceptionMode = 'error';
                    case {'fixTooLong'}
                        exceptionMode = 'warnSaved';
                end
                originalLabels = newLabels;
                [newLabels,wasMadeValid] = obj.makeValidName(newLabels,exceptionMode);
                
                % The number of new labels has to match what's being assigned to.
                if fullAssignment 
                    if numel(newLabels) ~= obj.length
                        obj.throwIncorrectNumberOfLabels();
                    end
                else
                    if numel(newLabels) ~= numel(varIndices)
                        obj.throwIncorrectNumberOfLabelsPartial();
                    end
                end

                if fixDups
                    % Make the new names (in their possibly modified form) unique with respect to
                    % each other and to existing names.
                    allNewLabels = obj.labels; allNewLabels(varIndices) = newLabels;
                    allNewLabels = matlab.lang.makeUniqueStrings(allNewLabels,varIndices,namelengthmax);
                    newLabels = allNewLabels(varIndices);
                elseif fullAssignment
                    % Check that the whole set of new names is unique
                    obj.checkDuplicateLabels(newLabels);
                else
                    % Make sure invalid names that have been fixed do not duplicate any of the other new
                    % names.
                    newLabels = matlab.lang.makeUniqueStrings(newLabels,wasMadeValid,namelengthmax);
                    % Check that the new names do not duplicate each other or existing names.
                    allNewLabels = obj.labels; allNewLabels(varIndices) = newLabels;
                    obj.checkDuplicateLabels(newLabels,allNewLabels,varIndices);
                end

                obj = obj.assignLabels(newLabels,fullAssignment,varIndices);

                if startsWith(exceptionMode,'warnSaved') && any(wasMadeValid)
                    if ~obj.hasDescrs
                        obj.descrs = repmat({''},1,obj.length);
                        obj.hasDescrs = true;
                    end
                    str = getString(message('MATLAB:table:uistrings:ModifiedVarNameDescr'));
                    obj.descrs(varIndices(wasMadeValid)) = append(str, ' ''', originalLabels(wasMadeValid), '''');
                end
            end

            %-----------------------------------------------------------------------
            function obj = makeUniqueForRepeatedIndices(obj,~)
                obj.labels = matlab.lang.makeUniqueStrings(obj.labels,{},namelengthmax);
            end

            %-----------------------------------------------------------------------
            function throwRequiresLabels(~)
                throwAsCaller(MException(message('MATLAB:table:CannotRemoveVarNames')));
            end
            function throwIncorrectNumberOfLabels(~)
                throwAsCaller(MException(message('MATLAB:table:IncorrectNumberOfVarNames')));
            end
            function throwIncorrectNumberOfLabelsPartial(~)
                throwAsCaller(MException(message('MATLAB:table:IncorrectNumberOfVarNamesPartial')));
            end
            function throwIndexOutOfRange(~)
                throwAsCaller(MException(message('MATLAB:table:VarIndexOutOfRange')));
            end
            function throwUnrecognizedLabel(~,label)
                throwAsCaller(MException(message('MATLAB:table:UnrecognizedVarName',label{1})));
            end
            function throwInvalidLabel(~)
                throwAsCaller(MException(message('MATLAB:table:InvalidVarName')));
            end
            function throwInvalidSubscripts(~)
                throwAsCaller(MException(message('MATLAB:table:InvalidVarSubscript')));
            end
        end

        %===========================================================================
        methods (Static)
            function labels = dfltLabels(varIndices,oneName)
                %DFLTLABELS Default variable names for a table.
                prefix = getString(message('MATLAB:table:uistrings:DfltVarNamePrefix'));
                if nargin < 2 || ~oneName % return cellstr
                    labels = matlab.internal.datatypes.numberedNames(prefix,varIndices(:)',false); % row vector
                else % return one character vector
                    labels = matlab.internal.datatypes.numberedNames(prefix,varIndices,true);
                end
            end

            function conflicts = checkReservedNames(labels,doError)
                %CHECKRESERVEDNAMES Check for any conflicts with reserved names.
                arguments
                    labels
                    doError logical = false;
                end
                reservedNames = matlab.internal.tabular.private.varNamesDim.reservedNames;
                conflicts = matlab.internal.tabular.private.tabularDimension.checkReservedNamesImpl(labels,reservedNames);
                if (nargout==0 || doError) && any(conflicts)
                    dup = labels{find(conflicts,1)};
                    throwAsCaller( MException(message('MATLAB:table:ReservedVarNameConflict',dup)) );
                end
            end

            function [validNames, modified, issues] = makeValidName(names, mode, displayWarning)
                %MAKEVALIDNAME Construct valid table variable names from input
                %   MAKEVALIDNAME is a private function for table that allows
                %   checking and fixing names to be valid table variable names.
                %   It also provides exception contorl for cases when the names
                %   are not valid.
                %
                %   MODE controls the modification of names and error/warning
                %   behavior for cases when the names are not valid MATLAB
                %   identifiers, are too long, or they conflict with reserved
                %   names. The valid values for mode are:
                %       - error
                %       - silent
                %       - resolveConflict
                %       - warn
                %       - warnLength
                %       - warnSaved
                %       - warnSavedLegacy
                %       - warnUnstack
                %       - warnRows2Vars
                %   See parseMode method below for details on each one.

                arguments
                    names
                    mode
                    displayWarning logical = true;
                end

                import matlab.internal.datatypes.warningWithoutTrace;
                import matlab.internal.tabular.private.varNamesDim.checkReservedNames;
                import matlab.internal.tabular.validateVariableNameLength;

                % 'issues' indicates what issues were found in the input names
                % and patched by makeValidName for the selected mode. Currently
                % makeValidName finds and fixes the following three issues in
                % the names.
                issues.InvalidIdentifiers = false;
                issues.LongNames = false;
                issues.ReservedNameConflicts = false;

                [convertToValidNames, doError, doWarn, warnIDs] = parseMode(mode);
                doWarn = doWarn && displayWarning;

                if convertToValidNames
                    % Convert names to valid MATLAB identifiers. This would also
                    % handle long variable names. This is mainly used for
                    % compatibility reasons after tables supported arbitrary
                    % variable names.
                    [validNames, modified] = matlab.lang.makeValidName(names); issues.InvalidIdentifiers = any(modified);
                    % Check for any valid names that conflict with reserved
                    % names and patch those up.
                    conflicts = checkReservedNames(validNames); issues.ReservedNameConflicts = any(conflicts);
                    if any(conflicts)
                        validNames(conflicts) = matlab.lang.makeUniqueStrings(validNames(conflicts),validNames,namelengthmax);
                    end
                    modified = modified | conflicts;
                    if doWarn && any(modified) % warn if requested
                        warningWithoutTrace(message(warnIDs.modifiedVarNames));
                    end
                else
                    % For variable names that no longer need to be valid MATLAB
                    % identifiers, check length and conflicts with reserved
                    % names. In case of conflicts, we would either error or
                    % patch the names up (and optionally warn) based on the
                    % modException selected.
                    if mode == "resolveConflict"
                        % handle the case when the names contain empty char ''.
                        % This is used by internal methods that do not
                        % want to error or warn for empty names.
                        emptyNames = matches(names,'');
                        names(emptyNames) = {'x'};
                    end
                    validNames = names;
                    if ischar(names), names = { names }; end % unusual case, not optimized
                    tooLong = validateVariableNameLength(names,'MATLAB:table:VariableNameLengthMax',doError); issues.LongNames = any(tooLong);
                    conflicts = checkReservedNames(names,doError); issues.ReservedNameConflicts = any(conflicts);
                    modified = tooLong | conflicts;
                    if any(modified)
                        % Patch these names up and throw an appropriate warning if
                        % requested.
                        validNames(modified) = matlab.lang.makeUniqueStrings(validNames(modified),validNames,namelengthmax);
                        if doWarn
                            if any(conflicts)
                                reservedNameConflicts = names(conflicts);
                                warningWithoutTrace(message(warnIDs.reservedNameConflict,reservedNameConflicts{1}));
                            end
                            if any(tooLong)
                                warningWithoutTrace(message(warnIDs.longName));
                            end
                        end
                    end
                end
            end
        end

        %===========================================================================
        methods (Static, Access=protected)
            function x = orientAs(x)
                % orient as row
                if ~isrow(x)
                    x = x(:)';
                end
            end
        end
end

    %-----------------------------------------------------------------------
    function [names,empties] = fillEmptyNames(names,indices)
    empties = cellfun('isempty',names);
    if any(empties)
        names(empties) = matlab.internal.tabular.private.varNamesDim.dfltLabels(indices(empties));
    end
    end

    %-----------------------------------------------------------------------
    function tf = isEmptyElem(x)
    % Find the elements in an array that are empty (cell)/missing/default values.
    tf = false(size(x));
    if iscell(x)
        for i = 1:numel(x)
            tf(i) = isempty(x{i});
        end
    else
        % Need to handle types that has a default element that isn't true for
        % ismissing or isempty, such as int. Do element-wise comparison to
        % the default value provided by defaultArrayLike. But, because NaNs are
        % not equal, also check ismissing.
        dfltVal = matlab.internal.datatypes.defaultarrayLike([1 1], 'like', x);
        tf = (x==dfltVal) | ismissing(x);
    end
    end

    %-----------------------------------------------------------------------
    function [convertToValidNames, doError, doWarn, warnIDs] = parseMode(mode)
        % PARSEMODE Helper to parse the mode and determine the error/warnging
        % behavior and what modifications need to be done on the names.
        
        % Essentially it looks at the modException and determines the following:
        %   1. Should we convert names to valid MATLAB identifiers.
        %   2. Should we error for any naming issues.
        %   3. Should we display warnings for name modification.
        %   4. Select appropriate warning ids for different cases based on the mode.
        
        convertToValidNames = true;
        doWarn = true;
        doError = false;
        warnIDs.modifiedVarNames = 'MATLAB:table:ModifiedVarnames';
        switch mode
            case 'warn'                
                % Default behavior. Convert names to valid MATLAB identifiers
                % and resolve any conflicts with reserved names without any
                % errors. Warn if any of the names are modified.
            case 'warnSavedLegacy'
                % Same as the default behavior. Throws a more specialized
                % warning.
                warnIDs.modifiedVarNames = 'MATLAB:table:ModifiedAndSavedVarnames';
            case 'warnUnstack'
                % Same as the default behavior. Throws a more specialized
                % warning.
                warnIDs.modifiedVarNames = 'MATLAB:table:ModifiedVarnamesUnstack';
            case 'warnRows2Vars'
                % Same as the default behavior. Throws a more specialized
                % warning.
                warnIDs.modifiedVarNames = 'MATLAB:table:ModifiedVarnamesRows2Vars';
            case 'warnSaved'
                % Do not convert to valid MATLAB identifiers but fix any names
                % that are too long or conflict with a reserved name. Throw
                % specialized warnings for each case.
                convertToValidNames = false;
                warnIDs.reservedNameConflict = 'MATLAB:table:ModifiedAndSavedVarnamesReserved';
                warnIDs.longName = 'MATLAB:table:ModifiedAndSavedVarnamesLengthMax';
            case 'warnLength'
                % Same behavior as warnSaved above with different warning
                % messages.
                convertToValidNames = false;
                warnIDs.reservedNameConflict = 'MATLAB:table:ModifiedVarnamesReservedConflict';
                warnIDs.longName = 'MATLAB:table:ModifiedVarnamesLengthMax';
            case 'resolveConflict'
                % Do not convert to valid MATLAB identifiers but fix any names
                % that are too long or conflict with a reserved name. Do not
                % throw any warnings.
                convertToValidNames = false;
                doWarn = false;
            case 'silent'
                % Convert names to valid MATLAB identifiers and resolve any
                % conflicts with reserved names without any errors or warnings.
                doWarn = false;
            case 'error'
                % For names that no longer need to be valid MATLAB identifiers,
                % check and error if the names are too long or conflict with
                % reserved names.
                convertToValidNames = false;
                doError = true;
            otherwise
                % Should not be hit. If a new mode is added, then add a case
                % above.
                assert(false);
        end
    end