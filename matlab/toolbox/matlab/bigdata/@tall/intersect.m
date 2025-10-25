function varargout = intersect(a, b, varargin)
%INTERSECT Set intersection.
%   OUT = INTERSECT(A,B)
%   OUT = INTERSECT(A,B,'stable')
%   OUT = INTERSECT(A,B,'sorted') 
%   OUT = INTERSECT(A,B,'rows',...)
%   OUT = INTERSECT(A,B,...,'rows')
%
%   [OUT,IA,IB] = INTERSECT(...)  
%   
%   Limitations:
%   1. 'legacy' flag is not supported.
%   2. 'stable' flag is not supported when A and B are both tall.
%   3. Inputs of type 'char' are not supported when A and B are both tall.
%   4. Ordinal categorical arrays are not supported.
%
%   See also INTERSECT, TALL.

%   Copyright 2018-2023 The MathWorks, Inc.

% Validate inputs and process flags
narginchk(2,4);
nargoutchk(0,3);

% Determine whether it is A or B that is tall, and send off to the
% intersect function so that the resulting order of outputs in varargout
% corresponds correctly to A or B
adaptorA = matlab.bigdata.internal.adaptors.getAdaptor(a);
adaptorB = matlab.bigdata.internal.adaptors.getAdaptor(b);
aIsTall = istall(a);
bIsTall = istall(b);
if aIsTall && ~bIsTall
    [flags, flagInds] = iValidateInputsAndFlags(a, b, max(1, nargout), varargin{:});
    [varargout{1:max(1, nargout)}] = iIntersectTallAndSmall(a, b, flags, adaptorA.Class, bIsTall);
    % Send a as the tall variable and b as the small variable to set the adaptors
    [outAdaptor, iaAdaptor, ibAdaptor] = iSetAdaptors(adaptorA, adaptorB, flagInds);
    varargout{1}.Adaptor = outAdaptor;
    if nargout > 1
        varargout{2}.Adaptor = iaAdaptor;
        if nargout == 3
            varargout{3}.Adaptor = ibAdaptor;
        end
    end
elseif ~aIsTall && bIsTall
    [flags, flagInds] = iValidateInputsAndFlags(a, b, max(1, nargout), varargin{:});
    [varargout{1:max(1, nargout)}] = iIntersectTallAndSmall(b, a, flags, adaptorB.Class, bIsTall);
    % Send a as the small variable and b as the tall variable to set the adaptors
    [outAdaptor, iaAdaptor, ibAdaptor] = iSetAdaptors(adaptorB, adaptorA, flagInds);
    varargout{1}.Adaptor = outAdaptor;
    if nargout > 1
        varargout{2}.Adaptor = iaAdaptor;
        if nargout == 3
            varargout{3}.Adaptor = ibAdaptor;
        end
    end
else
    flags = parseSetfunInputs(a, b, adaptorA, max(1, nargout), mfilename, varargin{:});
    
    % Use common implementation in setfunCommon to get the set of unique
    % elements in A and B.
    [tOut, isRowVector] = setfunCommon(a, b, adaptorA, adaptorB, max(1, nargout), mfilename, flags);
    
    % Extract data from the common implementation of set functions and find
    % the intersection of A and B. Intersect returns data common to both A
    % and B.
    conditionFcn = @(ia, ib) ia > 0 & ib > 0;
    [varargout{1:max(1, nargout)}] = extractSetfunResult(tOut, conditionFcn);
        
    % Transpose first output if both inputs A and B are row vectors
    varargout{1} = changeSetfunRowVector(varargout{1}, isRowVector);
    
    % Update adaptor for c
    adaptorA = resetSizeInformation(adaptorA);
    adaptorB = resetSizeInformation(adaptorB);
    varargout{1}.Adaptor = matlab.bigdata.internal.adaptors.combineAdaptors(1, {adaptorA, adaptorB});
end
end

function [flagsOut, flagInds] = iValidateInputsAndFlags( a, b, numArgsOut, varargin )
% The flags in varargin are found and their indices noted.
% Then, validateSyntax is called to check for any invalid flags or other 
% invalid inputs that would throw errors in the in-memory function. The
% flags and the flag indices are returned to the main function. The
% possible flags out are "rows", "stable", "sorted" and "r2012a".

% Flags must not be tall
tall.checkNotTall(upper(mfilename), 2, varargin{:});
% Find flags and note the index where it was found in varargin
flagVals = ["rows" "sorted" "stable" "legacy" "r2012a"];
nFlagVals = numel(flagVals);
flagInds = zeros(1,nFlagVals);
for ii = 1:numel(varargin(:))
    flag = lower(string(varargin{ii}));
    
    foundFlag = startsWith(flagVals, flag, 'IgnoreCase', true);
    if sum(foundFlag) ~= 1
        break;
    end
    flagInds(foundFlag) = ii;
end
% 'legacy' flag is not supported for tall/intersect
if flagInds (4)
    error(message('MATLAB:bigdata:array:SetFcnLegacyNotSupported'));
end

% tall.validateSyntax will throw the same errors as the in-memory
% intersect function. The error messages thrown for unknown input or 
% unknown flag are different for tall/intersect because the 'legacy' flag
% is not supported, and so is not listed as a valid flag.
try
    tall.validateSyntax(@intersect, {a, b, varargin{:}}, ...
        'DefaultType', 'double', 'InputGroups', [1 1], 'NumOutputs', numArgsOut); %#ok<CCAT>
catch E
    if E.identifier == "MATLAB:INTERSECT:UnknownInput"
        error(message('MATLAB:bigdata:array:IntersectUnknownInput'));
    elseif E.identifier == "MATLAB:INTERSECT:UnknownFlag"
        error(message('MATLAB:bigdata:array:IntersectUnknownFlag', flag));
    else
        rethrow(E);
    end
end

% The possible flags out are "rows", "stable", "sorted" and "r2012a".
flagsOut = cellstr(flagVals(flagInds>0));
end

function varargout = iIntersectTallAndSmall( tallVar, smallVar, flags, classTallVar, bIsTall)
% The tall and the small variables are sent to the correct primitive function 
% based on how many outputs are requested, and the outputs of the
% intersect of the tall variable and the small variable are returned.

hasStringInput = (classTallVar == "string") || isstring(smallVar);
isStable = ismember("stable", flags);

if nargout<=1 && ~hasStringInput && ~isStable
    % For all one-output cases (unless the inputs are strings or 'stable' 
    % is specified), the size of the tall variable and the absolute slice 
    % indices are not required. Thus, we can use reducefun and decrease 
    % the number of passes required.
    varargout{1} = reducefun(@(x) intersect(x, smallVar, flags{:}), tallVar);
    
else
    % 'stable' returns the intersection of A and B, keeping the same order
    % of appearance. This requires the use of absolute slice indices to
    % return the output in the appropriate order. Strings are a special 
    % case that require the size of the tall variable in order to be 
    % formatted properly. Thus, both cases are sent here regardless of
    % number of outputs requested.
    
    % In the first step of the aggregatefun, we intersect each block with 
    % the small input, whilst also tracking the indices. In the second
    % step, the results of each block are combined using unique.
    indSmallRequired = ( nargout == 3 || bIsTall );
    isStableAndBIsTall = isStable && bIsTall;
    sliceIds = getAbsoluteSliceIndices(tallVar);
    processFcn = @(x, ids, sz) iProcessChunks(x, smallVar, ids, sz, flags, indSmallRequired, isStableAndBIsTall);
    combineFcn =  @(out,indTall,indSmall) iCombineChunks(out, indTall, indSmall, flags, indSmallRequired, isStableAndBIsTall);
    
    [varargout{1},ia,ib] = aggregatefun(processFcn, combineFcn, tallVar, sliceIds,...
        matlab.bigdata.internal.broadcast(size(tallVar)));
    
    if nargout > 1
        % If B is tall, varargout{2} will correspond to IB and varargout{3}
        % will correspond to IA
        if bIsTall
            optionalOutputs = {ib, ia};
        else
            optionalOutputs = {ia, ib};
        end
        varargout(2:nargout) = optionalOutputs(1:nargout-1);
    end
end

end

function [out, indTall, indSmall, flags, indSmallRequired, isStableAndBIsTall] ...
    = iProcessChunks(localT, smallVar, sliceIds, globalSz, flags, indSmallRequired, isStableAndBIsTall)
% The intersection between the small variable and the chunk of the tall
% variable is found, and then the indices of the chunk elements are
% mapped to the tall variable using the absolute slice indices and the 
% overall size of the tall variable.

if ~isStableAndBIsTall
    [out, indTall, indSmall] = intersect(localT, smallVar, flags{:});
else
    % If b is tall and flags contains 'stable', we need to keep the same
    % order of appearance according to the small variable a.
    [out, indSmall, indTall] = intersect(smallVar, localT, flags{:});
end

if ~isempty(indTall)
    indTall = iMapToAbsoluteIndices(indTall, localT, sliceIds, globalSz);
end

% With strings, need to make sure that all the chunks have the right sizes
% to be able to be concatenated together
if isstring(out) && ~isempty(globalSz)
    if ~(isrow(smallVar) && globalSz(1)==1) && (~iscolumn(out) && ~( isempty(out) && size(out,2) > 1 ))
            out = out.';
    end
end
end

function [chunkOut, outIndTall, outIndSmall, flags, indSmallRequired, isStableAndBIsTall] ...
    = iCombineChunks(chunkIn, indTall, indSmall, flags, indSmallRequired, isStableAndBIsTall)
% To ensure that the combined chunks have the correct elements and indices, 
% first indTall is sorted from lowest to highest and the 
% corresponding elements of chunkIn and indSmall are put in that same
% order. Then unique(chunkIn) is called to remove the repeated elements.
% Since indTall was sorted, the unique elements left in the chunk will be 
% the ones with the lowest tall index.

isRowsMode = ismember("rows", flags);
isStableMode = ismember("stable", flags);

% No combination needed if there is an empty chunkIn, unless we are in
% 'rows' mode.
if ~isempty(chunkIn) || (isRowsMode && isempty(chunkIn))
    if ~isStableAndBIsTall
        % Sort indTall, swapping the indices of the corresponding
        % chunkIn and indSmall elements as well
        [indTall, indx] = sort(indTall);
        if indSmallRequired
            indSmall = indSmall(indx);
        end
    else
        % Stable order is based on the first variable. In this case it is
        % the small variable but we should take the first appearance in the
        % tall variable
        [~, indx] = sortrows([indSmall indTall]);
        indSmall = indSmall(indx);
        indTall = indTall(indx);
    end
    
    if isRowsMode || istable(chunkIn) || istimetable(chunkIn)
        chunkIn = chunkIn(indx,:);
    else
        chunkIn = chunkIn(indx);
    end
    
    % Now we remove the repeated elements
    [chunkIn, indx] = unique(chunkIn, flags{:});
    if ~isempty(indTall)
        indTall = indTall(indx);
        if indSmallRequired
            indSmall = indSmall(indx);
        end
    end
end

if ~isStableMode
    % chunkIn comes back unsorted. We use intersect to put the elements
    % back in sorted order because sort and sortrows don't support tables with 
    % NDarrays as variables
    [chunkIn, indx] = intersect(chunkIn, chunkIn, flags{:});
    if ~isempty(indx) && ~isempty(indTall)
        indTall = indTall(indx);
        if indSmallRequired
            indSmall = indSmall(indx);
        end
    end
end

chunkOut = chunkIn;
outIndTall = indTall;
outIndSmall = indSmall;

end


function outIndT = iMapToAbsoluteIndices(indT, localT, sliceIds, globalSz)
% The local indices are mapped to absolute indices using the absolute slice
% indices and the overall size of the tall variable.

    isRowLocalT = (size(localT, 1) == 1);    
    if any(indT(:)>size(localT,1))
        % Need to account for the overall height of localT if it is not a
        % column vector
        [localRow,localCol] = ind2sub(size(localT),indT);
        isSliceIdsInitialized = (length(sliceIds)==length(indT));
        if ~isRowLocalT || isSliceIdsInitialized
            localRow = sliceIds(localRow);
        else
            % sliceIds is a scalar value
            localRow(1:end) = sliceIds;
        end
        outIndT = sub2ind(globalSz, localRow, localCol);
    else
        if ~isRowLocalT
            outIndT = sliceIds(indT);
        else
            % Here, outIndT is simply the absolute slice index
            outIndT = sliceIds;
        end
    end
end

function [outAdaptor, iaAdaptor, ibAdaptor] = iSetAdaptors( tallAdaptor, smallAdaptor, flagInds)
% Sets adaptors.

% With intersect, the tall size cannot be predicted in any case.
isTabularMode = (smallAdaptor.Class == "table" || smallAdaptor.Class == "timetable");
if  isTabularMode
    % If A and B are tabular, the output will always be tabular and have
    % the same small size as A and B.
    tallAdaptor = resetTallSize(tallAdaptor);
    outAdaptor = tallAdaptor;
else
    classOfSmallVar = smallAdaptor.Class;
    if flagInds(1) && classOfSmallVar ~= "char"
        % With 'rows' mode, the small sizes are the same as A (in the
        % case of 'char', the small size cannot be predicted).
        tallAdaptor = resetTallSize(tallAdaptor);
    else
        % In these cases, it is impossible to predict what the small sizes
        % will be due to possible nxn NaN matrices and empty row vectors
        tallAdaptor = resetSizeInformation(tallAdaptor);
    end
    % The output usually has the class of the tall variable.
    % If the class of the small variable is not double or logical, the output
    % has the class of the small variable.
    %
    % If the class of the tall variable is a string, the class of the output
    % will always be a string and the above statement can be ignored.
    
    if  classOfSmallVar == "double" || classOfSmallVar == "logical" || tallAdaptor.Class == "string"
        outAdaptor = tallAdaptor;
    else
        updatedAdaptor = matlab.bigdata.internal.adaptors.getAdaptorForType(classOfSmallVar);
        updatedAdaptor = copyTallSize(updatedAdaptor, tallAdaptor);
        outAdaptor = updatedAdaptor;
    end
end

if nargout>1
    % The indices IA and IB are always column vectors of class 'double'
    idxAdaptor = matlab.bigdata.internal.adaptors.getAdaptorForType('double');
    idxAdaptor = setSmallSizes(idxAdaptor, 1);
    iaAdaptor = idxAdaptor;
    if nargout == 3
        ibAdaptor = idxAdaptor;
    end
end
end
