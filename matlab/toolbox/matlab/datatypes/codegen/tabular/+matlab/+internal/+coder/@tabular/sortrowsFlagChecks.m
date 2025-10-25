function [processedVars,varData,processedSortMode,nvStart] = ...
    sortrowsFlagChecks(doIssortedrows,a,vars,sortMode,varargin) %#codegen
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

% Parse optional input arguments in tabular sortrows and issortedrows.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.prefer_const(doIssortedrows,vars,sortMode,varargin);

% Parse the VARS
if nargin < 3 % default is sort by all data vars, do not treat [] as "default behavior"
    processedVars = 1:a.varDim.length;
    varData = a.data;
    sortSigns = [];
    nvStart = 1;
else
    coder.internal.assert(coder.internal.isConst(vars),'MATLAB:table:sortrows:NonConstantVars');
    if isnumeric(vars)
        sortSigns = sign(vars);
        vars = abs(vars);
        % These still need to be validated.
    else
        sortSigns = [];
    end
    % The reserved name 'RowLabels' is a compatibility special case only for tables.
    if matlab.internal.coder.datatypes.isScalarText(vars) && strcmp(convertStringsToChars(vars),'RowNames') && isa(a,'table')
        processedVars = 0;
    else
        processedVars = a.getVarOrRowLabelIndices(vars,true); % allow empty row labels
    end
    varData = a.getVarOrRowLabelData(processedVars,msgidHelper(doIssortedrows,'EmptyRowNames'));
end

% Parse the DIRECTION / MODE
if nargin < 4
    %   SORTROWS(T/TT,VARS)
    tempSortMode = [];
    if nargin == 3
        nvStart = 2;
    end
else
    if rem(numel(varargin),2) == 0
        %   SORTROWS(T/TT,VARS,DIRECTION)
        %   SORTROWS(T/TT,VARS,DIRECTION,N1,V1,N2,V2,...)
        if isempty(sortMode) && ...
           (matlab.internal.coder.datatypes.isText(sortMode) || isa(sortMode,'double'))
            % Empty direction allowed because of legacy sortrows behavior
            tempSortMode = sortMode;
        else
            sortMode = convertStringsToChars(sortMode);
            if ischar(sortMode)
                sortModeCell = {sortMode};
            else
                coder.internal.assert(iscellstr(sortMode),...
                    msgidHelper(doIssortedrows,'UnrecognizedMode'));
                sortModeCell = sortMode;
            end
            
            tmp = zeros(numel(sortModeCell),1);
            tempSortMode = zeros(numel(processedVars),1);
            coder.unroll();
            for ii = 1:numel(sortModeCell)
                charFlag = sortModeCell{ii};
                if isrow(charFlag)
                    if strncmpi(charFlag,'ascend',numel(charFlag))
                        tmp(ii) = 1;
                    elseif strncmpi(charFlag,'descend',numel(charFlag))
                        tmp(ii) = 2;
                    end
                    if doIssortedrows % additional issorted directions
                        if strncmpi(charFlag,'monotonic',numel(charFlag))
                            tmp(ii) = 3;
                        elseif strncmpi(charFlag,'strictascend',max(7,numel(charFlag)))
                            tmp(ii) = 4;
                        elseif strncmpi(charFlag,'strictdescend',max(7,numel(charFlag)))
                            tmp(ii) = 5;
                        elseif strncmpi(charFlag,'strictmonotonic',max(7,numel(charFlag)))
                            tmp(ii) = 6;
                        end
                    end
                end
            end
            
            coder.internal.assert(all(tmp),...
                msgidHelper(doIssortedrows,'UnrecognizedMode'));
            
            if isscalar(tmp)
                tempSortMode(:) = tmp;
            else
                % If tmp is not scalar, then it should be the same length as
                % processedVars.
                coder.internal.assert(length(tmp) == length(processedVars),...
                msgidHelper(doIssortedrows,'WrongLengthMode'));
                tempSortMode = tmp;
            end
            
            
        end
        nvStart = 3;
    else
        %   SORTROWS(T/TT,VARS,N1,V1,N2,V2,...)
        nvStart = 2;
        tempSortMode = [];
    end
end

if isempty(tempSortMode)
    %   SORTROWS(T/TT,VARS,N1,V1,...)
    %   SORTROWS(T/TT,VARS,[],N1,V1,...)
    if isempty(sortSigns)
        processedSortMode = ones(size(processedVars));
    else
        processedSortMode = 1 + (sortSigns == -1); % 1 or 2
    end
else
    processedSortMode = tempSortMode;
end

%--------------------------------------------------------------------------
function mid = msgidHelper(doIssortedrows,errid)
if doIssortedrows
    mid = ['MATLAB:table:issortedrows:' errid];
else
    mid = ['MATLAB:table:sortrows:' errid];
end
