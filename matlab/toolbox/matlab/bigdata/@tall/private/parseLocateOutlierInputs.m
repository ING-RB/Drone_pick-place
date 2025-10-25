function opts = parseLocateOutlierInputs(A,fname,varargin)
% Parse and check inputs for tall/isoutlier and tall/filloutliers.

%   Copyright 2017-2022 The MathWorks, Inc.

fillOutliers = strcmpi(fname,'filloutliers');

opts.IsTabular = ismember(A.Adaptor.Class,{'table', 'timetable'});
opts.Method = 'median';
opts.Window = [];
opts.ReplaceValues = true;
opts.OutputFormat = 'logical';

if fillOutliers
    % Match FILLOUTLIERS(A,FILL,...) error message.
    tall.checkNotTall(upper(fname),1,varargin{1});
    if ischar(varargin{1}) || isstring(varargin{1})
        varargin{1} = validatestring(varargin{1}, {'center', 'clip', ...
            'previous', 'next', 'nearest', 'linear', 'spline', ...
            'pchip', 'makima'},fname,'Fill',2);
    else
        validateattributes(varargin{1},{'numeric'},{'scalar'},fname, ...
            'Fill',2);
    end
    opts.Fill = varargin{1};
end

computeOutliers = false;
ind = 1+fillOutliers; % Account for presence of FILL method.
if nargin-1 > ind && (ischar(varargin{ind}) || isstring(varargin{ind}))
    tall.checkNotTall(upper(fname),ind,varargin{ind});
    % Match ISOUTLIER(A,METHOD,N1,V1,...) error message.
    % Match FILLOUTLIERS(A,FILL,METHOD,N1,V1,...) error message.
    validParams = {'median', 'mean', 'quartiles', 'grubbs', 'gesd', ...
        'movmedian', 'movmean', 'percentiles', 'SamplePoints', 'DataVariables', ...
        'ThresholdFactor', 'MaxNumOutliers'};
    if fillOutliers
        validParams = [validParams, {'OutlierLocations', 'ReplaceValues'}];
    else % isoutlier
        validParams = [validParams, {'OutputFormat'}];
    end
    mthd = validatestring(varargin{ind},validParams,ind+1);
    if any(strcmpi(mthd,{'median', 'mean', 'quartiles'}))
        opts.Method = mthd;
        computeOutliers = true;
        ind = ind+1;
    elseif any(strcmpi(mthd,{'movmean', 'movmedian'}))
        % Parse the mov methods as in tall/fillmissing.
        % Match ISOUTLIER(A,MOVMETHOD,WINDOW,N1,V1,...) error.
        % Match FILLOUTLIERS(A,FILL,MOVMETHOD,WINDOW,N1,V1,...) error.
        if nargin-1 < 3+fillOutliers
            error(message(['MATLAB:',fname,':MissingWindowLength'],mthd));
        end
        if strcmpi(A.Adaptor.Class,'timetable')
            error(message('MATLAB:bigdata:array:OutliersMovmethodTimetable'));
        end
        tall.checkNotTall(upper(fname),ind+1,varargin{ind+1});
        movOpts = parseMovOpts(str2func(mthd),varargin{ind+1});
        opts.Window = movOpts.window;
        opts.Method = mthd;
        computeOutliers = true;
        ind = ind+2;
    elseif any(strcmpi(mthd,{'grubbs', 'gesd'}))
        error(message('MATLAB:bigdata:array:OutliersGrubbsGesd'));
    elseif strcmpi(mthd,'percentiles')
        error(message('MATLAB:bigdata:array:OutliersPercentiles'));
    end
end

% Other defaults
if opts.IsTabular
    opts.Dim = 1;
    opts.AllVars = getVariableNames(A.Adaptor);
    opts.DataVars = opts.AllVars;
else
    opts.Dim = []; % [] denotes that DIM is unknown.
end

if strcmpi(opts.Method,'quartiles')
    opts.ThresholdFactor = 1.5;
else % {'median','mean','movmedian','movmean'}
    opts.ThresholdFactor = 3;
end

% No trailing optional inputs
if nargin-1 <= ind
    return;
end

% ISOUTLIER(A,DIM,...)
% ISOUTLIER(A,METHOD,DIM,...)
% ISOUTLIER(A,MOVMETHOD,WIN,DIM,...)
% FILLOUTLIERS(A,FILL,DIM,...)
% FILLOUTLIERS(A,FILL,METHOD,DIM,...)
% FILLOUTLIERS(A,FILL,MOVMETHOD,WIN,DIM,...)
if ~(ischar(varargin{ind}) || isstring(varargin{ind}))
    tall.checkNotTall(upper(fname),ind,varargin{ind});
    % Match in-memory check.
    validateattributes(varargin{ind},{'numeric'},{'scalar','integer',...
        'positive'},fname,'dim',ind+1);
    opts.Dim = varargin{ind};
    ind = ind+1;
    if opts.IsTabular && opts.Dim ~= 1
        error(message(['MATLAB:',fname,':TableDim']));
    end
end

% Trailing N-V pairs
if rem(numel(varargin(ind:end)),2) ~= 0
    error(message(['MATLAB:',fname,':ArgNameValueMismatch']));
end
validParams = {'SamplePoints', 'DataVariables', 'ThresholdFactor', 'MaxNumOutliers'};
if fillOutliers
    validParams = [validParams, {'ReplaceValues', 'OutlierLocations'}];
else % isoutlier
    validParams = [validParams, {'OutputFormat'}];
end

for ii = ind:2:numel(varargin)
    tall.checkNotTall(upper(fname),ii,varargin{ii});
    parName = validatestring(varargin{ii},validParams,ii+1);
    parVal = varargin{ii+1};
    switch parName
        case 'SamplePoints'
            error(message('MATLAB:bigdata:array:SamplePointsNotSupported'));
        case 'DataVariables'
            tall.checkNotTall(upper(fname),ii+1,parVal);
            if opts.IsTabular
                varInds = checkDataVariables(A,parVal,fname);
                opts.DataVars = opts.AllVars(sort(varInds));
            else
                error(message(['MATLAB:',fname,':DataVariablesArray']));
            end
        case 'ThresholdFactor'
            tall.checkNotTall(upper(fname),ii+1,parVal);
            % Match in-memory check.
            validateattributes(parVal,{'numeric'},{'real', 'scalar', ...
                'nonnegative', 'nonnan'},fname,'ThresholdFactor');
            opts.ThresholdFactor = double(parVal);
        case 'MaxNumOutliers'
            tall.checkNotTall(upper(fname),ii+1,parVal);
            % Match in-memory check.
            validateattributes(parVal,{'numeric'},{'scalar', ...
                'positive','integer'},fname,'MaxNumOutliers');
            if ~strcmpi(opts.Method,'gesd')
                error(message(['MATLAB:',fname,':MaxNumOutliersGesdOnly']));
            end
        case 'ReplaceValues'
            if ~opts.IsTabular
                error(message("MATLAB:filloutliers:ReplaceValuesArray"))
            end
            tall.checkNotTall(upper(fname),ii+1,parVal);
            opts.ReplaceValues = matlab.internal.datatypes.validateLogical(parVal, "Replacevalues");
        case 'OutputFormat'
            if ~opts.IsTabular
                error(message("MATLAB:isoutlier:OutputFormatArray"))
            end
            tall.checkNotTall(upper(fname),ii+1,parVal);
            opts.OutputFormat = validatestring(parVal,["logical","tabular"],fname,"OutputFormat");
        otherwise % 'OutlierLocations'
            % Must be tall and have the same size as the first input.
            tall.checkIsTall(upper(fname),ii+2,parVal);
            parVal = tall.validateType(parVal,fname,{'logical'},ii+2);
            [A,parVal] = validateSameTallSize(A,parVal);
            [A,parVal] = tall.validateSameSmallSizes(A,parVal,...
                'MATLAB:bigdata:array:OutliersLocation');
            % Match in-memory check.
            if computeOutliers
                error(message('MATLAB:filloutliers:MethodNotAllowed'));
            end
            if any(strcmpi(opts.Fill,{'center', 'clip'}))
                error(message('MATLAB:filloutliers:UnsupportedFill'));
            end
            opts.Method = parVal;
    end
end