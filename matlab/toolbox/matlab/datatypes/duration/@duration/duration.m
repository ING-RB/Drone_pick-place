classdef (Sealed, InferiorClasses = {?matlab.graphics.axis.Axes}) duration ...
        < matlab.mixin.internal.datatypes.TimeArrayDisplay ...
        & matlab.mixin.internal.indexing.Paren ...
        & matlab.mixin.internal.indexing.ParenAssign
    %
    
    %   Copyright 2014-2024 The MathWorks, Inc.
    
    %#ok<*MGMD>
    properties(GetAccess='public', Dependent)
        Format
    end

    %=======================================================================
    properties(GetAccess='public', Constant, Hidden)
        % This property is for internal use only and will change in a
        % future release.  Do not use this property.
        DefaultDisplayFormat = 'hh:mm:ss';
    end
    
    %=======================================================================
    properties(Access='protected')
        % The duration data, stored as milliseconds

        millis = 0;
        
        % Format in which to display

        fmt = duration.DefaultDisplayFormat;
    end
    properties(GetAccess='private', Constant)
        noConstructorParamsSupplied = struct('Format',false,'InputFormat',false);
    end
    
    %=======================================================================
    % Backward compatibility layer
    properties(Access='private', Dependent)
        data
    end
    methods
        function d = set.data(d,data)
            d.millis = data * 1000;
        end
    end
    
    %=======================================================================
    methods(Access = 'public')
        function this = duration(inData,varargin)
            import matlab.internal.datatypes.parseArgs
            import matlab.internal.datatypes.isText
            
            if nargin == 0 % same as duration(0,0,0)
                return;
            end
            
            inputFormat = '';
            if isnumeric(inData)
                % Find how many numeric inputs args: count up until the first non-numeric.
                numNumericArgs = 1; % include inData
                for i = 1:numel(varargin)
                    if ~isnumeric(varargin{i}), break, end
                    numNumericArgs = numNumericArgs + 1;
                end
                if numNumericArgs == 1 % duration([h,m,s],...)
                    if ~ismatrix(inData) || ~(size(inData,2) == 3)
                        error(message('MATLAB:duration:InvalidNumericData'));
                    end
                    % Split numeric matrix into separate vectors. Manual
                    % conversion to cell for performance
                    inData = double(inData);
                    inData = {inData(:,1),inData(:,2),inData(:,3)};
                elseif numNumericArgs == 3 % duration(h,m,s,...)
                    inData = [{inData} varargin(1:2)];
                    varargin = varargin(3:end);
                elseif numNumericArgs == 4 % duration(h,m,s,ms,...)
                    inData = [{inData} varargin(1:3)];
                    varargin = varargin(4:end);
                else
                    error(message('MATLAB:duration:InvalidNumericData'));
                end
                convertFromText = false;
            elseif isText(inData)
                % strips whitespace and converts to always be cell.
                inData = strtrim(convertStringsToChars(inData));
                convertFromText = true;
            elseif ~isa(inData,'duration') && ~isa(inData, 'missing')
                error(message('MATLAB:duration:InvalidData'));
            end
            
            if isempty(varargin)
                % Default format.
                outputFmt = duration.DefaultDisplayFormat;
                supplied = this.noConstructorParamsSupplied;
            else
                % Accept explicit parameter name/value pairs.
                pnames = {'Format'                      ,'InputFormat'};
                dflts =  { duration.DefaultDisplayFormat,inputFormat};
                
                [outputFmt,inputFormat,supplied] = parseArgs(pnames, dflts, varargin{:});
                if supplied.Format
                    % verifyFormat also converts strings to chars.
                    outputFmt = verifyFormat(outputFmt); 
                end
                if supplied.InputFormat 
                    if ~convertFromText
                        warning(message('MATLAB:duration:IgnoredInputFormat'));
                    else
                        inputFormat = verifyInputFormat(inputFormat); 
                    end
                end
               
            end
                                  
            try
                if iscell(inData) && ~convertFromText % numeric input, now cells
                    % Construct from separate h,m,s arrays.
                    thisMillis = duration.createFromFields(inData);
                elseif isa(inData,'duration')
                    % Modify a duration array.
                    thisMillis = inData.millis;
                    if ~supplied.Format, outputFmt = inData.fmt; end
                elseif isa(inData, 'missing')
                    % Create a NaN from a missing.
                    thisMillis = double(inData);
                elseif convertFromText
                    thisMillis = matlab.internal.duration.createFromText(inData,inputFormat,outputFmt,supplied);
                end
            catch ME
                throw(ME)
            end
            
            this.millis = thisMillis;
            this.fmt = outputFmt;
        end
        
        %% Conversions to numeric types
        function s = milliseconds(d)
            s = d.millis;
        end
        
        function s = seconds(d)
            s = d.millis / 1000; % ms -> s
        end
        
        function m = minutes(d)
            m = d.millis / (60*1000); % ms -> m
        end
        
        function h = hours(d)
            h = d.millis / (3600*1000); % ms -> h
        end
        
        function d = days(d)
            d = d.millis / (86400*1000); % ms -> days
        end
        
        function y = years(d)
            y = d.millis / (86400*365.2425*1000); % ms -> years
        end
        
        %% Conversions to string types
        function s = char(this,format,locale)
            import matlab.internal.duration.formatAsString
            
            isLong = strncmp(matlab.internal.display.format,'long',4);
            if nargin < 2 || isequal(format,[])
                format = this.fmt;
            end
            if nargin < 3 || isequal(locale,[])
                format = convertStringsToChars(format);
                s = strjust(char(formatAsString(this.millis,format,isLong,false)),'right');
            else
                [format,locale] = convertStringsToChars(format,locale);
                s = strjust(char(formatAsString(this.millis,format,isLong,false,matlab.internal.datetime.verifyLocale(locale))),'right');
            end
        end
        
        function c = cellstr(this,format,locale)
            import matlab.internal.duration.formatAsString
            
            isLong = strncmp(matlab.internal.display.format,'long',4);
            if nargin < 2 || isequal(format,[])
                format = this.fmt;
            end
            if nargin < 3 || isequal(locale,[])
                format = convertStringsToChars(format);
                c = formatAsString(this.millis,format,isLong,false);
            else
                [format,locale] = convertStringsToChars(format,locale);
                c = formatAsString(this.millis,format,isLong,false,matlab.internal.datetime.verifyLocale(locale));
            end
        end
        
        function s = string(this,format,locale)
            import matlab.internal.duration.formatAsString
            
            isLong = strncmp(matlab.internal.display.format,'long',4);
            if nargin < 2 || isequal(format,[])
                format = this.fmt;
            end
            if nargin < 3 || isequal(locale,[])
                format = convertStringsToChars(format);
                s = formatAsString(this.millis,format,isLong,true);
            else
                [format,locale] = convertStringsToChars(format,locale);
                s = formatAsString(this.millis,format,isLong,true,matlab.internal.datetime.verifyLocale(locale));
            end
            
            % Convert 'NaN' to missing string. String method is a
            % conversion, not a text representation, and thus NaT should be
            % converted to its equivalent in string, which is the missing
            % string.
            s(isnan(this)) = string(missing);
        end
        
        %% Conversions to the legacy types        
        function n = datenum(this)
            n = this.millis / (86400*1000); % ms -> days
        end
        
        function [y,mo,d,h,m,s] = datevec(this,varargin)
            s = this.millis / 1000; % ms -> s
            y = fix(s / (86400*365.2425)); % possibly negative, possibly nonfinite
            mo = zeros(size(s));
            mo(~isfinite(s)) = NaN;
            s = s - (86400*365.2425)*y; % NaN if s was infinite
            d = fix(s / 86400);
            s = s - 86400*d;
            h = fix(s / 3600);
            s = s - 3600*h;
            m = fix(s / 60);
            s = s - 60*m;
            
            % Return the same non-finite in all fields.
            nonfiniteElems = ~isfinite(y);
            nonfiniteVals = y(nonfiniteElems);
            if ~isempty(nonfiniteVals)
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
            [varargout{1:nargout}] = size(this.millis,varargin{:});
        end
        function l = length(this)
            l = length(this.millis);
        end
        function n = ndims(this)
            n = ndims(this.millis);
        end
        
        function n = numel(this,varargin)
            if nargin == 1
                n = numel(this.millis);
            else
                n = numel(this.millis,varargin{:});
            end
        end
        
        function t = isempty(a),  t = isempty(a.millis);  end
        function t = isscalar(a), t = isscalar(a.millis); end
        function t = isvector(a), t = isvector(a.millis); end
        function t = isrow(a),    t = isrow(a.millis);    end
        function t = iscolumn(a), t = iscolumn(a.millis); end
        function t = ismatrix(a), t = ismatrix(a.millis); end
        
        function result = cat(dim,varargin)
            try
                result = duration.catUtil(dim,false,varargin{:});
            catch ME
                throw(ME);
            end
        end
        function result = horzcat(varargin)
            try
                result = duration.catUtil(2,true,varargin{:});
            catch ME
                throw(ME);
            end
        end
        function result = vertcat(varargin)
            try
                result = duration.catUtil(1,true,varargin{:});
            catch ME
                throw(ME);
            end
        end
        
        function that = ctranspose(this)
            try
                that = this; that.millis = ctranspose(this.millis);
            catch ME
                throw(ME);
            end
        end
        function that = transpose(this)
            try
                that = this; that.millis = transpose(this.millis);
            catch ME
                throw(ME);
            end
        end
        function that = reshape(this,varargin)
            that = this; that.millis = reshape(this.millis,varargin{:});
        end
        function that = permute(this,order)
            that = this; that.millis = permute(this.millis,order);
        end
        
        %% Relational operators
        function t = eq(a,b)
            [amillis,bmillis] = duration.compareUtil(a,b);
            t = (amillis == bmillis);
        end
        
        function t = ne(a,b)
            [amillis,bmillis] = duration.compareUtil(a,b);
            t = (amillis ~= bmillis);
        end
        
        function t = lt(a,b)
            [amillis,bmillis] = duration.compareUtil(a,b);
            t = (amillis < bmillis);
        end
        
        function t = le(a,b)
            [amillis,bmillis] = duration.compareUtil(a,b);
            t = (amillis <= bmillis);
        end
        
        function t = ge(a,b)
            [amillis,bmillis] = duration.compareUtil(a,b);
            t = (amillis >= bmillis);
        end
        
        function t = gt(a,b)
            [amillis,bmillis] = duration.compareUtil(a,b);
            t = (amillis > bmillis);
        end
        
        function t = isequal(varargin)
            narginchk(2,Inf);
            try
                argsMillis = duration.isequalUtil(varargin);
            catch ME
                if ME.identifier == "MATLAB:duration:InvalidComparison"
                    t = false;
                    return
                else
                    throw(ME);
                end
            end
            t = isequal(argsMillis{:});
        end
        
        function t = isequaln(varargin)
            narginchk(2,Inf);

            % Ensure the logic to check equality is consistent between isequaln and
            % keyMatch.
            try
                argsMillis = duration.isequalUtil(varargin);
            catch ME
                if ME.identifier == "MATLAB:duration:InvalidComparison"
                    t = false;
                    return
                else
                    throw(ME);
                end
            end
            t = isequaln(argsMillis{:});
        end

        function t = keyMatch(d1,d2)
            if isa(d1,"duration") && isa(d2,"duration")
                % Only the underlying millis values need to match. Duration keys
                % can have different formats.
                t = isequaln(d1.millis,d2.millis);
            else
                t = false;
            end
        end

        function h = keyHash(d)
            h = keyHash(d.millis);
        end
        
        %% Math
        function y = eps(x)
            y = x;
            y.millis = eps(x.millis);
            % Output eps in a simple format (not a digital timer format; e.g. hh:mm:ss)
            if any(y.fmt == ':')
                y.fmt = 's';
            end
        end
        
        function s = sign(d)
            s = sign(d.millis);
        end
        
        function b = uplus(a)
            b = a;
        end
        
        function nz = nnz(d)
            nz = nnz(d.millis);
        end
        
        function tf = isreal(d) %#ok<MANU>
            tf = true;
        end
        
        function y = cumsum(x,varargin)
            y = x;
            y.millis = cumsum(x.millis,varargin{:});
        end
        function y = cummin(x,varargin)
            y = x;
            y.millis = cummin(x.millis,varargin{:});
        end
        function y = cummax(x,varargin)
            y = x;
            y.millis = cummax(x.millis,varargin{:});
        end
        
        function z = mod(x,y)
            [xmillis,ymillis,z] = duration.compareUtil(x,y);
            z.millis = mod(xmillis,ymillis);
        end
        function z = rem(x,y)
            [xmillis,ymillis,z] = duration.compareUtil(x,y);
            z.millis = rem(xmillis,ymillis);
        end
    end % public methods block
    
    %=======================================================================
    methods(Access='public', Hidden)       
        %% Arrayness
        function n = end(this,k,n)
            try
                n = builtin('end',this.millis,k,n);
            catch ME
                throw(ME);
            end
        end
        
        %% Format
        function this = setFractionalFormat(this)
            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            this.fmt = duration.getFractionalSecondsFormat(this.millis,this.fmt); 
        end
        
        %% Subscripting
        this = subsasgn(this,s,rhs)
        that = subsref(this,s)
        that = parenReference(this,rowIndices,colIndices,varargin)
        this = parenAssign(this,that,rowIndices,colIndices,varargin)
        
        function sz = numArgumentsFromSubscript(~,~,~)
            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            sz = 1;
        end
        
        %% Variable Editor methods
        % These functions are for internal use only and will change in a
        % future release.  Do not use this function.
        [out,warnmsg] = variableEditorClearDataCode(this, varname, rowIntervals, colIntervals)
        [out,warnmsg] = variableEditorColumnDeleteCode(this, varName, colIntervals)
        out = variableEditorInsert(this, orientation, row, col, data)
        out = variableEditorPaste(this, rows, columns, data)
        [out,warnmsg] = variableEditorRowDeleteCode(this, varName, rowIntervals)
        [out,warnmsg] = variableEditorSortCode(~, varName, columnIndexStrings, direction)

        %% Error stubs
        % Methods to override functions and throw helpful errors
        function d = double(d), error(message('MATLAB:duration:InvalidNumericConversion','double')); end %#ok<MANU>
        function d = single(d), error(message('MATLAB:duration:InvalidNumericConversion','single')); end %#ok<MANU>
        function d = month(d), error(message('MATLAB:duration:MonthsNotSupported','month')); end %#ok<MANU>
        function d = months(d), error(message('MATLAB:duration:MonthsNotSupported','months')); end %#ok<MANU>
        function d = isuniform(d), error(message('MATLAB:datatypes:UseIsRegularMethod',mfilename)); end %#ok<MANU> 
    end % hidden public methods block
    
    %=======================================================================
    methods(Access='public', Static, Hidden)
        function d = empty(varargin)
            if nargin == 0
                d = duration([],[],[]);
            else
                dMillis = zeros(varargin{:});
                if numel(dMillis) ~= 0
                    error(message('MATLAB:class:emptyMustBeZero'));
                end
                d = duration([],[],[]);
                d.millis = dMillis;
            end
        end
        
        function d = fromMillis(millis,fmt,addFractional)
            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            
            % Create a duration with a format "like" another one, or with
            % a specific format.
            
            % Maintain a persistent copy of a scalar duration that can be used
            % as a template when the caller does not provide one. This helps us
            % avoid calling duration ctor for every call to fromMillis.
            persistent dTemplate
            if isempty(dTemplate)
                % We just need a duration object with default value for fmt. The
                % value of millis will always be overwritten.
                dTemplate = duration;
            end
            haveTemplate = (nargin > 1) && isa(fmt,'duration');
            if haveTemplate
                d = fmt; % 2nd arg is the template, not a format
            else
                d = dTemplate;
                if nargin > 1
                    if nargin > 2 && addFractional
                        fmt = duration.getFractionalSecondsFormat(millis,fmt);
                    end
                    d.fmt = convertStringsToChars(fmt);
                end
            end
            d.millis = millis;
        end

        function fmt = getFractionalSecondsFormat(data,fmt)
            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            
            % Find the longest fractional part by checking the modulus of the
            % milliseconds. Note: if mod(data,1000) == 0 so does mod(data,1)
            % etc. First, get the remainder, implicitly expanding in MOD into
            % Nx3 and look only at the non-zero values. Next, sum each row to
            % get the number of digit increments. Finally, find the row with the
            % most increments. Multiplying by three gets the number of digits
            % needed.
            % i.e. see: mod([1000;1001;1000.1;1000.00001],[1e3,1e0,1e-3]) > 0
            fractional = 3 * max(sum(mod(data(:),[1e3,1e0,1e-3]) > 0,2));
            if fractional  > 0
                fmt = [fmt '.' repmat('S',1,fractional)];
            end
        end
        
        function name = matlabCodegenRedirect(~)
            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            
            % Use the implementation in the class below when generating
            % code.
            name = 'matlab.internal.coder.duration';
        end
        
        function d = codegenInit(millis, fmt)
            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            
            % Only for use by codegen, for redirecting codegen output to
            % MATLAB.
            d = duration;
            d.millis = millis;
            d.fmt = fmt;
        end
    end % static hidden public methods block
    
    %=======================================================================
    methods(Access={?matlab.internal.tabular.private.explicitRowTimesDim, ?withtol})
        inds = timesubs2inds(subscripts,labels,tol)
    end
    
    %=======================================================================
    methods(Access='protected')
        this = subsasgnDot(this,s,rhs)
        this = subsasgnParens(this,s,rhs)
        value = subsrefDot(this,s)
        value = subsrefParens(this,s)
        fmt = getDisplayFormat(this)
        
        %-----------------------------------------------------------------------
        function chars = formatAsCharForDisplay(this)
            import matlab.internal.duration.formatAsString

            isLong = strncmp(matlab.internal.display.format,'long',4);
            chars = strjust(char(formatAsString(this.millis,this.fmt,isLong,false)),'right');
        end

        %-----------------------------------------------------------------------
        function missingText = getMissingTextDisplay(~)
            missingText = "NaN";
        end
    end
    
    %=======================================================================
    methods(Access=?matlab.unittest.TestCase, Static)
        [amillis,bmillis,template] = compareUtil(a,b)
    end
    
    %=======================================================================
    methods(Access='protected', Static)
        [argsMillis,template] = isequalUtil(args)
        millis = createFromFields(fields)
        
        function result = catUtil(dim, useSpecializedFcn, varargin)
            import matlab.internal.datatypes.isCharStrings;

            if ~isnumeric(dim)
                error(message('MATLAB:duration:cat:NonNumericDim'))
            end

            for i = 1:numel(varargin)
                arg = varargin{i};
                if (isstring(arg) && ~isscalar(arg)) || ischar(arg) && ~isCharStrings(arg)
                    error(message('MATLAB:duration:cat:InvalidConcatenation'));
                end
            end
            try
                [argsMillis,result] = duration.isequalUtil(varargin);
            catch ME
                matlab.internal.datatypes.throwInstead(ME, ...
                    "MATLAB:duration:InvalidComparison", ...
                    "MATLAB:duration:cat:InvalidConcatenation");
            end
            if useSpecializedFcn
                if dim == 1
                    result.millis = vertcat(argsMillis{:}); % use fmt from the first array
                elseif dim == 2
                    result.millis = horzcat(argsMillis{:}); % use fmt from the first array
                else
                    assert(false);
                end
            else
                result.millis = cat(dim,argsMillis{:}); % use fmt from the first array
            end
        end
    end % protected static methods block
    
    %======================= Testing Infrastructure ========================
    methods(Access=?matlab.unittest.TestCase, Static)
        function methodList = methodsWithNonDurationFirstArgument, methodList = {'cat'}; end
    end
end
