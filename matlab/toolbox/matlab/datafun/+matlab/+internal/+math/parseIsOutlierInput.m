function [method, wl, dim, p, samplepoints, datavariables, maxoutliers, lowup, fmt] = ...
    parseIsOutlierInput(a, isRmoutliers,input)
% parseIsOutlierInput Helper function for ISOUTLIER and RMOUTLIERS.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2022 - 2024 The MathWorks, Inc.

method = 'median';
wl = [];
p = [];
samplepoints = [];
datavariables = [];
maxoutliers = [];
lowup = [];
spvar = [];
funcname = 'isoutlier';
fmt = 'logical';

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

if ~isempty(input)
    i = 1;
    if isRmoutliers
        validNames = {'SamplePoints','DataVariables', 'ThresholdFactor', ...
            'OutlierLocations', 'MaxNumOutliers', 'MinNumOutliers'};
    else
        validNames = {'SamplePoints','DataVariables', 'ThresholdFactor', 'MaxNumOutliers', 'OutputFormat'};
    end
    % parse methods and movmethod
    if ischar(input{i}) || isstring(input{i})
        validMethods = [{'median', 'mean', 'quartiles', 'grubbs', ...
            'gesd', 'movmedian', 'movmean', 'percentiles'} validNames];

        str = validatestring(input{i},validMethods, i+1);

        if ismember(str, {'median', 'mean', 'quartiles', 'grubbs','gesd'})
            % method
            method = str;
            i = i+1;
        elseif ismember(str, {'movmedian', 'movmean'})
            % movmethod
            method = str;
            if isscalar(input)
                error(message('MATLAB:isoutlier:MissingWindowLength',method));
            end
            wl = input{i+1};
            if (isnumeric(wl) && isreal(wl)) || islogical(wl) || isduration(wl) 
                if isscalar(wl)
                    if wl <= 0 || ~isfinite(wl) 
                        error(message('MATLAB:isoutlier:WindowLengthInvalidSizeOrClass'));
                    end
                elseif numel(wl) == 2
                    if any(wl < 0 | ~isfinite(wl)) 
                        error(message('MATLAB:isoutlier:WindowLengthInvalidSizeOrClass'));
                    end
                else
                    error(message('MATLAB:isoutlier:WindowLengthInvalidSizeOrClass'));
                end       
            else
                error(message('MATLAB:isoutlier:WindowLengthInvalidSizeOrClass'));
            end
            i = i+2;
        elseif isequal(str,'percentiles')
            method = str;
            lowup = input{i+1};
            if  ~isnumeric(lowup) || ~isreal(lowup) || ~isequal(size(lowup),[1 2]) || any(isnan(lowup)) ||...
                    lowup(1)<0 || lowup(1)>100 || lowup(2)<0 || lowup(2)>100 || lowup(1)>lowup(2)
                error(message('MATLAB:isoutlier:PercentilesInvalid'));
            end
            i = i+2;
        end
    end
    % parse dim
    if i <= length(input)
        if ~(ischar(input{i}) || isstring(input{i}))
            validateattributes(input{i},{'numeric'}, {'scalar', 'integer', 'positive'}, ...
                funcname, 'dim', i+1);
            dim = input{i};
            if aistable && dim ~= 1
                error(message('MATLAB:isoutlier:TableDim'));
            end
            i = i+1;
        end
        
        % parse N-V pairs
        inputlen = length(input);
        if rem(inputlen - i + 1,2) ~= 0
            error(message('MATLAB:isoutlier:ArgNameValueMismatch'))
        end
     
        for i = i:2:inputlen

            name = validatestring(input{i}, validNames, i+1);
            
            value = input{i+1};
            switch name
                case 'SamplePoints'
                    if istimetable(a)
                        error(message('MATLAB:samplePoints:SamplePointsTimeTable'));
                    end
                    [samplepoints,spvar] = matlab.internal.math.checkSamplePoints(value,a,aistable,false,dim);
                    if ~(isfloat(samplepoints) || isduration(samplepoints) || isdatetime(samplepoints))
                        error(message('MATLAB:samplePoints:SamplePointsInvalidDatatype'));
                    end
                case 'DataVariables'
                    if aistable
                        datavariables = matlab.internal.math.checkDataVariables(a,value,funcname);
                    else
                        error(message('MATLAB:isoutlier:DataVariablesArray'));
                    end
                case 'OutputFormat'
                    if aistable
                        fmt = validatestring(value,{'logical','tabular'},funcname,'OutputFormat');
                    else
                        error(message('MATLAB:isoutlier:OutputFormatArray'));
                    end
                case 'ThresholdFactor'
                    if isequal(method,'percentiles')
                        error(message('MATLAB:isoutlier:UnsupportedThreshold'));
                    end
                    validateattributes(value,{'numeric'}, {'real', 'scalar', ...
                        'nonnegative', 'nonnan'}, funcname, 'ThresholdFactor');
                    p = double(value);
                case 'MaxNumOutliers'
                    validateattributes(value,{'numeric'}, {'scalar', 'positive', ...
                        'integer'}, funcname, 'MaxNumOutliers');
                    maxoutliers = double(value);
            end
        end
        if ~isempty(spvar)
            datavariables(datavariables == spvar) = [];
        end
    end
end
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
        error(message('MATLAB:isoutlier:AlphaOutOfRange'));
    end
end

if ~isempty(maxoutliers)
    if ~strcmp(method, 'gesd')
        error(message('MATLAB:isoutlier:MaxNumOutliersGesdOnly'));
    elseif maxoutliers > size(a,dim)
        error(message('MATLAB:isoutlier:MaxNumOutliersTooLarge'));
    end
end

if (isdatetime(samplepoints) || isduration(samplepoints)) && ...
        ~isempty(wl) && ~isduration(wl)
    error(message('MATLAB:samplePoints:SamplePointsNonDuration'));
end
if istimetable(a)
    % Let NaTs in row times flow through
    samplepoints = a.Properties.RowTimes;
end