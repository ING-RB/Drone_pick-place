function [b,tf,lthresh,uthresh,center] = filloutliers(a,fill,varargin)
% Syntax:
%   B = filloutliers(A,FILL)
%   B = filloutliers(A,FILL,METHOD)
%   B = filloutliers(A,FILL,"percentiles",[LP UP])
%   B = filloutliers(A,FILL,MOVMETHOD,WL)
%   B = filloutliers(___,DIM)
%   B = filloutliers(___,Name=Value)
%   [B,TF,LTHRESH,UTHRESH,CENTER] = filloutliers(___) 
%
%   Name-Value Arguments:  
%       ThresholdFactor
%       SamplePoints
%       MaxNumOutliers
%       OutlierLocations
%       DataVariables
%       ReplaceValues
%
% For more information, see documentation

%   Copyright 2016-2024 The MathWorks, Inc.

[method, wl, dim, p, sp, vars, fill, maxoutliers, lowup, replace] = ...
    parseinput(a, fill, varargin);

dim = min(dim, ndims(a)+1);
xistable = istabular(a);

if xistable
    if replace
        b = a;
    else
        b = a(:,vars);
        vars = 1:width(b);
    end
    tf = false(size(b));
    if nargout > 2
        if ~islogical(method) && ismember(method, {'movmedian', 'movmean'})
            % with moving methods, the thresholds and center have the same
            % size as input
            lthresh = b(:,vars);
        elseif height(b) == 0
            lthresh = b(:,vars);
            lthresh = matlab.internal.datatypes.lengthenVar(lthresh,1);
        else
            % with other methods, thresholds and center has reduced
            % dimension along first dimension
            lthresh = b(1,vars);
        end
        uthresh = lthresh;
        center = lthresh;
    end

    if istabular(method)
        % Convert names in cell arrays to string to allow direct dot index
        % Need to get the actual names to allow random order of
        % variable names in tabular OutlierLocations
        locnames = string(method.Properties.VariableNames);
    end

    for i = 1:length(vars)
        vari = b.(vars(i));
        if ~(isempty(vari) || iscolumn(vari))
            error(message('MATLAB:filloutliers:NonColumnTableVar'));
        end
        if ~isfloat(vari)
            error(message('MATLAB:filloutliers:NonfloatTableVar',...
                b.Properties.VariableNames{vars(i)}, class(vari)));
        end
        if ~isreal(vari)
            error(message('MATLAB:filloutliers:ComplexTableVar'));
        end
        if islogical(method)
            if isequal(size(method,2),1)
                % One DataVariable is specified and OutlierLocation is a
                % valid logical vector
                [out, lt, ut, c, yi] = matlab.internal.math.locateoutliers(vari, ...
                    method, wl, p, sp, maxoutliers, fill, lowup);
            else
                [out, lt, ut, c, yi] = matlab.internal.math.locateoutliers(vari, ...
                    method(:,vars(i)), wl, p, sp, maxoutliers, fill, lowup);
            end
        elseif istabular(method)
            methodi = method.(locnames(i));
            [out, lt, ut, c, yi] = matlab.internal.math.locateoutliers(vari, ...
                methodi, wl, p, sp, maxoutliers, fill, lowup);
        else
            [out, lt, ut, c, yi] = matlab.internal.math.locateoutliers(vari, ...
                method, wl, p, sp, maxoutliers, fill, lowup);
        end
        tf(:,vars(i)) = any(out,2);
        b.(vars(i)) = yi;
        if nargout > 2
            lthresh.(i) = lt;
            uthresh.(i) = ut;
            center.(i) = c;
        end
    end
    if ~replace
        b = matlab.internal.math.appendDataVariables(a,b,"filled");
        if nargout > 1
            tf = [false(size(a)) tf];
        end
    end
else
    asparse = issparse(a);
    % Avoid overhead for unnecessary permute calls
    if (dim > 1) && ~isscalar(a)
        dims = 1:max(ndims(a),dim);
        dims(1) = dim;
        dims(dim) = 1;
        if asparse && dim > 2
            % permuting beyond second dimension not supported for sparse
            a = full(a);
        end
        a = permute(a, dims);
        if islogical(method)
            method = permute(method, dims);
        end
    end
    [tf, lthresh, uthresh, center, b] = matlab.internal.math.locateoutliers(a, method, ...
        wl, p, sp, maxoutliers, fill, lowup);

    if (dim > 1) && ~isscalar(a)
        b = ipermute(b, dims);
        if asparse
            % explicitly convert to sparse. If dim > 2, we have converted
            % to full previously
            b = sparse(b);
        end
        if nargout > 1
            tf = ipermute(tf, dims);
            lthresh = ipermute(lthresh, dims);
            uthresh = ipermute(uthresh, dims);
            center = ipermute(center, dims);
            if asparse
                tf = sparse(tf);
                lthresh = sparse(lthresh);
                uthresh = sparse(uthresh);
                center = sparse(center);
            end
        end
    end

end

function [method, wl, dim, p, samplepoints, datavariables, fill, ...
    maxoutliers, lowup, replace] = parseinput(a, fill, input)
% Parse FILLOUTLIER inputs
method = 'median';
methodinput = false;
wl = [];
p = [];
samplepoints = [];
datavariables = [];
dataVarsProvided = false;
OutlierLocationProvided = false;
maxoutliers = [];
lowup = [];
replace = true;
funcname = mfilename;

validateattributes(a,{'single','double','table','timetable'}, {'real'}, funcname, 'A', 1);
aistable = istabular(a);
if aistable
    datavariables = 1:width(a);
end
% dim
if aistable
    dim = 1;
else
    dim = matlab.internal.math.firstNonSingletonDim(a);
end

if ischar(fill) || isstring(fill)
    fill = validatestring(fill, {'center', 'clip',...
        'previous', 'next', 'nearest', 'linear', 'spline', ...
        'pchip','makima'},funcname, 'Fill', 2);
else
    validateattributes(fill, {'numeric'}, {'scalar'}, funcname, ...
        'Fill', 2);
end

if ~isempty(input)
    i = 1;
    % parse methods and movmethod
    if ischar(input{i}) || isstring(input{i})
        str = validatestring(input{i},{'median', 'mean', 'quartiles', 'grubbs', ...
            'gesd', 'movmedian', 'movmean', 'percentiles', 'SamplePoints', 'ReplaceValues', ...
            'DataVariables', 'ThresholdFactor', 'MaxNumOutliers', 'OutlierLocations'}, i+2);
        if ismember(str, {'median', 'mean', 'quartiles', 'grubbs','gesd'})
            % method
            method = str;
            methodinput = true;
            i = i+1;
        elseif ismember(str, {'movmedian', 'movmean'})
            % movmethod
            method = str;
            if isscalar(input)
                error(message('MATLAB:filloutliers:MissingWindowLength',method));
            end
            methodinput = true;
            wl = input{i+1};
            if (isnumeric(wl) && isreal(wl)) || islogical(wl) || isduration(wl)
                if isscalar(wl)
                    if wl <= 0 || ~isfinite(wl)
                        error(message('MATLAB:filloutliers:WindowLengthInvalidSizeOrClass'));
                    end
                elseif numel(wl) == 2
                    if any(wl < 0 | ~isfinite(wl))
                        error(message('MATLAB:filloutliers:WindowLengthInvalidSizeOrClass'));
                    end
                else
                    error(message('MATLAB:filloutliers:WindowLengthInvalidSizeOrClass'));
                end
            else
                error(message('MATLAB:filloutliers:WindowLengthInvalidSizeOrClass'));
            end
            i = i+2;
        elseif isequal(str,'percentiles')
            method = str;
            methodinput = true;
            lowup = input{i+1};
            if  ~isnumeric(lowup) || ~isreal(lowup) || ~isequal(size(lowup),[1 2]) || any(isnan(lowup)) ||...
                    lowup(1)<0 || lowup(1)>100 || lowup(2)<0 || lowup(2)>100 || lowup(1)>lowup(2)
                error(message('MATLAB:filloutliers:PercentilesInvalid'));
            end
            i = i+2;
        end
    end
    % parse dim
    if i <= length(input)
        if ~(ischar(input{i}) || isstring(input{i}))
            validateattributes(input{i},{'numeric'}, {'scalar', 'integer', 'positive'}, ...
                funcname, 'dim', i+2);
            dim = input{i};
            if aistable && dim ~= 1
                error(message('MATLAB:filloutliers:TableDim'));
            end
            i = i+1;
        end

        % parse N-V pairs
        inputlen = length(input);
        spvar = [];
        if rem(inputlen - i + 1,2) ~= 0
            error(message('MATLAB:filloutliers:ArgNameValueMismatch'))
        end
        for i = i:2:inputlen
            name = validatestring(input{i}, {'SamplePoints', 'ReplaceValues',...
                'DataVariables', 'ThresholdFactor', 'MaxNumOutliers', 'OutlierLocations'}, i+2);

            value = input{i+1};
            switch name
                case 'SamplePoints'
                    if istimetable(a)
                        error(message('MATLAB:samplePoints:SamplePointsTimeTable'));
                    end
                    [samplepoints,spvar] = matlab.internal.math.checkSamplePoints(value,a,aistable,false,dim);
                    if ~isempty(a) && ~(isfloat(samplepoints) || isduration(samplepoints) || isdatetime(samplepoints))
                        error(message('MATLAB:samplePoints:SamplePointsInvalidDatatype'));
                    end
                case 'DataVariables'
                    if aistable
                        datavariables = matlab.internal.math.checkDataVariables(a,value,'filloutliers');
                        dataVarsProvided = true;
                    else
                        error(message('MATLAB:filloutliers:DataVariablesArray'));
                    end
                case 'ReplaceValues'
                    if aistable
                        replace = matlab.internal.datatypes.validateLogical(value,'ReplaceValues');
                    else
                        error(message('MATLAB:filloutliers:ReplaceValuesArray'));
                    end
                case 'ThresholdFactor'
                    if isequal(method,'percentiles')
                        error(message('MATLAB:filloutliers:UnsupportedThreshold'));
                    end
                    validateattributes(value,{'numeric'}, {'real', 'scalar', ...
                        'nonnegative', 'nonnan'}, funcname, 'ThresholdFactor', i+3);
                    p = double(value);
                case 'MaxNumOutliers'
                    validateattributes(value,{'numeric'}, {'scalar', 'positive', ...
                        'integer'}, funcname, 'MaxNumOutliers', i+3);
                    maxoutliers = double(value);
                case 'OutlierLocations'
                    loc = value;
                    
                    if methodinput
                        error(message('MATLAB:filloutliers:MethodNotAllowed'));
                    end
                    if any(strcmp(fill, {'center', 'clip'}))
                        error(message('MATLAB:filloutliers:UnsupportedFill'));
                    end
                    method = value;
                    OutlierLocationProvided = true;
            end
        end
        if ~isempty(spvar)
            datavariables(datavariables == spvar) = [];
        end

        if OutlierLocationProvided
            if istabular(loc) && aistable
                datavariables = validateTabularOutlierLocations(a,loc,datavariables,dataVarsProvided);
            else
                if isvector(loc) && isscalar(datavariables)
                    validateattributes(loc,{'logical'}, {'size', [size(a,1) numel(datavariables)]}, ...
                        funcname, 'OutlierLocations');
                else
                    validateattributes(loc,{'logical'}, {'size', size(a)}, ...
                        funcname, 'OutlierLocations');
                end
            end
        end
    end
end
if ~islogical(method) && ~istabular(method)
    if isempty(p)  % default p
        switch method
            case {'median','mean','movmedian','movmean'}
                p = 3;
            case 'quartiles'
                p = 1.5;
            otherwise % grubbs, gesd
                p = 0.05;
        end
    elseif ismember(method, {'grubbs', 'gesd'})
        if p > 1
            error(message('MATLAB:filloutliers:AlphaOutOfRange'));
        end
    end
end

if ~isempty(maxoutliers)
    if ~strcmp(method, 'gesd')
        error(message('MATLAB:filloutliers:MaxNumOutliersGesdOnly'));
    elseif maxoutliers > size(a,dim)
        error(message('MATLAB:filloutliers:MaxNumOutliersTooLarge'));
    end
end

if (isdatetime(samplepoints) || isduration(samplepoints)) && ...
        ~isempty(wl) && ~isduration(wl)
    error(message('MATLAB:samplePoints:SamplePointsNonDuration'));
end
if istimetable(a)
    samplepoints = a.Properties.RowTimes;
end


function datavariables = validateTabularOutlierLocations(a,loc,datavariables,dataVarsProvided)
vnames = loc.Properties.VariableNames;
tnames = a.Properties.VariableNames;
if dataVarsProvided
    if ~all(ismember(tnames(datavariables),vnames))
        % DataVariable names must be present in loc table
        error(message('MATLAB:filloutliers:InvalidLocationsWithDataVars'));
    end
else
    try
        datavariables = matlab.internal.math.checkDataVariables(a, vnames, 'filloutliers');
    catch
        error(message('MATLAB:filloutliers:InvalidTabularLocationsFirstInput'));
    end
end

vnames = string(vnames);
for ii=vnames
    if ~islogical(loc.(ii)) || ~isequal(size(a.(ii)),size(loc.(ii)))
        error(message('MATLAB:filloutliers:LogicalVarsRequired'));
    end
end
