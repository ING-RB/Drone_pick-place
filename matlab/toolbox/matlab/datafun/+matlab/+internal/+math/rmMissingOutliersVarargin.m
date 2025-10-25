function opts = rmMissingOutliersVarargin(funName,A,opts,...
    errorForDataVars,varargin)
% rmMissingOutliersVarargin Helper to parse DIM and N-V pairs for RMMISSING
% and RMOUTLIERS and inputs which need to be forwarded on to ISOUTLIER.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2018-2024 The MathWorks, Inc.

numargs = numel(varargin);
doOutliers = isequal(funName,'rmoutliers');

if doOutliers
    % Check if an outlier detection method has been specified
    input2 = varargin{1};
    offsetMethod = 0;
    if (ischar(input2) || isstring(input2))
        ind = matlab.internal.math.checkInputName(input2, ...
            {'median' 'mean' 'movmedian' 'movmean' 'percentiles' 'quartiles' 'grubbs' ...
            'gesd' 'SamplePoints' 'DataVariables' 'ThresholdFactor' 'OutlierLocations' ...
            'MinNumOutliers'});
        if sum(ind) ~= 1
            error(message('MATLAB:rmoutliers:SecondInputString'));
        end
        offsetMethod = any(ind(1:8)) + any(ind(3:5));
    end
    if offsetMethod == 0
        opts.isoutlierArgs = {'median'}; % Use the default method
    else
        % Pass the method on to isoutlier, including the invalid case of
        % isoutlier(A,movmethod)
        opts.isoutlierArgs = varargin(1:min(numargs,offsetMethod));
    end
    startNV = offsetMethod + 1;
else
    startNV = 1;
end

% Parse the DIM and N-V pairs
if numargs >= startNV
    dimIn = varargin{startNV};
    [opts,startNV] = getDim(funName,opts,startNV,dimIn,numargs,doOutliers);
    
    indNV = startNV:numargs;
    if rem(numel(indNV),2) ~= 0
        issueError(funName,'NameValuePairs');
    end
    
    if doOutliers
        minNumName = 'MinNumOutliers';
        locName = 'OutlierLocations';
    else
        minNumName = 'MinNumMissing';
        locName = 'MissingLocations';
    end
    
    extraArgs = [];
    for k = indNV(1:2:end)
        opt = varargin{k};
        if matlab.internal.math.checkInputName(opt,minNumName)
            if doOutliers && matlab.internal.math.checkInputName(opt,'m')
                % 'm' is ambiguous due to 'MinNum' and 'MaxNum'
                validatestring('m',{'MinNumOutliers', 'MaxNumOutliers'});
            end
            minNum = varargin{k+1};
            if (~isnumeric(minNum) && ~islogical(minNum)) || ...
                    ~isscalar(minNum) || ~isreal(minNum) || ...
                    fix(minNum) ~= minNum || ~(minNum >= 0)
                issueError(funName,minNumName);
            end
            opts.minNum = minNum;
        elseif matlab.internal.math.checkInputName(opt,'DataVariables')
            opts.dataVarsProvided = true;
            dataVars = varargin{k+1};
            if errorForDataVars
                if opts.AisTable
                    dataVars = matlab.internal.math.checkDataVariables(...
                        A,dataVars,funName);
                else
                    issueError(funName,'DataVariablesArray');
                end
                opts.dataVars = dataVars;
            else
                % Just collect the data variables for later validation
                opts.dataVars = {opts.dataVars{:} dataVars}; %#ok<CCAT>
            end
        elseif matlab.internal.math.checkInputName(opt,locName)
            locs = varargin{k+1};
            opts.outlierLocs = locs;
            opts.locsProvided = true;
        else
            extraArgs = [extraArgs k k+1]; %#ok<AGROW>
        end
    end

    if opts.AisTable && opts.locsProvided
        if istabular(locs)
            if doOutliers
                opts.dataVars = validateTabularLocations(A,locs,opts.dataVars,opts.dataVarsProvided,'rmoutliers',locName);
                if offsetMethod > 0
                    error(message('MATLAB:rmoutliers:MethodNotAllowed'));
                end
            else
                opts.dataVars = validateTabularLocations(A,locs,opts.dataVars,opts.dataVarsProvided,'rmmissing',locName);
            end
            if opts.dataVarsProvided
                % Must use the actual variable names because A and loc may have
                % different order of variables
                vname = string(A.Properties.VariableNames(opts.dataVars));
                opts.outlierLocs = opts.outlierLocs(:,vname);
            end
        else
            if isvector(locs) && isscalar(opts.dataVars)
                validateattributes(locs,{'logical'}, {'size', [size(A,1) numel(opts.dataVars)]}, ...
                    funName, locName);
            else
                validateattributes(locs,{'logical'}, {'size', size(A)}, ...
                    funName, locName);
            end
            if doOutliers && offsetMethod > 0
                error(message('MATLAB:rmoutliers:MethodNotAllowed'));
            end
        end
    elseif ~opts.AisTable && opts.locsProvided
        validateattributes(locs,{'logical'}, {'size', size(A)}, ...
            funName, locName);
        if doOutliers && offsetMethod > 0
            error(message('MATLAB:rmoutliers:MethodNotAllowed'));
        end
    end

    % MinNum and DataVariables apply to both rmmissing and rmoutliers,
    % while everything else is a N-V for rmoutliers and isoutlier
    if doOutliers
        opts.isoutlierArgs = [opts.isoutlierArgs varargin(extraArgs)];
    elseif ~isempty(extraArgs)
        error(message('MATLAB:rmmissing:NameValueNames'));
    end
end
end

%--------------------------------------------------------------------------
function [opts,startNV] = getDim(funName,opts,startNV,dim,nargs,doOutliers)
% If an optional DIM is specified, then it must be the second input for
% RMMISSING and a trailing input for RMOUTLIERS (same as in ISOUTLIER):
if (doOutliers || nargs > 1) && (ischar(dim) || isstring(dim))
    %   rmmissing(A,N1,V1,N2,V2,...)
    %   rmoutliers(A,N1,V1,N2,V2,...)
    %   rmoutliers(A,method,N1,V1,N2,V2,...)
    %   rmoutliers(A,movmethod,window,N1,V1,N2,V2,...)
    % startNV = startNV; % N-V pairs can be the first entry of varargin
else
    %   rmmissing(A,DIM,N1,V1,N2,V2,...)
    %   rmoutliers(A,DIM,N1,V1,N2,V2,...)
    %   rmoutliers(A,method,DIM,N1,V1,N2,V2,...)
    %   rmoutliers(A,movmethod,window,DIM,N1,V1,N2,V2,...)
    startNV = startNV+1; % N-V pairs can be the second entry of varargin
    if (isnumeric(dim) || islogical(dim)) && isreal(dim) && isscalar(dim)
        if dim == 1
            opts.byRows = true;
        elseif dim == 2
            opts.byRows = false;
        else
            issueError(funName,'DimensionInvalid');
        end
    else
        issueError(funName,'DimensionInvalid');
    end
end
end

%--------------------------------------------------------------------------
function issueError(funName,errorId)
% Issue error from the correct error message catalog
error(message(['MATLAB:', funName, ':', errorId]));
end

function datavariables = validateTabularLocations(a,loc,datavariables,dataVarsProvided,fname,nvName)
vnames = loc.Properties.VariableNames;
tnames = a.Properties.VariableNames;
if dataVarsProvided
    if ~all(ismember(tnames(datavariables),vnames))
        % DataVariable names must be present in loc table
        error(message('MATLAB:rmoutliers:InvalidLocationsWithDataVars',nvName));
    end
else
    try
        datavariables = matlab.internal.math.checkDataVariables(a, vnames, fname);
    catch
        error(message('MATLAB:rmoutliers:InvalidTabularLocationsFirstInput',nvName));
    end
end

vnames = string(vnames);
for ii=vnames
    if ~islogical(loc.(ii)) || ~isequal(size(a.(ii)),size(loc.(ii)))
         error(message('MATLAB:rmoutliers:LogicalVarsRequired',nvName));
    end
end
end