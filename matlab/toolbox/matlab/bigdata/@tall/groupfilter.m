function [G,GR] = groupfilter(T,groupVars,method,varargin)
%GROUPFILTER Filter data by group.
%
%   Supported syntaxes for tall tables T and tall matrices X:
%
%   G = groupfilter(T,GROUPVARS,METHOD)
%   G = groupfilter(X,GROUPVARS,METHOD)
%   G = groupfilter(T,GROUPVARS,METHOD,DATAVARS)
%
%   G = groupfilter(T,GROUPVARS,GROUPBINS,METHOD)
%   G = groupfilter(X,GROUPVARS,GROUPBINS,METHOD)
%   G = groupfilter(T,GROUPVARS,GROUPBINS,METHOD,DATAVARS)
%
%   G = groupfilter(___,'IncludedEdge',LR)
%
%   [G,GR] = groupfilter(X,___)
%
% Limitations:
% 1) If X and GROUPVARS are both tall matrices, then they must have the 
%    same number of rows.
% 2) If the first input is a tall matrix, then GROUPVARS can be a cell 
%    array containing tall grouping vectors.
% 3) The GROUPVARS and DATAVARS arguments do not support function handles.
% 4) METHOD must be a valid input for tall/splitapply.
% 5) When grouping by discretized datetime arrays, the categorical group 
%    names will be different from in-memory GROUPFILTER calculations.
%
%   See also GROUPFILTER, TALL, FINDGROUPS, SPLITAPPLY, DISCRETIZE.

%   Copyright 2019-2024 The MathWorks, Inc.

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
    groupfilter(sT,groupVars,method,varargin{:});
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
        groupfilter(sT,sgroupvars,method,varargin{:});
    else
        if ~iscell(groupVars)
            error(message('MATLAB:groupfilter:SecondInputType'));
        end
        
        % Create sample of same types and run through in-memory
        % grouptransform for input validation
        sgroupvars = cell(size(groupVars));
        for k = 1:numel(groupVars)
            tall.checkIsTall(upper(fname), 2,groupVars{k});
            sgroupvars{k} = buildSample(groupVars{k}.Adaptor,'double',1);
        end
        sT = buildSample(T.Adaptor,'double',1);
        groupfilter(sT,sgroupvars,method,varargin{:});
    end
end

% Parse second input arguments for tall (grouping variables)
if isa(groupVars,'function_handle')
    error(message('MATLAB:bigdata:array:GrouptransformUnsupportedGroupVarsFcn'));
end
[groupingData,groupVars,gvLabels,T] = parseGroupVarsTall(groupVars,isTabular,'groupfilter',T);

if isTabular
    ungrouped = isempty(groupVars);
    availableVariableNames = string(subsref(T, substruct('.', 'Properties', '.', 'VariableNames')));
else
    ungrouped = false;
end

% Set default values
inclEdge = 'left';

% ---------- start argument parsing ---------------

% Parse remaining inputs
gbProvided = false;
dvNotProvided = true;
indStart = 1;
    
% Parse groupbins
if matlab.internal.math.isgroupbins(method,'groupfilter')
    [groupBins,~,scalarExpandVars] = matlab.internal.math.parsegroupbins(method,numel(gvLabels),'groupfilter:Group');
    gbProvided = true;
    method = varargin{indStart};
    indStart = indStart + 1;
end

if nargin > 2+indStart
    if isTabular
        %Parse data variables
        if (isnumeric(varargin{indStart}) || islogical(varargin{indStart}) || ...
                ((ischar(varargin{indStart}) || isstring(varargin{indStart})) && ...
                ~any(matlab.internal.math.checkInputName(varargin{indStart},{'IncludedEdge'},1))) || ...
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
    
    % Compute group transformations
    for ii=1:numDataVars
        fcnErrHandler = @() handleFcnError(isTabular, dataLabels(ii));
        try
            applyMethodFcn = @(tx) applyMethod(tx, method);
            gStats{ii} = transformbykey(dvData{ii},txnm,applyMethodFcn,fcnErrHandler);
            [gStats{ii},dvData{ii}] = validateSameTallSize(gStats{ii},dvData{ii});
            gStats{ii} = setKnownType(gStats{ii}, 'logical');
        catch
            % Single error being thrown for all other possible problems above
            fcnErrHandler();
        end
    end
    
    gStats = [gStats{:}];
    
    % Figure out which rows to filter
    filterRows = all(gStats,2);
    
    % Prepare discretized groupingdata
    if (gbProvided && isTabular) || nargout>1
        if isTabular
            groupingData = groupingData(gbForGV);
            gvLabels = gvLabels(gbForGV);
        else
            % Set groups
            if numGroupVars == 1
                GR = groupingData{1};
            else
                GR = groupingData;
            end
            
            if iscell(GR) && ~isempty(GR) && numGroupVars ~= 1
                for k = 1:numGroupVars
                    GR{1,k} = filterslices(filterRows,GR{1,k});
                end
            else
                GR = filterslices(filterRows,GR);
            end
        end
    end
    
    G = T;
    if isTabular && gbProvided && ~isempty(groupingData)
        % Make sure all labels are unique
        uniquelabels = matlab.lang.makeUniqueStrings([availableVariableNames,gvLabels],string(sT.Properties.DimensionNames),namelengthmax);
        gdataT = table(groupingData{:},'VariableNames',uniquelabels(numel(availableVariableNames)+1:end));
        G = [G, gdataT];
    end
    G = filterslices(filterRows,G);
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
    error(message('MATLAB:groupfilter:ApplyDataVarsError',datalabel));
else
    error(message('MATLAB:groupfilter:ApplyDataVecsError',datalabel));
end
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

%--------------------------------------------------------------------------
%
function y = normalizeMethodOutput(x)
if isempty(x)
    y = false(size(x,1),1);
elseif iscolumn(x)
    y = x;
else
    error(message("MATLAB:groupfilter:MethodOutputInvalidSize"));
end
end

%--------------------------------------------------------------------------
%
function tx = applyMethod(tx, method)
% Apply the user provided method and ensure the output for a group is a
% logical column vector or scalar.
tx = method(tx);
if istall(tx)
    tx = slicefun(@(x) normalizeMethodOutput(x),tx);
else
    tx = normalizeMethodOutput(tx);
end
end
