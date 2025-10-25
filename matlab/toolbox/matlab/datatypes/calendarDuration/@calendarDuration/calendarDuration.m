classdef (Sealed, InferiorClasses = {?duration}) calendarDuration ...
        < matlab.mixin.internal.datatypes.TimeArrayDisplay ...
        & matlab.mixin.internal.indexing.Paren ...
        & matlab.mixin.internal.indexing.ParenAssign
%

%   Copyright 2014-2024 The MathWorks, Inc.

    %#ok<*MGMD>
    properties(GetAccess='public', Dependent=true)
        Format
    end
    properties(GetAccess='public', Hidden, Constant)
        % This property is for internal use only and will change in a
        % future release.  Do not use this property.
        DefaultDisplayFormat = 'ymdt';
    end
    
    properties(GetAccess='protected', SetAccess='protected')
        % number of months, days, milliseconds, stored as separate arrays

        components = struct('months',[],'days',[],'millis',[]);
        
        % Format in which to display

        fmt = 'ymdt';
    end
    
    % Forward compatibility layer
    properties(GetAccess='private', SetAccess='private', Dependent=true)
        data
    end
    methods
        function d = set.data(d,data)
            d.components = struct('months',data.months, ...
                                  'days',data.days, ...
                                  'millis',data.seconds*1000);
        end
    end
    
    methods(Access = 'public')
        function this = calendarDuration(inData,varargin)
            import matlab.internal.datatypes.parseArgs
            
            if nargin == 0 % same as calendarDuration(0,0,0)
                theComponents = struct('months',0,'days',0,'millis',0);
                inFmt = calendarDuration.DefaultDisplayFormat;
            else
                if isnumeric(inData)
                    % Find how many numeric inputs args: count up until the first non-numeric.
                    numNumericArgs = 1 + sum(cumprod(cellfun(@isnumeric,varargin)));
                    if numNumericArgs == 1 % calendarDuration([y,mo,d,h,mi,s],...), or calendarDuration([y,mo,d],...)
                        m = size(inData,2);
                        if ~ismatrix(inData) || ~((m == 6) || (m == 3))
                            error(message('MATLAB:calendarDuration:InvalidNumericMatrix'));
                        end
                        % Split numeric matrix into separate vectors.
                        inData = num2cell(double(inData),1);
                    elseif numNumericArgs == 3 % calendarDuration(y,mo,d,t,...) or calendarDuration(y,mo,d,...)
                        if (nargin >= 4) && isa(varargin{3},'duration')
                            inData = {inData varargin{1:2} milliseconds(varargin{3})};
                            varargin = varargin(4:end);
                        else
                            inData = {inData varargin{1:2}};
                            varargin = varargin(3:end);
                        end
                    elseif numNumericArgs == 4 % calendarDuration(y,mo,d,ms,...)
                        inData = {inData varargin{1:3}};
                        varargin = varargin(4:end);
                    elseif numNumericArgs == 6 % calendarDuration(y,mo,d,h,mi,s,...)
                        inData = {inData varargin{1:5}};
                        varargin = varargin(6:end);
                    else
                        error(message('MATLAB:calendarDuration:InvalidNumericData'));
                    end
                elseif isa(inData,'duration')
                    error(message('MATLAB:calendarDuration:InvalidDurationData'));
                elseif ~isa(inData,'calendarDuration') && ~isa(inData, 'missing')
                    error(message('MATLAB:calendarDuration:InvalidData'));
                end
                
                if isempty(varargin)
                    % Default format.
                    inFmt = calendarDuration.DefaultDisplayFormat;
                    supplied = struct('Format',false);
                else
                    % Accept explicit parameter name/value pairs.
                    pnames = {'Format'                              };
                    dflts =  { calendarDuration.DefaultDisplayFormat};
                    [inFmt,supplied] = parseArgs(pnames, dflts, varargin{:});
                    if supplied.Format, inFmt = verifyFormat(inFmt); end
                end
                
                if isa(inData,'calendarDuration') % construct from an array of calendarDurations
                    if ~supplied.Format, inFmt = inData.fmt; end
                    theComponents = inData.components;
                elseif isa(inData, 'missing')
                    theComponents = struct('months',0,'days',0,'millis',double(inData));
                else
                    % Construct from numeric data.
                    theComponents = calendarDuration.createFromFields(inData);
                end
            end
            
            this.components = theComponents;
            this.fmt = inFmt;
        end
        
        %% Extract date/time fields
        function y = calyears(this)
            comps = this.components;
            y = calendarDuration.expandFieldForOutput(comps,floor(comps.months/12));
        end
        
        function q = calquarters(this)
            comps = this.components;
            q = calendarDuration.expandFieldForOutput(comps,floor(comps.months/3));
        end
        
        function mo = calmonths(this)
            comps = this.components;
            mo = calendarDuration.expandFieldForOutput(comps,comps.months);
        end
        
        function w = calweeks(this)
            comps = this.components;
            if ~all((comps.months(:) == 0))
                error(message('MATLAB:calendarDuration:NonZeroMonths'));
            end
            w = calendarDuration.expandFieldForOutput(comps,floor(comps.days/7));
        end
        
        function d = caldays(this)
            comps = this.components;
            if ~all((comps.months(:) == 0))
                error(message('MATLAB:calendarDuration:NonZeroMonths'));
            end
            d = calendarDuration.expandFieldForOutput(comps,comps.days);
        end
        
        function t = time(this)
            comps = this.components;
            t = duration.fromMillis(calendarDuration.expandFieldForOutput(comps,comps.millis));
        end
        
        %% Conversions to string types
        function s = char(this,format,locale)
            if nargin < 2 || isequal(format,[]) % treat '' as [], but not "" or string.empty
                format = this.fmt;
            else
                format = verifyFormat(format);
            end
            
            if nargin < 3 || isequal(locale,[])
                s = calendarDuration.formatAsString(this.components,format,true);
            else
                s = calendarDuration.formatAsString(this.components,format,true,locale);
            end
            s = strjust(char(s(:)),'right');
        end
        
        function c = cellstr(this,format,locale)
            if nargin < 2 || isequal(format,[]) % treat '' as [], but not "" or string.empty
                format = this.fmt;
            else
                format = verifyFormat(format);
            end

            if nargin < 3 || isequal(locale,[])
                c = cellstr(calendarDuration.formatAsString(this.components,format,true));
            else
                c = cellstr(calendarDuration.formatAsString(this.components,format,true,locale));
            end
        end
        
        function s = string(this,format,locale)
            if nargin < 2 || isequal(format,[]) % treat '' as [], but not "" or string.empty
                format = this.fmt;
            else
                format = verifyFormat(format);
            end

            if nargin < 3 || isequal(locale,[])
                s = calendarDuration.formatAsString(this.components,format,false);
            else
                s = calendarDuration.formatAsString(this.components,format,false,locale);
            end
        end
        
        %% Conversions to the legacy types
        function [y,mo,d,h,m,s] = datevec(this,varargin)
            theComponents = this.components;
            outSz = calendarDuration.getFieldSize(theComponents);
            
            mo = theComponents.months;
            d = theComponents.days;
            s = theComponents.millis / 1000; % ms -> s
            
            % Find nonfinite elements
            check = mo + d + s;
            nonfiniteElems = ~isfinite(check);
            nonfiniteVals = check(nonfiniteElems);
            
            if isscalar(mo), mo = repmat(mo,outSz); end
            y = fix(mo / 12);
            mo = rem(mo,12);
            if isscalar(d), d = repmat(d,outSz); end
            if isscalar(s), s = repmat(s,outSz); end
            h = fix(s / 3600);
            s = rem(s,3600);
            m = fix(s / 60);
            s = rem(s,60);
            
            % Return the same non-finite in all fields.
            if ~isempty(nonfiniteVals)
                y(nonfiniteElems) = nonfiniteVals;
                mo(nonfiniteElems) = nonfiniteVals;
                d(nonfiniteElems) = nonfiniteVals;
                h(nonfiniteElems) = nonfiniteVals;
                m(nonfiniteElems) = nonfiniteVals;
                s(nonfiniteElems) = nonfiniteVals;
            end
            
            if nargout <= 1
                y = [y(:),mo(:),d(:),h(:),m(:),s(:)];
            end
        end
        
        %% Array methods
        function [varargout] = size(this,varargin)
            [~,field] = calendarDuration.getFieldSize(this.components);
            if nargin < 2
                [varargout{1:nargout}] = size(field);
            else
                [varargout{1:nargout}] = size(field,varargin{:});
            end
        end
        function l = length(this)
            [~,field] = calendarDuration.getFieldSize(this.components);
            l = length(field);
        end
        function n = ndims(this)
            [~,field] = calendarDuration.getFieldSize(this.components);
            n = ndims(field);
        end
        
        function n = numel(this,varargin)
             [~,field] = calendarDuration.getFieldSize(this.components);
             if nargin == 1
                 n = numel(field);
             else
                 n = numel(field,varargin{:});
             end
        end
        
        function t = isempty(a),  [~,f] = calendarDuration.getFieldSize(a.components); t = isempty(f);  end
        function t = isscalar(a), [~,f] = calendarDuration.getFieldSize(a.components); t = isscalar(f); end
        function t = isvector(a), [~,f] = calendarDuration.getFieldSize(a.components); t = isvector(f); end
        function t = isrow(a),    [~,f] = calendarDuration.getFieldSize(a.components); t = isrow(f);    end
        function t = iscolumn(a), [~,f] = calendarDuration.getFieldSize(a.components); t = iscolumn(f); end
        function t = ismatrix(a), [~,f] = calendarDuration.getFieldSize(a.components); t = ismatrix(f); end
        
        function result = horzcat(varargin)
            try
                result = calendarDuration.catUtil(2,true,varargin{:});
            catch ME
                throw(ME);
            end
        end
        function result = vertcat(varargin)
            try
                result = calendarDuration.catUtil(1,true,varargin{:});
            catch ME
                throw(ME);
            end
        end

        function this = ctranspose(this)
            try
                this.components = applyArraynessFun(this.components,@transpose); % NOT ctranspose
            catch ME
                throw(ME);
            end
        end
        function this = transpose(this)
            try
                this.components = applyArraynessFun(this.components,@transpose);
            catch ME
                throw(ME);
            end
        end
        function this = reshape(this,varargin)
            this.components = applyArraynessFun(this.components,@reshape,varargin{:});
        end
        function this = permute(this,order)
            this.components = applyArraynessFun(this.components,@permute,order);
        end
        function t = isequal(varargin)
            narginchk(2,Inf);
            try
                argsComponents = calendarDuration.isequalUtil(varargin);
            catch ME
                if ME.identifier == "MATLAB:calendarDuration:InvalidComparison"
                    t = false;
                    return
                else
                    throw(ME);
                end
            end
            t = isequal(argsComponents{:});
        end
        
        function t = isequaln(varargin)
            narginchk(2,Inf);

            % Ensure the logic to check equality is consistent between isequaln and
            % keyMatch.
            try
                argsComponents = calendarDuration.isequalUtil(varargin);
            catch ME
                if ME.identifier == "MATLAB:calendarDuration:InvalidComparison"
                    t = false;
                    return
                else
                    throw(ME);
                end
            end
            t = isequaln(argsComponents{:});
        end

        function t = keyMatch(d1,d2)
            if isa(d1,"calendarDuration") && isa(d2,"calendarDuration")
                % Adjust the scalar zero and non-finite components of the
                % calendarDurations before calling isequaln.
                d1_components = calendarDuration.adjustComponentsForComparision(d1.components);
                d2_components = calendarDuration.adjustComponentsForComparision(d2.components);
                t = isequaln(d1_components,d2_components);
            else
                t = false;
            end
        end

        function h = keyHash(d)
            %

            % Adjust the scalar zero and non-finite components of the
            % calendarDuration before calling keyHash. This ensures that two
            % equal calendarDurations always generate the same hash.
            d_components = calendarDuration.adjustComponentsForComparision(d.components);
            h = keyHash(d_components);
        end
        
        %% Math
        function b = uplus(a)
            b = a;
        end
        
        function nz = nnz(d)
            d_components = d.components;
            nz = nnz((d_components.months ~= 0) | (d_components.days ~= 0) | (d_components.millis ~= 0));
        end
        
        function tf = isreal(d) %#ok<MANU>
            tf = true;
        end
    end % public methods block
    
    methods(Hidden = true)        
        %% Arrayness
        function n = end(this,k,n)
            try
                [~,field] = calendarDuration.getFieldSize(this.components);
                n = builtin('end',field,k,n);
            catch ME
                throw(ME);
            end
        end
        
        %% Subscripting
        this = subsasgn(this,s,rhs)
        that = subsref(this,s)
        that = parenReference(this,rowIndices,colIndices,varargin)
        this = parenAssign(this,that,rowIndices,colIndices,varargin)
        
        function sz = numArgumentsFromSubscript(~,~,~)
            sz = 1;
        end
        
        %% Variable Editor methods
        % These functions are for internal use only and will change in a
        % future release.  Do not use this function.
        [out, warnmsg] = variableEditorColumnDeleteCode(this, varName, colIntervals)
        out = variableEditorInsert(this, orientation, row, col, data)
        out = variableEditorPaste(this, rows, columns, data)
        [out, warnmsg] = variableEditorRowDeleteCode(this, varName, rowIntervals)
        
        %% Error stubs
        % Methods to override functions and throw helpful errors
        function n = datenum(this), error(message('MATLAB:calendarDuration:DatenumNotDefined')); end %#ok<MANU,STOUT>
        function n = datestr(this), error(message('MATLAB:calendarDuration:DatestrNotDefined')); end %#ok<MANU,STOUT>
        function c = linspace(a,b,n), error(message('MATLAB:calendarDuration:LinspaceNotDefined')); end %#ok<INUSD,STOUT>
        function c = colon(a,d,b), error(message('MATLAB:calendarDuration:ColonNotDefined')); end %#ok<INUSD,STOUT>
        function d = double(d), error(message('MATLAB:calendarDuration:InvalidNumericConversion','double')); end %#ok<MANU>
        function d = single(d), error(message('MATLAB:calendarDuration:InvalidNumericConversion','single')); end %#ok<MANU>
        function varargout = diff(varargin), errorStubHelper('diff', varargin); end %#ok<STOUT>            
        function varargout = sum(varargin), errorStubHelper('sum', varargin); end %#ok<STOUT>
        function varargout = max(varargin), errorStubHelper('max', varargin); end %#ok<STOUT>
        function varargout = min(varargin), errorStubHelper('min', varargin); end %#ok<STOUT>
        function varargout = mod(varargin), errorStubHelper('mod', varargin); end %#ok<STOUT>
        function varargout = rem(varargin), errorStubHelper('rem', varargin); end %#ok<STOUT>
        function varargout = discretize(varargin), errorStubHelper('discretize', varargin); end %#ok<STOUT>
        function varargout = histcounts(varargin), errorStubHelper('histcounts', varargin); end %#ok<STOUT>
        function varargout = interp1(varargin), errorStubHelper('interp1', varargin); end %#ok<STOUT>
        function varargout = isbetween(varargin), errorStubHelper('isbetween', varargin); end %#ok<STOUT>
        function varargout = intersect(varargin), errorStubHelper('intersect', varargin); end %#ok<STOUT>
        function varargout = ismember(varargin), errorStubHelper('ismember', varargin); end %#ok<STOUT>
        function varargout = setdiff(varargin), errorStubHelper('setdiff', varargin); end %#ok<STOUT>
        function varargout = setxor(varargin), errorStubHelper('setxor', varargin); end %#ok<STOUT>
        function varargout = union(varargin), errorStubHelper('union', varargin); end %#ok<STOUT>
        
        function d = month(d) %#ok<MANU> 
            import matlab.lang.correction.ReplaceIdentifierCorrection
            ME = MException(message('MATLAB:calendarDuration:NoMonthsMethod','month'));
            ME = addCorrection(ME,ReplaceIdentifierCorrection('month','calmonths'));
            throw(ME);
        end
        
        function d = months(d) %#ok<MANU> 
            import matlab.lang.correction.ReplaceIdentifierCorrection
            ME = MException(message('MATLAB:calendarDuration:NoMonthsMethod','months'));
            ME = addCorrection(ME,ReplaceIdentifierCorrection('months','calmonths'));
            throw(ME);
        end
    end % hidden public methods block
    
    methods(Hidden = true, Static = true)
        function d = empty(varargin)
            if nargin == 0
                d = calendarDuration([],[],[]);
            else
                dComponents = zeros(varargin{:});
                if numel(dComponents) ~= 0
                    error(message('MATLAB:class:emptyMustBeZero'));
                end
                d = calendarDuration([],[],[]);
                d.components = struct('months',dComponents,'days',dComponents,'millis',dComponents);
            end
        end
        
        function fmt = combineFormats(varargin)
            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            
            %COMBINEFORMATS Combine the formats of two calendarDuration arrays.
            %   FMT = CALENDARDURATION.COMBINEFORMATS(FMT1,FMT2,...) returns a
            %   calendarDuration format character vector that is a combination of the formats FMT1,
            %   FMT2, ... .
            %
            %   See also CALENDARDURATION.
            tokens = 'yqmwdt';
            [~,i] = ismember(unique(strjoin(varargin,'')),tokens);
            fmt = tokens(sort(i));
        end
    end % static hidden public methods block
        
    methods(Access='protected')
        this = subsasgnDot(this,s,rhs)
        this = subsasgnParens(this,s,rhs)
        value = subsrefDot(this,s)
        value = subsrefParens(this,s)
        fmt = getDisplayFormat(this)

        %-----------------------------------------------------------------------
        function chars = formatAsCharForDisplay(this)
            chars = strjust(char(cellstr(calendarDuration.formatAsString(this.components,this.fmt,true))),'right');
        end

        %-----------------------------------------------------------------------
        function missingText = getMissingTextDisplay(~)
            missingText = "NaN";
        end
    end
    
    methods(Static, Access='protected')
        args = isequalUtil(args)
        components = createFromFields(fields)
        s = formatAsString(components,fmt,missingAsNaN,locale)
        result = catUtil(dim,useSpecializedFcn,varargin)
        
        function [sz,f] = getFieldSize(components)
            %

            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            
            % Get the common (across all three components) scalar/implicit
            % expansion size of the array, and return an array representative of
            % that common size.
            f = components.months + components.days + components.millis;
            sz = size(f);
        end
        
        function components = expandFields(components)
            %

            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            
            % Any component in an in-progress array that is not a scalar zero
            % must be expanded to the common (across all three components)
            % scalar/implicit expansion size, even if it becomes an array of a
            % constant (non-zero) value. Leave scalar zeros alone, as
            % memory-saving placeholders.
            [targetSize,f] = calendarDuration.getFieldSize(components);
            if ~isscalar(f)
                components.months = repComponent(components.months,targetSize);
                components.days   = repComponent(components.days,  targetSize);
                components.millis = repComponent(components.millis,targetSize);
            end
        end
        
        function components = expandScalarZeroPlaceholders(components)
            %

            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            
            % Expand any scalar zero placeholders out to the full array size.
            sz = calendarDuration.getFieldSize(components);
            if isequal(components.months,0)
                components.months = zeros(sz);
            end
            if isequal(components.days,0)
                components.days = zeros(sz);
            end
            if isequal(components.millis,0)
                components.millis = zeros(sz);
            end
        end
        
        function [components,nonfiniteElems,nonfiniteVals] = reconcileNonfinites(components)
            %

            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            
            % Find and reconcile any nonfinite elements across all components of
            % the array, and put the same nonfinite in all three fields. This is
            % needed, for example, when constructing from components or adding
            % two calendarDurations together, and different components contain
            % nonfinites in the same elements.
            
            % In extreme cases, this sum could overflow, but for all practical
            % purposes, that's not an issue.
            check = components.months + components.days + components.millis;
            nonfiniteElems = ~isfinite(check);
            if any(nonfiniteElems(:))
                nonfiniteVals = check(nonfiniteElems);
                if isscalar(check)
                    % Ordinarily, reconcileNonfinites leaves scalar zero placeholders
                    % alone, they have no effect. However, a placeholder in a scalar
                    % calendarDuration can't be distinguished from a real value, so
                    % treat it like one.
                    components.months = check;
                    components.days = check;
                    components.millis = check;
                else
                    if ~isequal(components.months,0)
                        components.months(nonfiniteElems) = nonfiniteVals;
                    end
                    if ~isequal(components.days,0)
                        components.days(nonfiniteElems) = nonfiniteVals;
                    end
                    if ~isequal(components.millis,0)
                        components.millis(nonfiniteElems) = nonfiniteVals;
                    end
                end
            else
                nonfiniteVals = [];
            end
        end

        function components = adjustComponentsForComparision(components)
            %

            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            
            % Expand out scalar zero placeholders to simplify comparison of all three
            % fields. May also have to put appropriate nonfinites into elements of
            % fields that were expanded.
            components = calendarDuration.expandScalarZeroPlaceholders(components);
            components = calendarDuration.reconcileNonfinites(components);
        end
        
        function field = expandFieldForOutput(components,field)
            %

            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            
            % Expand the field out to the array size if it's a scalar zero placeholder.
            if isequal(field,0)
                field = zeros(calendarDuration.getFieldSize(components));
            end
            
            % Find any nonfinite values in other fields.
            check = components.months + components.days + components.millis;
            nonfiniteElems = ~isfinite(check);
            nonfiniteVals = check(nonfiniteElems);
            % Replicate nonfinites where necessary in this field.
            if ~isempty(nonfiniteVals)
                field(nonfiniteElems) = nonfiniteVals;
            end
        end
    end % protected static methods block
end


%%%%%%%%%%%%%%%%% Local functions %%%%%%%%%%%%%%%%%

%-----------------------------------------------------------------------
function component = repComponent(component,targetSize)
% Repmat a months/days/millis component out to a target size.
if isscalar(component)
    % Scalar expansion, but leave scalar zeros alone.
    if component ~= 0
        component = repmat(component,targetSize);
    end
else
    % Implicit expansion.
    sz = size(component);
    if ~isequal(sz,targetSize)
        reps = targetSize; reps(sz ~= 1) = 1;
        component = repmat(component,reps);
    end
end
end

%-----------------------------------------------------------------------
function components = applyArraynessFun(components,fun,varargin)
% If the field is a scalar 0, it's just a placeholder, leave it alone
if ~isequal(components.months,0)
    components.months = fun(components.months,varargin{:});
end
if ~isequal(components.days,0)
    components.days = fun(components.days,varargin{:});
end
if ~isequal(components.millis,0)
    components.millis = fun(components.millis,varargin{:});
end
end

%-----------------------------------------------------------------------
function errorStubHelper(fName, args)
if length(args) == 2 
    % For functions where the first 2 inputs are the main data arguments
    % and it was called with exactly two inputs, spell out both class names
    throwAsCaller(MException(message('MATLAB:calendarDuration:UnsupportedMethod2Inputs', fName, class(args{1}), class(args{2}))));
else
    % If called for more than two inputs, don't bother detecting where
    % calendarDuration appears in the argument list
    throwAsCaller(MException(message('MATLAB:calendarDuration:UnsupportedMethod', fName)));
end
end
