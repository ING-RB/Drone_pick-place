function [G,GR] = grouptransform(T,groupVars,method,varargin)
%GROUPTRANSFORM Transformations by group.
%
%   Supported syntaxes for tall tables T and tall matrices X:
%
%   G = grouptransform(T,GROUPVARS,METHOD)
%   G = grouptransform(X,GROUPVARS,METHOD)
%   G = grouptransform(T,GROUPVARS,METHOD,DATAVARS)
%
%   G = grouptransform(T,GROUPVARS,GROUPBINS,METHOD)
%   G = grouptransform(X,GROUPVARS,GROUPBINS,METHOD)
%   G = grouptransform(T,GROUPVARS,GROUPBINS,METHOD,DATAVARS)
%
%   G = grouptransform(___,'IncludedEdge',LR)
%   G = grouptransform(___,'ReplaceValues',TF)
%
%   [G,GR] = grouptransform(X,___)
%
% Limitations:
% 1) If X and GROUPVARS are both tall matrices, then they must have the 
%    same number of rows.
% 2) If the first input is a tall matrix, then GROUPVARS can be a cell 
%    array containing tall grouping vectors.
% 3) The GROUPVARS and DATAVARS arguments do not support function handles.
% 4) If the METHOD argument is a function handle, then it must be a valid
%    input for tall/splitapply.
% 5) When grouping by discretized datetime arrays, the categorical group 
%    names will be different from in-memory GROUPTRANSFORM calculations.
%
%   See also GROUPTRANSFORM, TALL, FINDGROUPS, SPLITAPPLY, DISCRETIZE.

%   Copyright 2018-2023 The MathWorks, Inc.

% Check correct number of inputs
narginchk(3,inf);

% Parse inputs and error out as early as possible.
fname = mfilename;

% First input must be tall
tall.checkIsTall(upper(fname), 1, T);

% Compute matrix/table switch flag
Tcls = tall.getClass(T);
isTabular = isequal(Tcls, 'table') || isequal(Tcls, 'timetable');

if isTabular
    % Error if asking for more than 1 output for table
    nargoutchk(0,1);
    
    % Only the first input can be tall for table/timetable first input
    tall.checkNotTall(upper(fname), 1, groupVars, method, varargin{:});
    
    % Create sample of same types and run through in-memory grouptransform
    % for input validation
    sT = buildSample(T.Adaptor,'double',1);
    grouptransform(sT,groupVars,method,varargin{:});
else
    % Only first/second input can be tall for matrix case, except when the
    % second input is a cell array
    tall.checkNotTall(upper(fname), 2, method, varargin{:});
    
    if istall(groupVars)
        tall.checkIsTall(upper(fname), 2, groupVars);
        
        % Create sample of same types and run through in-memory
        % grouptransform for input validation
        sT = buildSample(T.Adaptor,'double',1);
        sgroupvars = buildSample(groupVars.Adaptor,'double',1);
        grouptransform(sT,sgroupvars,method,varargin{:});
    else
        if ~iscell(groupVars)
            error(message('MATLAB:grouptransform:SecondInputType'));
        end
        
        % Create sample of same types and run through in-memory
        % grouptransform for input validation
        sgroupvars = cell(size(groupVars));
        for k = 1:numel(groupVars)
            tall.checkIsTall(upper(fname), 2,groupVars{k});
            sgroupvars{k} = buildSample(groupVars{k}.Adaptor,'double',1);
        end
        sT = buildSample(T.Adaptor,'double',1);
        grouptransform(sT,sgroupvars,method,varargin{:});
    end
end

% Parse second input arguments for tall (grouping variables)
if isa(groupVars,'function_handle')
    error(message('MATLAB:bigdata:array:GrouptransformUnsupportedGroupVarsFcn'));
end
[groupingData,groupVars,gvLabels,T] = parseGroupVarsTall(groupVars,isTabular,'grouptransform',T);

if isTabular
    ungrouped = isempty(groupVars);
    availableVariableNames = string(subsref(T, substruct('.', 'Properties', '.', 'VariableNames')));
else
    ungrouped = false;
end

% Set default values
inclEdge = 'left';
replaceDataVars = true;

% ---------- start argument parsing ---------------

% Parse remaining inputs
gbProvided = false;
dvNotProvided = true;
indStart = 1;
    
% Parse groupbins
if matlab.internal.math.isgroupbins(method,'grouptransform')
    [groupBins,~,scalarExpandVars] = matlab.internal.math.parsegroupbins(method,numel(gvLabels),'grouptransform:Group');
    gbProvided = true;
    method = varargin{indStart};
    indStart = indStart + 1;
end
% Parse method
[method,methodprefix] = parsemethod(method);
if nargin > 2+indStart
    if isTabular
        %Parse data variables
        if (isnumeric(varargin{indStart}) || islogical(varargin{indStart}) || ...
                ((ischar(varargin{indStart}) || isstring(varargin{indStart})) && ...
                ~any(matlab.internal.math.checkInputName(varargin{indStart},{'IncludedEdge','ReplaceValues'},1))) || ...
                iscell(varargin{indStart}) || rem(nargin-(indStart+1),2) == 0)
            
            dataVars = varargin{indStart};
            
            if isa(dataVars,'function_handle')
                error(message('MATLAB:bigdata:array:GrouptransformUnsupportedDataVarsFcn'));
            end
            
            if isnumeric(dataVars) || islogical(dataVars)
                dataVars = availableVariableNames(dataVars);
            elseif ischar(dataVars) || iscellstr(dataVars) %#ok<ISCLSTR> 
                dataVars = string(dataVars);
            elseif isa(dataVars,'vartype')
                dataVars = matlab.internal.math.checkDataVariables(T.Adaptor.buildSample('double'), dataVars, 'groupsummary');
                dataVars = availableVariableNames(dataVars);
            end
            
            dataVars = unique(dataVars,'stable');
            dvNotProvided = false;
            indStart = indStart + 1;
        end
    end
end

% Parse name-value pairs
if rem(nargin-(indStart),2) == 0
    for j = indStart:2:length(varargin)
        % Other options caught by sample test above
        name = varargin{j};
        if matlab.internal.math.checkInputName(name,{'IncludedEdge'},1)
            inclEdge = varargin{j+1};
        elseif matlab.internal.math.checkInputName(name,{'ReplaceValues'},1)
            replaceDataVars = varargin{j+1};
        end
    end
end

% Keep track of which groupvars have a groupbin
gbForGV = false(size(groupingData));
if gbProvided
    % Discretize grouping variables and remove repeated pairs of grouping
    % variables and group bins
    [groupingData,groupVars,gvLabels,gbForGV] = discGroupVarTall(groupingData,groupVars,gvLabels,groupBins,inclEdge,isTabular,scalarExpandVars);
elseif isTabular
    % Remove repeated groupvars
    [groupVars,ridx] = unique(groupVars,'stable');
    groupingData = groupingData(ridx);
    gvLabels = gvLabels(ridx);
end

% Compute final number of grouping variables from labels
numGroupVars = numel(gvLabels);

if isTabular && dvNotProvided % set default
    dataVars = setdiff(availableVariableNames, groupVars,'stable');
end
% -------------- end parsing code ---------------

if ungrouped
    txnm = slicefun(@iExtractGnumAsDouble, T, tall(1));
    txnm.Adaptor = setSmallSizes(matlab.bigdata.internal.adaptors.getAdaptorForType('double'), 1);
else
    % Find groups
    tx = mgrp2idxTall(true,groupingData{:});
    
    % flag groups that are extra with tag 0
    txnm = elementfun(@flagMissingAsZero,tx);
end

if isTabular && numel(dataVars) == 0
    % Output original table with any discretized groups
    groupingData = groupingData(gbForGV);
    if gbProvided && ~isempty(groupingData)
        gvLabels = gvLabels(gbForGV);
        % Make sure all labels are unique
        uniquelabels = matlab.lang.makeUniqueStrings([availableVariableNames,gvLabels],string(sT.Properties.DimensionNames),namelengthmax);
        groupingdataT = table(groupingData{:},'VariableNames',uniquelabels(numel(availableVariableNames)+1:end));
        G = [T, groupingdataT];
    else
        if ~ungrouped
            G = elementfun(@(x,y) x,T,txnm);
            G.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(T));
        else
            G = T;
        end
    end
else
    % Extract data variables
    if isTabular
        [dvData,dataLabels,numDataVars] = extractDataVarsTall(T,isTabular,dataVars);
    else
        [dvData,dataLabels,numDataVars] = extractDataVarsTall(T,isTabular);
    end
    
    % Preallocate cell arrays
    gStats = cell(1,numDataVars);
    gStatsLabel = strings(1,numDataVars);
    
    % Compute group transformations
    for ii=1:numDataVars
        fcnErrHandler = @() handleFcnError(isTabular, dataLabels(ii));
        try
            gStats{ii} = transformbykey(dvData{ii},txnm,method,fcnErrHandler);
            gStatsLabel(ii) = methodprefix + "_" + dataLabels(ii);
            
            if ~isTabular
                gStats{ii} = tall.validateVectorOrEmpty(gStats{ii}, 'MATLAB:grouptransform:MethodOutputInvalidSize');
            end
            [gStats{ii},dvData{ii}] = validateSameTallSize(gStats{ii},dvData{ii});
        catch
            % Single error being thrown for all other possible problems above
            fcnErrHandler();
        end
    end
    % Prepare discretized groupingdata
    if (gbProvided && isTabular) || nargout>1
        if isTabular
            groupingData = groupingData(gbForGV);
            gvLabels = gvLabels(gbForGV);
        else
            % Set groups
            if numGroupVars == 1 %#ok<ISCL>
                GR = groupingData{1};
            else
                GR = groupingData;
            end
        end
    end
    
    if replaceDataVars % 'ReplaceValues' true
        if isTabular
            if gbProvided && ~isempty(groupingData)
                % Make sure all labels are unique
                uniquelabels = matlab.lang.makeUniqueStrings([availableVariableNames,gvLabels],string(sT.Properties.DimensionNames),namelengthmax);
                groupingdataT = table(groupingData{:},'VariableNames',uniquelabels(numel(availableVariableNames)+1:end));
                
                G = [T, groupingdataT];
            else
                G = T;
            end
            for jj = 1:numDataVars
                G = subsasgn(G,substruct('.',dataLabels(jj)),gStats{:,jj});
            end
        else
            % Extract G
            G = [gStats{:}];
        end
    else % 'ReplaceValues' false
        if isTabular
            if gbProvided
                % Make sure all labels are unique
                uniquelabels = matlab.lang.makeUniqueStrings([availableVariableNames,gvLabels,gStatsLabel],string(sT.Properties.DimensionNames),namelengthmax);
                groupsgstatsT = table(groupingData{:},gStats{:},'VariableNames',uniquelabels(numel(availableVariableNames)+1:end));
                G = [T, groupsgstatsT];
            else
                % Make sure all labels are unique
                uniquelabels = matlab.lang.makeUniqueStrings([availableVariableNames,gStatsLabel],string(sT.Properties.DimensionNames),namelengthmax);
                gStatsLabel = uniquelabels(numel(availableVariableNames)+1:end);
                
                G = T;
                for jj = 1:numDataVars
                    G = subsasgn(G,substruct('.',gStatsLabel(jj)),gStats{:,jj});
                end
            end
        else
            % Extract G
            G = [gStats{:}];
            G = [T,G];
        end
    end
end
end
%--------------------------------------------------------------------------
function [method,methodprefix] = parsemethod(method)
%PARSEMETHOD Assembles method into a function handle

if ischar(method)
    method = string(method);
end

% Change each option to a function handle and set names appropriately
if isstring(method)
    if strncmpi(method,"zscore",1)
        method = @(x) (x - mean(x,1,"omitnan")) ./ std(x,0,1,"omitnan");
        methodprefix = "zscore";
    elseif strncmpi(method,"norm",3)
        method = @(x) normalize(x,1,"norm",2);
        methodprefix = "norm";
    elseif strncmpi(method,"meancenter",5)
        method = @(x)  x - mean(x,1,"omitnan");
        methodprefix = "meancenter";
    elseif strncmpi(method,"rescale",1)
        method = @(x) rescale(x,0,1,"InputMin",min(x,[],1),"InputMax",max(x,[],1));
        methodprefix = "rescale";
    elseif strncmpi(method,"meanfill",5)
        method = @(x) fillmissingTallFillValue(x);
        methodprefix = "meanfill";
    else %strncmpi(method,'linearfill',1)
        method = @(x) fillmissing(x,"linear",1);
        methodprefix = "linearfill";
    end
else
    methodprefix = "fun";
end
end

%--------------------------------------------------------------------------
% Dealing with missing groups
function tout = flagMissingAsZero(tin)
tout = tin;
tout(ismissing(tin))=0;
end

%--------------------------------------------------------------------------
% Issue the correct error based on type of input
function handleFcnError(isTabular, datalabel)
if isTabular
    error(message('MATLAB:grouptransform:ApplyDataVarsError',datalabel));
else
    error(message('MATLAB:grouptransform:ApplyDataVecsError',datalabel));
end
end

%--------------------------------------------------------------------------
% 'meanfill' method - fill missing values with mean of group
function F = fillmissingTallFillValue(A)

fillValue = mean(A,1,'omitnan');

allowedArrayTypes = ...
    {'numeric', 'logical', 'categorical', ...
    'datetime', 'duration', 'calendarDuration', ...
    'string', 'char', 'cellstr'};

A = tall.validateType(A, mfilename, allowedArrayTypes, 1);

F = elementfun(@iFillMissing, A, fillValue);

% Ensure that the outputs have correct adaptors set
F.Adaptor = A.Adaptor;
end

function F = iFillMissing(A,fillValue)

F = fillmissing(A,'constant',fillValue,1);
end

%--------------------------------------------------------------------------
% Create group vector of ones in the ungrouped case
function gnum = iExtractGnumAsDouble(varargin)
sz = size(varargin{1}, 1);

gnum = varargin{end};

if size(gnum, 1) == 1
    gnum = gnum .* ones(sz, 1);
end

gnum = double(gnum);
end
