function [G,GR,GC] = groupsummary(T,groupVars,varargin) 
%GROUPSUMMARY Summary computations by group.
%
%   Supported syntaxes for tall tables T and tall matrices X:
%
%   G = groupsummary(T,GROUPVARS)
%   G = groupsummary(T,GROUPVARS,METHOD)
%   G = groupsummary(X,GROUPVARS,METHOD)
%   G = groupsummary(T,GROUPVARS,METHOD,DATAVARS);
%
%   G = groupsummary(T,GROUPVARS,GROUPBINS)
%   G = groupsummary(T,GROUPVARS,GROUPBINS,METHOD)
%   G = groupsummary(X,GROUPVARS,GROUPBINS,METHOD)
%   G = groupsummary(T,GROUPVARS,GROUPBINS,METHOD,DATAVARS);
%
%   G = groupsummary(___,'IncludeMissingGroups',TF)
%   G = groupsummary(___,'IncludedEdge',LR)
%
%   [G,GR] = groupsummary(X,___)
%   [G,GR,GC] = groupsummary(X,___)
%
% Limitations:
%  1) If X and GROUPVARS are both tall matrices, then they must have the 
%     same number of rows.
%  2) If the first input is a tall matrix, then groupvars can be a cell 
%     array containing tall grouping vectors.
%  3) The GROUPVARS and DATAVARS arguments do not support function handles.
%  4) The 'IncludeEmptyGroups' name-value pair is not supported.
%  5) The 'median', 'mode', and 'numunique' methods are not supported.
%  6) For tall datetime arrays, the 'std' method is not supported.
%  7) If the METHOD argument is a function handle, then it must be a valid
%     input for tall/splitapply. If the function handle takes multiple 
%     inputs, then the first input to GROUPSUMMARY must be a tall table.
%  8) The order of the groups might be different compared to in-memory
%     GROUPSUMMARY calculations.
%  9) When grouping by discretized datetime arrays the categorical group 
%     names will be different from in-memory GROUPSUMMARY calculations.
%
%   See also GROUPSUMMARY, TALL, FINDGROUPS, SPLITAPPLY, DISCRETIZE.

%   Copyright 2018-2024 The MathWorks, Inc.

% Check correct number of inputs
narginchk(2,inf);

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
    tall.checkNotTall(upper(fname), 1, groupVars, varargin{:});
    
    % Create sample of same types and run through in-memory groupsummary
    % for input validation
    sT = buildSample(T.Adaptor,'double',1);
    groupsummary(sT,groupVars,varargin{:});
else
    % Only first/second input can be tall for matrix case, except when the
    % second input is a cell array
    tall.checkNotTall(upper(fname), 2, varargin{:});
    
    if istall(groupVars)
        tall.checkIsTall(upper(fname), 2, groupVars);
        
        % Create sample of same types and run through in-memory groupsummary
        % for input validation
        sT = buildSample(T.Adaptor,'double',1);
        sgroupVars = buildSample(groupVars.Adaptor,'double',1);
        groupsummary(sT,sgroupVars,varargin{:});
    else
        if ~iscell(groupVars)
            error(message('MATLAB:groupsummary:SecondInputType'));
        end
        
        % Create sample of same types and run through in-memory groupsummary
        % for input validation
        sgroupVars = cell(size(groupVars));
        for k = 1:numel(groupVars)
            tall.checkIsTall(upper(fname), 2,groupVars{k});
            sgroupVars{k} = buildSample(groupVars{k}.Adaptor,'double',1);
        end
        sT = buildSample(T.Adaptor,'double',1);
        groupsummary(sT,sgroupVars,varargin{:});
    end
end

% Parse grouping variables
if isa(groupVars,'function_handle')
    error(message('MATLAB:bigdata:array:GroupsummaryUnsupportedGroupVarsFcn'));
end

[groupingData,groupVars,gvLabels,T] = parseGroupVarsTall(groupVars,isTabular,'groupsummary',T);

if isTabular
    ungrouped = isempty(groupVars);
    gcLabel = "GroupCount";
    availableVariableNames = string(subsref(T, substruct('.', 'Properties', '.', 'VariableNames')));
else
    ungrouped = false;
end

% Set default values
numMethods = 0;
numMethodInput = 1;
inclNan = true;
inclEdge = 'left';
funPresent = false;

% ---------- start argument parsing ---------------

% Parse remaining inputs
gbProvided = false;
dvNotProvided = true;
if nargin > 2
    indStart = 1;
    % Parse groupbins
    if matlab.internal.math.isgroupbins(varargin{indStart},'groupsummary')
        [groupBins,~,scalarExpandVars,flag] = matlab.internal.math.parsegroupbins(varargin{indStart},numel(gvLabels),'groupsummary:Group');
        if flag
            indStart = indStart + 1;
            gbProvided = true;
        end
    end
    if indStart < nargin-1
        % Parse method
        if matlab.internal.math.isgroupmethod(varargin{indStart})
            [methods,methodsif,methodsrf,methodprefix,numMethods,funPresent] = parseMethods(varargin{indStart});
            indStart = indStart + 1;
            if indStart < nargin-1
                if isTabular
                    %Parse data variables
                    if iscell(varargin{indStart}) && ~iscellstr(varargin{indStart})
                        % This is the case where we have a cell where each
                        % input tells you the values for one input to the
                        % function handle method
                        dataVars = varargin{indStart};
                        numMethodInput = numel(dataVars);
                        [dataVars,dvSets] = iCheckMultDataVariables(T,dataVars,availableVariableNames,numMethodInput);
                        dvNotProvided = false;
                        indStart = indStart + 1;
                    elseif(isnumeric(varargin{indStart}) || islogical(varargin{indStart}) || ...
                            ((ischar(varargin{indStart}) || isstring(varargin{indStart})) && ...
                            ~any(matlab.internal.math.checkInputName(varargin{indStart},{'IncludeEmptyGroups','IncludedEdge','IncludeMissingGroups'},8))) || ...
                            iscell(varargin{indStart}) || rem(nargin-(indStart),2) == 0)
                        % This is the case where we have 1 input to the method
                        dataVars = varargin{indStart};
                        
                        if isa(dataVars,'function_handle')
                            error(message('MATLAB:bigdata:array:GroupsummaryUnsupportedDataVarsFcn'));
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
        end
    end
    
    % Parse name-value pairs
    if rem(nargin-(1+indStart),2) == 0
        for j = indStart:2:length(varargin)
            % Other options caught by sample test above
            name = varargin{j};
            if matlab.internal.math.checkInputName(name,{'IncludeEmptyGroups'},8)
                error(message('MATLAB:bigdata:array:GroupsummaryEmptyGroups'));
            elseif matlab.internal.math.checkInputName(name,{'IncludeMissingGroups'},8)
                inclNan = varargin{j+1};
                matlab.internal.datatypes.validateLogical(inclNan,'IncludeMissingGroups');
            elseif matlab.internal.math.checkInputName(name,{'IncludedEdge'},8)
                inclEdge = varargin{j+1};
            end
        end
    end
end

if gbProvided
    % Discretize grouping variables and remove repeated pairs of grouping
    % variables and group bins
    [groupingData,groupVars,gvLabels] = discGroupVarTall(groupingData,groupVars,gvLabels,groupBins,inclEdge,isTabular,scalarExpandVars);
elseif isTabular
    % Remove repeated grouping variables
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

if ~ungrouped
    % Find groups
    tx = mgrp2idxTall(inclNan,groupingData{:});
    
    % flag groups that are extra with tag 0
    txnm = elementfun(@flagMissingAsZero,tx);
    
    if ~funPresent
        % Get groups and counts
        groups = cell(size(groupingData));
        [txnm_out,groups{:},gcount] = aggregatebykeyfun(@getGroupsAndCounts,@reduceGroupsAndCounts,txnm,groupingData{:},txnm);
        
        % Set Adaptors
        for k=1:numGroupVars
            groups{k}.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(groupingData{k}));
        end
        gcount.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(txnm));
    end
else
    % Need to create data
    groups = cell(1,0);
    gvLabels = string.empty;
    gcount = size(T,1);
end
  
if isTabular && (numMethods == 0 || numel(dataVars) == 0)
    if ~inclNan && ~ungrouped
        % Remove extra groups with tag 0
        [gcount, groups{:}] = deleteMissingGroup(txnm_out,gcount,groups{:});
    end
    
    % Make sure all labels are unique
    uniquelabels = matlab.lang.makeUniqueStrings([gvLabels,gcLabel],["Row", "Variables"],namelengthmax);
    
    % reusing deleteMissingGroups to handle empty tall tables
    if ungrouped
        [gcount] = deleteMissingGroup(gcount,gcount);
    end
    
    % Build the output tall table from tall variables.
    G = table(groups{:},gcount,'VariableNames',uniquelabels);
else
    % Extract data variables
    if isTabular
        if numMethodInput > 1
            numDataVars = numel(dataVars);
            dataLabels = dataVars;
            dvData = cell(size(dvSets));
            for i=1:numel(dvSets)
                dvData{i} = subsref(T,substruct('.',dvSets(i)));
            end
        else
            [dvData,dataLabels,numDataVars] = extractDataVarsTall(T,isTabular,dataVars);
        end
    else
        [dvData,dataLabels,numDataVars] = extractDataVarsTall(T,isTabular);
    end
    
    % Extract strong types
    StrongTypes = matlab.bigdata.internal.adaptors.getStrongTypes;
    
    % Preallocate cell arrays
    gStats = cell(1,numMethods*numDataVars);
    gStatsLabel = strings(1,numMethods*numDataVars);
    
    if (ungrouped)
        % Compute group summary computations when data is in one group      
        for jj = 1:numMethods
            for ii=1:numDataVars
                % try applying function
                try
                    switch(methodprefix(jj))
                        case {'sum', 'min', 'max'}
                            gStats{(ii-1)*numMethods + jj} = reducefun(methodsif{jj},dvData{ii});
                        case {'nummissing', 'nnz'}
                            gStats{(ii-1)*numMethods + jj} = aggregatefun(methodsif{jj},methodsrf{jj},dvData{ii});
                        case 'range'
                            mingstat = reducefun(methodsif{jj},dvData{ii});
                            maxgstat = reducefun(methodsrf{jj},dvData{ii});
                            if (ismember(tall.getClass(dvData{ii}),StrongTypes))
                                mingstat.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(dvData{ii}));
                                maxgstat.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(dvData{ii}));
                            end
                            gStats{(ii-1)*numMethods + jj} = elementfun(@(X,Y) iUnsignedRange(X,Y),maxgstat,mingstat);
                        case 'mean'
                            if (ismember(tall.getClass(dvData{ii}),{'datetime'}))
                                % Tall reduction
                                [gStats{(ii-1)*numMethods + jj}, ~] = aggregatefun( @(y) iPerBlockDatetimeMean(y, 1, 'omitnan'), @(m,n) iCombineDatetimeMeans(m, n, 'omitnan'),  dvData{ii});
                                gStats{(ii-1)*numMethods + jj}.Adaptor = dvData{ii}.Adaptor;
                                gStats{(ii-1)*numMethods + jj}.Adaptor = computeReducedSize(gStats{(ii-1)*numMethods + jj}.Adaptor, dvData{ii}.Adaptor, 1, false);
                            else
                                sumgstat = reducefun(methodsif{jj},dvData{ii});
                                bcount = aggregatefun(@(x) sum(~ismissing(x),1),@(x) sum(x,1),dvData{ii});
                                if (ismember(tall.getClass(dvData{ii}),StrongTypes))
                                    sumgstat.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(dvData{ii}));
                                end
                                gStats{(ii-1)*numMethods + jj} = elementfun(@(X,Y) X./Y,sumgstat,bcount);
                            end
                        case 'var'
                            % cannot be datetime or duration as this is caught by sample test above
                            [bcount,~,bnM2] = aggregatefun(@calculateMomentsInChunk, @reduceMoments,dvData{ii});
                            gStats{(ii-1)*numMethods + jj} = elementfun( @elemVar,bnM2,bcount);
                        case 'std'
                            if (ismember(tall.getClass(dvData{ii}),{'datetime'}))
                                error(message('MATLAB:bigdata:array:FcnNotSupportedForType','std','datetime'));
                            elseif (ismember(tall.getClass(dvData{ii}),{'duration'}))
                                tmpin = seconds(dvData{ii});
                                [bcount,~,bnM2] = aggregatefun(@calculateMomentsInChunk, @reduceMoments,tmpin);
                                tmpout = elementfun( @elemStd,bnM2,bcount);
                                gStats{(ii-1)*numMethods + jj} = duration(0,0,tmpout);
                            else
                                [bcount,~,bnM2] = aggregatefun(@calculateMomentsInChunk, @reduceMoments,dvData{ii});
                                gStats{(ii-1)*numMethods + jj} = elementfun( @elemStd,bnM2,bcount);
                            end
                        otherwise
                            % isa(methods{jj},'function_handle')
                            gStats{(ii-1)*numMethods + jj} = splitapply(methods{jj},dvData{:,ii},tall(1));
                            if ~isTabular
                                gStats{(ii-1)*numMethods + jj} = tall.validateColumn(gStats{(ii-1)*numMethods + jj}, {'MATLAB:groupsummary:ApplyDataVarsError',methodprefix(jj),dataLabels(ii)});
                            end
                    end
                    
                    % Set label
                    gStatsLabel((ii-1)*numMethods + jj) = methodprefix(jj) + "_" + dataLabels(ii);
                    
                    % If dealing with a strong type set Adaptor
                    if ismember(tall.getClass(dvData{ii}),StrongTypes)
                        % Copy adaptor information with new tall size
                        gStats{(ii-1)*numMethods + jj}.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(dvData{ii}));
                        
                        % reset small size to match the output width for nnz
                        if(ismember(methodprefix(jj), {'nnz'}))
                            gStats{(ii-1)*numMethods + jj}.Adaptor = setSmallSizes(resetSmallSizes(gStats{(ii-1)*numMethods + jj}.Adaptor), 1);
                        end
                        
                        % set type to double for nummissing and nnz
                        if(ismember(methodprefix(jj), {'nummissing', 'nnz'}))
                            gStats{(ii-1)*numMethods + jj} = setKnownType(gStats{(ii-1)*numMethods + jj}, 'double');
                        end
                        
                        % If doing range or sum on datetime output is duration so set type appropriately
                        if(ismember(methodprefix(jj), {'range'}) && ismember(tall.getClass(dvData{ii}),{'datetime'}))
                            gStats{(ii-1)*numMethods + jj} = setKnownType(gStats{(ii-1)*numMethods + jj}, 'duration');
                        end
                    end
                catch ME
                    mid = 'MATLAB:groupsummary:ApplyDataVarsError';
                    % Return error message with added information
                    m = message(mid,methodprefix(jj),dataLabels(ii));
                    throw(addCause(MException(m.Identifier,'%s',getString(m)),ME));
                end
            end
        end
    else        
        if funPresent
            % remove all missing groups from groupingData, dvData and txnm
            if ~inclNan 
                % Remove extra groups with tag 0
                [txnm, groupingData{:},dvData{:}] = deleteMissingGroup(txnm,txnm,groupingData{:},dvData{:});
            end
            
            % need to put group computation and counts throught splitapply
            gcount = splitapply(@(x) size(x,1),txnm,txnm);
            for i = 1:numel(groupingData)
                groups{i} = splitapply(@(x) topkrows(x,1),groupingData{i},txnm);
            end
            
            for jj = 1:numMethods
                for ii=1:numDataVars
                    
                    try
                        % if we have 1 function handle need to put all
                        % methods through splitapply
                        gStats{(ii-1)*numMethods + jj} = splitapply(methods{jj},dvData{:,ii},txnm);
                    catch ME
                        if isTabular
                            mid = 'MATLAB:groupsummary:ApplyDataVarsError';
                        else
                            mid = 'MATLAB:groupsummary:ApplyDataVecsError';
                        end
                        % Return error message with added information
                        m = message(mid,methodprefix(jj),dataLabels(ii));
                        throw(addCause(MException(m.Identifier,'%s',getString(m)),ME));
                    end    
                    
                    if ~isTabular
                        gStats{(ii-1)*numMethods + jj} = tall.validateColumn(gStats{(ii-1)*numMethods + jj}, {'MATLAB:groupsummary:ApplyDataVecsError',methodprefix(jj),dataLabels(ii)});
                    end
                    
                    % set label
                    gStatsLabel((ii-1)*numMethods + jj) = methodprefix(jj) + "_" + dataLabels(ii);
                end
            end
        else
            % Compute group summary computations with bykey primitives
            for jj = 1:numMethods
                for ii=1:numDataVars
                    
                    % applying function - no easy way to error
                    switch(methodprefix(jj))
                        case {'sum', 'min', 'max'}
                            [~,gStats{(ii-1)*numMethods + jj}] = reducebykeyfun(methodsif{jj},txnm,dvData{ii});
                        case {'nummissing', 'nnz'}
                            [~,gStats{(ii-1)*numMethods + jj}] = aggregatebykeyfun(methodsif{jj},methodsrf{jj},txnm,dvData{ii});
                        case 'range'
                            [~,mingstat] = reducebykeyfun(methodsif{jj},txnm,dvData{ii});
                            [~,maxgstat] = reducebykeyfun(methodsrf{jj},txnm,dvData{ii});
                            if (ismember(tall.getClass(dvData{ii}),StrongTypes))
                                mingstat.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(dvData{ii}));
                                maxgstat.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(dvData{ii}));
                            end
                            gStats{(ii-1)*numMethods + jj} = elementfun(@(X,Y) iUnsignedRange(X,Y),maxgstat,mingstat);
                        case 'mean'
                            if (ismember(tall.getClass(dvData{ii}),{'datetime'}))
                                % Tall reduction
                                [~,gStats{(ii-1)*numMethods + jj}, ~] = aggregatebykeyfun( @(y) iPerBlockDatetimeMean(y, 1, 'omitnan'), @(m,n) iCombineDatetimeMeans(m, n, 'omitnan'),txnm, dvData{ii});
                                gStats{(ii-1)*numMethods + jj}.Adaptor = dvData{ii}.Adaptor;
                                gStats{(ii-1)*numMethods + jj}.Adaptor = computeReducedSize(gStats{(ii-1)*numMethods + jj}.Adaptor, dvData{ii}.Adaptor, 1, false);
                            else
                                [~,sumgstat] = reducebykeyfun(methodsif{jj},txnm,dvData{ii});
                                [~,bcount] = aggregatebykeyfun(@(x) sum(~ismissing(x),1),@(x) sum(x,1), txnm,dvData{ii});
                                if (ismember(tall.getClass(dvData{ii}),StrongTypes))
                                    sumgstat.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(dvData{ii}));
                                end
                                gStats{(ii-1)*numMethods + jj} = elementfun(@(X,Y) X./Y,sumgstat,bcount);
                            end
                        case 'var'
                            % cannot be datetime or duration as this is caught by sample test above
                            [~,bcount,~,bnM2] = aggregatebykeyfun(@calculateMomentsInChunk, @reduceMoments,txnm,dvData{ii});
                            gStats{(ii-1)*numMethods + jj} = elementfun( @elemVar,bnM2,bcount);
                        otherwise
                            % case 'std'
                            if (ismember(tall.getClass(dvData{ii}),{'datetime'}))
                                error(message('MATLAB:bigdata:array:FcnNotSupportedForType','std','datetime'));
                            elseif (ismember(tall.getClass(dvData{ii}),{'duration'}))
                                tmpin = seconds(dvData{ii});
                                [~,bcount,~,bnM2] = aggregatebykeyfun(@calculateMomentsInChunk, @reduceMoments,txnm,tmpin);
                                tmpout = elementfun( @elemStd,bnM2,bcount);
                                gStats{(ii-1)*numMethods + jj} = duration(0,0,tmpout);
                            else
                                [~,bcount,~,bnM2] = aggregatebykeyfun(@calculateMomentsInChunk, @reduceMoments,txnm,dvData{ii});
                                gStats{(ii-1)*numMethods + jj} = elementfun( @elemStd,bnM2,bcount);
                            end
                    end
                    
                    % Set label apropriately
                    gStatsLabel((ii-1)*numMethods + jj) = methodprefix(jj) + "_" + dataLabels(ii);
                    
                    % If dealing with a strong type set Adaptor
                    if ismember(tall.getClass(dvData{ii}),StrongTypes)
                        % Copy adaptor information with new tall size
                        gStats{(ii-1)*numMethods + jj}.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(dvData{ii}));
                        
                        % reset small size to match the output width for nnz
                        if(ismember(methodprefix(jj), {'nnz'}))
                            gStats{(ii-1)*numMethods + jj}.Adaptor = setSmallSizes(resetSmallSizes(gStats{(ii-1)*numMethods + jj}.Adaptor), 1);
                        end
                        
                        % set type to double for nummissing and nnz
                        if(ismember(methodprefix(jj), {'nummissing', 'nnz'}))
                            gStats{(ii-1)*numMethods + jj} = setKnownType(gStats{(ii-1)*numMethods + jj}, 'double');
                        end
                        
                        % If doing range or sum on datetime output is duration so set type appropriately
                        if(ismember(methodprefix(jj), {'range'}) && ismember(tall.getClass(dvData{ii}),{'datetime'}))
                            gStats{(ii-1)*numMethods + jj} = setKnownType(gStats{(ii-1)*numMethods + jj}, 'duration');
                        end
                    end
                end
            end
            
            if ~inclNan
                % Remove extra groups with tag 0
                [gcount, groups{:}, gStats{:}] = deleteMissingGroup(txnm_out,gcount,groups{:},gStats{:});
            end
        end
    end
    
    if isTabular
        % Make sure all labels are unique
        uniquelabels = matlab.lang.makeUniqueStrings([gvLabels,gcLabel,gStatsLabel],["Row", "Variables"],namelengthmax);
        
        % reusing deleteMissingGroups to handle empty tall tables
        if ungrouped
            [gcount, gStats{:}] = deleteMissingGroup(gcount,gcount,gStats{:});
        end
        
        % Build the output tall table from tall variables
        G = table(groups{:},gcount,gStats{:},'VariableNames',uniquelabels);
    else
        G = [gStats{:}];
        if nargout > 1
            if numGroupVars == 1
                GR = groups{1};
            else
                GR = groups;
            end
            if nargout > 2
                GC = gcount;
            end
        end
    end
end

end

%% Tall groupsummary helpers - used for var & std
function [count_data,mean_data,nM2] = calculateMomentsInChunk(data)
count_data = sum(~isnan(data),1);              % count without NaNs
if nargout>1
    c = count_data;
    c(c==0)=1;
    mean_data = sum(data,1,'omitnan')./c;  % mean
    if nargout>2
        cdata = bsxfun(@plus,data,-mean_data); % data centering
        nM2 = sum(cdata.^2,1,'omitnan');  % second central moment times n
    end
end
end

function [count_data,mean_data,nM2] = reduceMoments(count_data,mean_data,nM2)
n = count_data;
count_data = sum(n,1);
if nargout>1
    me = mean_data;
    c = count_data;
    c(c==0)=1;
    mean_data  = sum(me.*n,1)./c;
    if nargout>2
        d = bsxfun(@plus,me,-mean_data);
        nM2 = sum( nM2 + n.*d.^2 ,1);
    end
end
end

function var = elemVar(NM2,count)
    div = max((count-1),1);
    div(count == 0) = 0;
    var = NM2./div;
end

function std = elemStd(NM2,count)
    div = max((count-1),1);
    div(count == 0) = 0;
    std = sqrt(NM2./div);
end

%% Helper In-memory modified Methods
function [methods,methodsif,methodsrf,methodprefix,nummethods,funpresent] = parseMethods(methods)
%PARSEMETHODS Assembles methods into a cell array of function handles
%   This function checks and replaces all with list of methods then changes
%   values into function handles and computes correct prefixes for the
%   methods given, it uses methods if and methodsrf to store methods needed
%   for initial and reduction functions or functions for intermediate
%   results

if isstring(methods)
    methods = num2cell(methods);
elseif ~iscell(methods)
    methods = {methods};
end
nummethods = numel(methods);

% Check for all option
isall = false(1,nummethods);
for jj = nummethods:-1:1
    if (ischar(methods{jj}) || isstring(methods{jj})) && strncmpi(methods{jj},"all",1)
        isall(jj) = true;
        firstall = jj;
    end
end
if any(isall)
    methods(isall) = [];
    allmethods = ["mean", "sum", "min", "max", "range", "var", "std", "nummissing", "nnz"];
    methods = [methods(1:firstall-1) num2cell(allmethods) methods(firstall:end)];
    nummethods = numel(methods);
end

% Change each option to a function handle and set names appropriately
funpresent = false;
methodprefix = strings(1,nummethods);
methodsif = cell(1,nummethods);
methodsrf = cell(1,nummethods);
numfun = 1;
for jj = 1:nummethods
    if ischar(methods{jj}) || isstring(methods{jj})
        if strncmpi(methods{jj},"numunique",4)
            error(message('MATLAB:bigdata:array:GroupsummaryUnsupportedMethod','numunique'));
        elseif strncmpi(methods{jj},"nummissing",4)
            methods{jj} = @(x) sum(ismissing(x),1);
            methodsif{jj} = @(x) sum(ismissing(x),1);
            methodsrf{jj} = @(x) sum(x,1);
            methodprefix(jj) = "nummissing";
        elseif strncmpi(methods{jj},"nnz",2)
            methods{jj} = @(x) nnz(x) - sum(ismissing(x),1);
            methodsif{jj} = @(x) nnz(x(~ismissing(x)));
            methodsrf{jj} = @(x) sum(x,1);
            methodprefix(jj) = "nnz";
        elseif strncmpi(methods{jj},"mean",3)
            methods{jj} = @(x) mean(x,1,"omitnan");
            methodsif{jj} = @(x) sum(x,1,"omitnan"); % needs intermediary results - sum, count
            methodsrf{jj} = {};
            methodprefix(jj) = "mean";
        elseif strncmpi(methods{jj},"median",3)
            error(message('MATLAB:bigdata:array:GroupsummaryUnsupportedMethod','median'));
        elseif strncmpi(methods{jj},"mode",3)
            error(message('MATLAB:bigdata:array:GroupsummaryUnsupportedMethod','mode'));
        elseif  strncmpi(methods{jj},"var",1)
            methods{jj} = @(x) var(x,0,1,"omitnan");
            methodsif{jj} = {}; % needs intermediary results - sum, count, mean
            methodsrf{jj} = {};
            methodprefix(jj) = "var";
        elseif  strncmpi(methods{jj},"std",2)
            methods{jj} = @(x) std(x,0,1,"omitnan");
            methodsif{jj} = {}; % needs intermediary results - sum, count, mean
            methodsrf{jj} = {};
            methodprefix(jj) = "std";
        elseif  strncmpi(methods{jj},"min",3)
            methods{jj} = @(x) min(x,[],1,"omitnan");
            methodsif{jj} = @(x) min(x,[],1,"omitnan");
            methodsrf{jj} = {}; % if/rf same
            methodprefix(jj) = "min";
        elseif strncmpi(methods{jj},"max",2)
            methods{jj} = @(x) max(x,[],1,"omitnan");
            methodsif{jj} = @(x) max(x,[],1,"omitnan");
            methodsrf{jj} = {}; %if/rf same
            methodprefix(jj) = "max";
        elseif strncmpi(methods{jj},"range",1)
            methods{jj} = @(x) max(x,[],1,"omitnan") - min(x,[],1,"omitnan");
            methodsif{jj} = @(x) min(x,[],1,"omitnan"); % needs intermediary results - max, min
            methodsrf{jj} = @(x) max(x,[],1,"omitnan");
            methodprefix(jj) = "range";
        else
            % strncmpi(methods{jj},"sum",2)
            methods{jj} = @(x) sum(x,1,"omitnan");
            methodsif{jj} = @(x) sum(x,1,"omitnan");
            methodsrf{jj} = {}; %if/rf same
            methodprefix(jj) = "sum";
        end
    else
        % isa(methods{jj},'function_handle')
        funpresent = true;
        methodprefix(jj) = "fun" + string(numfun);
        numfun = numfun + 1;
    end
end

% Remove repeated method names
[methodprefix,idx] = unique(methodprefix,"stable");
methods = methods(idx);
methodsif = methodsif(idx);
methodsrf = methodsrf(idx);
nummethods = numel(methods);

end

%% Helpers for getting group names and counts
function [varargout] = getGroupsAndCounts(varargin)
varargout = cell(size(varargin));
if isempty(varargin{1})
    varargout = varargin;
else
    for k=1:nargin-1
        z = varargin{k};
        varargout{k} = z(1,:);
    end
    varargout{nargin} = numel(varargin{nargin});
end
end

function [varargout] = reduceGroupsAndCounts(varargin)
varargout = cell(size(varargin));
if isempty(varargin{1})
    varargout = varargin;
else
    for k=1:nargin-1
        z = varargin{k};
        varargout{k} = z(1,:);
    end
    varargout{nargin} = sum(varargin{nargin},1);
end
end

%% Dealing with missing groups and empty tall tables/ timetables
function tout = flagMissingAsZero(tin)
tout = tin;
tout(ismissing(tin))=0;
end

function varargout = deleteMissingGroup(tin,varargin)
flag = logical(tin);
varargout = cell(size(varargin));
[varargout{:}] = filterslices(flag,varargin{:});
end

%% Helper methods for datetime mean
function [meanX, countX] = iPerBlockDatetimeMean(x, dim, nanFlag)
% If we have more than one row, we need to interpolate based on the number
% of controbuting elements.
meanX = mean(x, dim, nanFlag);
% we always only do 'omitnat'
countX = sum(~ismissing(x), dim);
end

function [meanX, countX] = iCombineDatetimeMeans(meanX, countX, nanFlag)
% If we have more than one row, we need to interpolate based on the number
% of controbuting elements.
import matlab.bigdata.internal.util.indexSlices;

if size(meanX,1)<=1
    return;
end

if all(countX(1,:)==countX(2:end,:), "all")
    % Special case where all blocks had the same number of elements. We
    % can just take the mean
    meanX = mean(meanX, 1, nanFlag);
    countX = sum(countX, 1);
else
    % Blocks had different number of elements. For each row in turn, work
    % out the ratio for each output element then interpolate the results.
    assert(isequal(size(meanX), size(countX)), "Expected means and counts to be same size")
    mean1 = indexSlices(meanX, 1);
    count1 = indexSlices(countX, 1);
    
    for slice = 2:size(meanX,1)
        mean2 = indexSlices(meanX, slice);
        count2 = indexSlices(countX, slice);
        ratio = count2 ./ (count2 + count1);
        
        % METHOD 1: Add scaled (duration) difference
        % newMean = mean1 + ratio.*(mean2 - mean1);
        
        % METHOD 2: Interlace the rows and use INTERP1 (which *is* supported
        % for datetime) to calculate the intermediate value between each
        % pair of elements. This is more complex than method 1, but turns
        % out to be significantly more accurate than going via duration.
        interlaced = reshape([mean1;mean2], 1, [])';
        query = ratio + ((1:numel(mean1))*2 - 1);
        newMean = interp1(1:numel(interlaced), interlaced, query);
        newMean = reshape(newMean, size(mean1));
        
        % To avoid NaN propagation, fix up values that didn't need interpolating
        newMean(ratio==0) = mean1(ratio==0);
        newMean(ratio==1) = mean2(ratio==1);
        
        % Finally, replace the original slice with the new mean
        mean1 = newMean;
        count1 = count1 + count2;
    end
    
    % The accumulated result is in mean1, count1
    meanX = mean1;
    countX = count1;
end
end

%% Helper for range
function R = iUnsignedRange(x,y)
% Compute the range and if the input is a signed integer then return range 
% as an unsigned integer value.
xClass = class(x);
if isa(x, 'integer') && strncmp('i',xClass,1)
    R = zeros(size(x),['u', class(x)]);
    for k = 1:numel(x)
        if sign(x(k)) == sign(y(k))
            R(k) = cast(x(k) - y(k), ['u', xClass]);
        else % x is always greater than y, so x > 0, y < 0
            R(k) = cast(x(k), ['u', xClass]) + cast(-y(k), ['u', xClass]);
            if y(k) == intmin(xClass)
                R(k) = R(k) + 1;
            end
        end
    end
else
    R = x - y;
end

end

%% Helper for multiple data variables
function [dataVars,dvSets] = iCheckMultDataVariables(T,dataVars,varNamesT,numMethodInput)
% iCheckMultDataVariables Validate and figure out sets of mulitple data 
% variable inputs for when the method can accept more than one input.

% Each element of dvValues contains the all the variables for one input to
% the method.  It needs to be stored as a cell since we do scalar expansion
dvValues = cell(1,numMethodInput);
for j = 1:numMethodInput
    dvValues{1,j} = checkDataVariables(T, dataVars{j}, 'groupsummary', false);
end

% Make sure that all cell elements of dataVars have the same number of
% inputs or are scalars
numDVSets = unique(cellfun(@numel,dvValues));
if numel(numDVSets) > 2 || (numel(numDVSets) == 2 && numDVSets(1) ~= 1)
    error(message('MATLAB:groupsummary:DataVariablesCellNumElements'));
end
numDVSets = max(numDVSets);

% Determine the sets of method inputs and store the sets as rows of matrix
dvSets = zeros(numDVSets,numMethodInput);
for j = 1:numMethodInput
    if isscalar(dvValues{1,j})
        dvSets(:,j) = repmat(dvValues{1,j},numDVSets,1);
    else
        dvSets(:,j) = dvValues{1,j};
    end
end

% Uniqueify the sets of method inputs 
dvSets = unique(dvSets,'rows','stable');
numDVSets = size(dvSets,1);

% Concatenate the variable names for each set of method inputs
dataVars = cell(1,numDVSets);
for j = 1:numDVSets
    dataVars{1,j} = varNamesT{dvSets(j,1)};
    for k = 2:numMethodInput
        dataVars{1,j} = [dataVars{1,j}, '_',varNamesT{dvSets(j,k)}];
    end
end

% Transpose dvSets since groupsummary wants the sets of method inputs
% stored as columns.
dvSets = dvSets';
end
