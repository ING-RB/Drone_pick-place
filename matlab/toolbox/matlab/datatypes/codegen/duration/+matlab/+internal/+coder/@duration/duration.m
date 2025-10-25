%#codegen
classdef duration < matlab.mixin.internal.indexing.Paren & ...
        matlab.mixin.internal.indexing.ParenAssign & coder.mixin.internal.SpoofReport
    %DURATION Arrays for Code Generation
    %
    % Limitations for Code Generation
    % - Text inputs and conversions
    % - Growth by assignment
    % - Deleting an element
    
    %   Copyright 2014-2021 The MathWorks, Inc.
    properties(GetAccess='protected', SetAccess='protected')
        % The duration data, stored as milliseconds
        millis = 0;
        
        % Format in which to display
        fmt = matlab.internal.coder.duration.DefaultDisplayFormat;
    end
    
    properties(GetAccess='public', Dependent=true)
        Format
    end
    properties(GetAccess='public', Hidden, Constant)
        DefaultDisplayFormat = 'hh:mm:ss';
    end
    
    
    properties(GetAccess='private', Constant)
        noConstructorParamsSupplied = struct('Format',uint32(0),'InputFormat',uint32(0));
    end
    
    properties(GetAccess='private', SetAccess='private', Dependent=true)
        data
    end
    methods
        function d = set.data(d,data)
            d.millis = data * 1000;
        end
        
        function f = get.Format(obj)
            f = obj.fmt;
        end
        
        function d = set.Format(d,in)
            f = convertStringsToChars(in);
            d.fmt =  matlab.internal.coder.duration.verifyFormat(f);
        end
        
    end
    
    methods(Access = 'public')
        function this = duration(inData,varargin)
            %DURATION Create an array of durations.
            %
            
            if nargin == 0 || ... % same as duration(0,0,0)
                    (nargin == 1 && isa(inData,'matlab.internal.coder.datatypes.uninitialized'))
                return;
            end
            
            numNumericArgs = 0;
            if isnumeric(inData)
                % Find how many numeric inputs args: count up until the first non-numeric.
                numNumericArgs = 1; % include inData
                for i = 1:numel(varargin)
                    if ~isnumeric(varargin{i}), break, end
                    numNumericArgs = numNumericArgs + 1;
                end
                
                nv = numel(varargin);
                
                if numNumericArgs == 1 % duration([h,m,s],...)
                    coder.internal.errorIf(~ismatrix(inData) || ~(size(inData,2) == 3), 'MATLAB:duration:InvalidNumericData');
                    % Split numeric matrix into separate vectors. Manual
                    % conversion to cell for performance
                    inData = double(inData);
                    normData = {inData(:,1),inData(:,2),inData(:,3)};
                    processedVarArgin = cell(1,nv);
                    for i = 1:nv
                        processedVarArgin{i} = convertStringsToChars(varargin{i});
                    end
                elseif numNumericArgs == 3 % duration(h,m,s,...)
                    normData = {inData, varargin{1}, varargin{2}};
                    processedVarArgin = cell(1, nv - 2);
                    for i = 3:nv
                        processedVarArgin{i-2} = convertStringsToChars(varargin{i});
                    end
                elseif numNumericArgs == 4 % duration(h,m,s,ms,...)
                    normData = {inData, varargin{1}, varargin{2}, varargin{3}};
                    processedVarArgin = cell(1, nv - 3);
                    for i = 4:nv
                        processedVarArgin{i-3} = convertStringsToChars(varargin{i});
                    end
                else
                    coder.internal.assert(false,'MATLAB:duration:InvalidNumericData');
                end
                convertFromText = false;
            elseif matlab.internal.coder.datatypes.isText(inData)
                % strips whitespace and converts to always be cell.
                convertFromText = true;
                processedVarArgin = {};
            else
                coder.internal.errorIf(~isa(inData,'duration') && ~isa(inData, 'missing'), 'MATLAB:duration:InvalidData');
            end
            
            if isempty(varargin)
                % Default format.
                outputFmt = matlab.internal.coder.duration.DefaultDisplayFormat;
                pstruct = this.noConstructorParamsSupplied;
            else
                % Accept explicit parameter name/value pairs.
                pnames = {'Format','InputFormat'};
                poptions = struct( ...
                    'CaseSensitivity',false, ...
                    'PartialMatching','unique', ...
                    'StructExpand',false);
                pstruct = coder.internal.parseParameterInputs(pnames,poptions,processedVarArgin{:});
                
                format = coder.internal.getParameterValue(pstruct.Format,matlab.internal.coder.duration.DefaultDisplayFormat,processedVarArgin{:});
                
                outputFmt = convertStringsToChars(format);
                if pstruct.Format
                    outputFmt = matlab.internal.coder.duration.verifyFormat(outputFmt);
                end
                if pstruct.InputFormat
                    if ~convertFromText
                        coder.internal.warning('MATLAB:duration:IgnoredInputFormat');
                    end
                end
                
            end
            
            if (numNumericArgs > 0) && ~convertFromText % numeric input, now cells
                % Construct from separate h,m,s arrays.
                thisMillis = matlab.internal.coder.duration.createFromFields(normData);
            elseif isa(inData,'duration')
                % Modify a duration array.
                thisMillis = milliseconds(inData);
                if pstruct.Format == 0, outputFmt = inData.Format; end
            elseif isa(inData, 'missing')
                % Create a NaN from a missing.
                thisMillis = double(inData);
            elseif convertFromText
                coder.internal.assert(false, 'MATLAB:duration:TextConstructionCodegen');
            end
            
            this.millis = thisMillis;
            this.fmt = outputFmt;
            
        end
        
        function b = parenReference(a, varargin)
            b = matlab.internal.coder.duration;
            b.millis = a.millis(varargin{:});
            b.fmt = a.fmt;
        end
        
        function this = parenAssign(this, rhs, varargin)
            if isa(rhs,'duration')
                if isa(this,'duration') % assignment from a duration array into another
                    this.millis(varargin{:}) = rhs.millis;
                else
                    coder.internal.error('MATLAB:duration:InvalidAssignmentLHS',class(rhs));
                end
            elseif isa(rhs, 'missing')
                this.millis(varargin{:}) = double(rhs);
                % Check isnumeric/isequal before builtin to short-circuit for performance
                % and to distinguish between '' and [].
            elseif isnumeric(rhs) && isequal(rhs,[]) && builtin('_isEmptySqrBrktLiteral',rhs) % deletion by assignment
                a = this.millis;
                a(varargin{:}) = []; %#ok<NASGU>
            else
                %try
                if isnumeric(rhs) || islogical(rhs)
                    newMillis = matlab.internal.coder.timefun.datenumToMillis(rhs,true); % allow non-double numeric
                else
                    [~,newMillis,~] = matlab.internal.coder.duration.compareUtil(this,rhs);
                end
                
                this.millis(varargin{:}) = newMillis;
                
            end
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
    end
    
    %% Unsupported Methods
    methods(Hidden)
        function s = char(~,~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'char', 'duration');
        end
        
        function c = cellstr(~,~,~)%#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cellstr', 'duration');
        end
        
        function s = string(~,~,~)%#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'string', 'duration');
        end
        
        function [bins, edges] = discretize(~,~,varargin)%#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'discretize', 'duration');
        end
        
        function [n,edges,bin] = histcounts(~, varargin)%#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'histcounts', 'duration');
        end
        
        function tf = isbetween(~,~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'isbetween', 'duration');
        end
        
        function [sorted,i] = maxk(~,~,varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'maxk', 'duration');
        end
        
        function [sorted,i] = mink(~,~,varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'mink', 'duration');
        end
        
        function that = round(~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'round', 'duration');
        end
        
        function [sorted,i] = topkrows(~,~,varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'topkrows', 'duration');
        end
        
        function n = datenum(~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'datenum', 'duration');
        end
    end
    
    methods(Access = 'public')
        %% Conversions to the legacy types
        function [y,mo,d,h,m,s] = datevec(this,varargin)
            s = this.millis / 1000; % ms -> s
            y1 = fix(s / (86400*365.2425)); % possibly negative, possibly nonfinite
            mo = zeros(size(s));
            mo(~isfinite(s)) = NaN;
            s = s - (86400*365.2425)*y1; % NaN if s was infinite
            d = fix(s / 86400);
            s = s - 86400*d;
            h = fix(s / 3600);
            s = s - 3600*h;
            m = fix(s / 60);
            s = s - 60*m;
            
            % Return the same non-finite in all fields.
            nonfiniteElems = ~isfinite(y1);
            nonfiniteVals = y1(nonfiniteElems);
            if ~isempty(nonfiniteVals)
                mo(nonfiniteElems) = nonfiniteVals;
                d(nonfiniteElems) = nonfiniteVals;
                h(nonfiniteElems) = nonfiniteVals;
                m(nonfiniteElems) = nonfiniteVals;
                s(nonfiniteElems) = nonfiniteVals;
            end
            
            if nargout <= 1
                y = [y1(:),mo(:),d(:),h(:),m(:),s(:)];
            else
                y = y1;
            end
        end
        
        %% Array methods
        function [varargout] = size(this,varargin)
            coder.internal.prefer_const(varargin);
            [varargout{1:nargout}] = size(this.millis,varargin{:});
        end
        function l = length(this)
            l = length(this.millis);
        end
        function n = ndims(this)
            n = ndims(this.millis);
        end
        
        function n = numel(this)
            n = numel(this.millis);
            
        end
        
        function t = repmat(this,varargin)
            t = matlab.internal.coder.duration;
            t.fmt = this.fmt;
            t.millis = repmat(this.millis,varargin{:});
        end
        
        function t = isempty(a),  t = isempty(a.millis);  end
        function t = isscalar(a), t = isscalar(a.millis); end
        function t = isvector(a), t = isvector(a.millis); end
        function t = isrow(a),    t = isrow(a.millis);    end
        function t = iscolumn(a), t = iscolumn(a.millis); end
        function t = ismatrix(a), t = ismatrix(a.millis); end
        
        
        function result = cat(dim,varargin)
            result = duration.catUtil(dim,false,varargin{:});
        end
        
        function result = horzcat(varargin)
            result = duration.catUtil(2,true,varargin{:});
        end
        
        function result = vertcat(varargin)
            result = duration.catUtil(1,true,varargin{:});
        end
        
        function that = ctranspose(this)
            that = matlab.internal.coder.duration;
            that.fmt = this.fmt;
            that.millis = ctranspose(this.millis);
        end
        function that = transpose(this)
            that = matlab.internal.coder.duration;
            that.fmt = this.fmt;
            that.millis = transpose(this.millis);
        end
        
        function that = reshape(this,varargin)
            that = matlab.internal.coder.duration;
            that.fmt = this.fmt;
            that.millis = reshape(this.millis,varargin{:});
        end
        function that = permute(this,order)
            that = matlab.internal.coder.duration;
            that.fmt = this.fmt;
            that.millis = permute(this.millis,order);
        end
        
        %% Relational operators
        function t = eq(a,b)
            coder.internal.implicitExpansionBuiltin;
            [amillis,bmillis] = matlab.internal.coder.duration.compareUtil(a,b);
            t = (amillis == bmillis);
        end
        
        function t = ne(a,b)
            coder.internal.implicitExpansionBuiltin;
            [amillis,bmillis] = matlab.internal.coder.duration.compareUtil(a,b);
            t = (amillis ~= bmillis);
        end
        
        function t = lt(a,b)
            coder.internal.implicitExpansionBuiltin;
            [amillis,bmillis] = matlab.internal.coder.duration.compareUtil(a,b);
            t = (amillis < bmillis);
        end
        
        function t = le(a,b)
            coder.internal.implicitExpansionBuiltin;
            [amillis,bmillis] = matlab.internal.coder.duration.compareUtil(a,b);
            t = (amillis <= bmillis);
        end
        
        function t = ge(a,b)
            coder.internal.implicitExpansionBuiltin;
            [amillis,bmillis] = matlab.internal.coder.duration.compareUtil(a,b);
            t = (amillis >= bmillis);
        end
        
        function t = gt(a,b)
            coder.internal.implicitExpansionBuiltin;
            [amillis,bmillis] = matlab.internal.coder.duration.compareUtil(a,b);
            t = (amillis > bmillis);
        end
        
        function t = isequal(varargin)
            narginchk(2,Inf);
            [argsMillis,~,validComparison] = matlab.internal.coder.duration.isequalUtil(varargin);
            if validComparison
                t = isequal(argsMillis{:});
            else
                t = false;
            end
        end
        
        function t = isequaln(varargin)
            narginchk(2,Inf);
            [argsMillis,~,validComparison] = matlab.internal.coder.duration.isequalUtil(varargin);
            if validComparison
                t = isequaln(argsMillis{:});
            else
                t = false;
            end
        end
        
        %% Math
        function y = eps(x)
            y = matlab.internal.coder.duration;
            
            % Output eps in a simple format (not a digital timer format; e.g. hh:mm:ss)
            if any(x.fmt == ':')
                y.fmt = 's';
            else
                y.fmt = x.fmt;
            end
            y.millis = eps(x.millis);
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
            coder.internal.implicitExpansionBuiltin;
            [xmillis,ymillis,template] = duration.compareUtil(x,y);
            z = matlab.internal.coder.duration;
            z.fmt = template.fmt;
            z.millis = mod(xmillis,ymillis);
        end
        function z = rem(x,y)
            coder.internal.implicitExpansionBuiltin;
            [xmillis,ymillis,template] = duration.compareUtil(x,y);
            z = matlab.internal.coder.duration;
            z.fmt = template.fmt;
            z.millis = rem(xmillis,ymillis);
        end
        
    end % public methods block
    
    methods(Hidden = true)
        %% Arrayness
        function e = end(this,k,n)
            dims = ndims(this.millis);
            if k == n && k <= dims
                e = 1;
                coder.unroll();
                for i = k:dims
                    % Collapse the dimensions beyond N and return the end.
                    % Use an explicit for loop to look at the size of each
                    % dim individually to avoid issues for varsize inputs.
                    e = e * size(this.millis,i);
                end
            else % k > n || k < n || k > ndims(a)
                % for k > n or k > ndims(a), e is 1
                e = size(this.millis,k);
            end
        end
        
        %% Error stubs
        % Methods to override functions and throw helpful errors
        function d = double(d), coder.internal.assert(false,'MATLAB:duration:InvalidNumericConversion','double'); end
        function d = single(d), coder.internal.assert(false,'MATLAB:duration:InvalidNumericConversion','single'); end
        function d = month(d), coder.internal.assert(false,'MATLAB:duration:MonthsNotSupported','month'); end
        function d = months(d), coder.internal.assert(false,'MATLAB:duration:MonthsNotSupported','months'); end
        
    end % hidden public methods block
    
    methods(Hidden = true, Static = true)
        
        function d = fromMillis(millis,fmt,addFractional)
            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            d = matlab.internal.coder.duration;
            coder.internal.assert(nnz(imag(millis))==0,'MATLAB:duration:MustBeRealMillis');
            d.millis = real(millis);
            
            if nargin > 1
                if nargin > 2 && addFractional
                    fmt = duration.getFractionalSecondsFormat(millis,fmt);
                end
                d.fmt = convertStringsToChars(fmt);
            else
                d.fmt = matlab.internal.coder.duration.DefaultDisplayFormat;
            end
        end
        
        function fmt = getFractionalSecondsFormat(data,fmt)
            fractional = 3 * max(sum(mod(data(:),[1e3,1e0,1e-3]) > 0,2));
            if fractional  > 0
                fmt = [fmt '.' repmat('S',1,fractional)];
            end
        end
        
        function b = matlabCodegenToRedirected(a)
            b = matlab.internal.coder.duration();
            b.millis = milliseconds(a);
            b.fmt = a.Format;
        end
        
        function b = matlabCodegenFromRedirected(a)
            b = duration.codegenInit(a.millis, a.fmt);
        end
        
        
        function t = matlabCodegenTypeof(~)
            t = 'matlab.coder.type.DurationType';
        end
        
    end
    
    methods (Static, Hidden)
        function name = matlabCodegenUserReadableName
            % Make this look like a duration (not the redirected duration) in the codegen report
            name = 'duration';
        end
        fmt = verifyFormat(fmt)
    end
    
    
    methods (Static, Access=?durationCodegenMethodHelper)
        [amillis,bmillis,template] = compareUtil(a,b)
    end
    methods(Access={?matlab.internal.coder.tabular.private.explicitRowTimesDim, ...
                    ?matlab.internal.coder.withtol})
        inds = timesubs2inds(subscripts,labels,tol)
    end

    % static hidden public methods block
    methods(Static, Access='protected')
        [argsMillis,template,validComparison] = isequalUtil(args)
        millis = createFromFields(fields)

        function result = catUtil(dim, useSpecializedFcn, varargin)
            coder.internal.assert(coder.internal.isConst(dim),'Coder:toolbox:dimNotConst');
            dim = coder.const(dim);
            useSpecializedFcn = coder.const(useSpecializedFcn);
            coder.unroll();
            for i = 1:numel(varargin)
                arg = varargin{i};
                coder.internal.errorIf((isstring(arg) && ~isscalar(arg)) || ischar(arg) && ~matlab.internal.coder.datatypes.isCharStrings(arg), 'MATLAB:duration:cat:InvalidConcatenation');
            end
            % It should be possible to make the second output of isequalUtil 'result'
            % and assign only to result.millis (rather than allocating a new duration
            % and assigning to both result.millis and result.fmt). As per g2176979,
            % however, this causes a crash in codegen for any subsequent method calls
            % on the output of duration/cat.
            [argsMillis,template,validComparison] = matlab.internal.coder.duration.isequalUtil(varargin);
            coder.internal.errorIf(~validComparison,'MATLAB:duration:cat:InvalidConcatenation');
            result = duration(matlab.internal.coder.datatypes.uninitialized);
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
            result.fmt = template.fmt;
        end
    end % protected static methods block
    
end
