function [direction, criterion, refPoint] = checkSortInput(varargin)

% Copyright 2023 The MathWorks, Inc.

%#codegen

direction = 'a';
criterion = 'a';
refPoint = [0 0];
if(isempty(varargin))
    return;
end

% Track whether each option has been set already
setDirection = false;
setCriterion = false;

directionOptions = {'ascend', 'descend'};
criterionOptions = {'numsides', 'area', 'perimeter', 'centroid'};

nvPairIndex = 3; % Index into varargin at which Name-Value pairs start
coder.unroll()
for i=1:min(2, nargin)
    coder.internal.assert(coder.internal.isConst(varargin{i}), ...
        'Coder:toolbox:OptionInputsMustBeConstant','sortboundaries');
    coder.internal.assert(coder.internal.isTextRow(varargin{i}),  ...
        'MATLAB:polyshape:sortParameter');

    cmpLen = strlength(varargin{i});

    isDirectionMatch = false;
    isCriterionMatch = false;
    
    coder.unroll()
    for ii = 1:numel(directionOptions)
        if strncmpi(varargin{i}, directionOptions{ii}, cmpLen)
            coder.internal.errorIf(setDirection, 'MATLAB:polyshape:sortDirection');
            isDirectionMatch = true;
            direction = directionOptions{ii}(1);
            setDirection = true;
            break;
        end
    end

    coder.unroll()
    for ii = 1:numel(criterionOptions)
        if strncmpi(varargin{i}, criterionOptions{ii}, cmpLen)
            coder.internal.errorIf(isDirectionMatch, 'MATLAB:polyshape:sortParameter');
            coder.internal.errorIf(setCriterion, 'MATLAB:polyshape:sortCriterion');
            isCriterionMatch = true;
            criterion = criterionOptions{ii}(1);
            setCriterion = true;
            break;
        end
    end

    % Check if input is reference point
    if ~(isDirectionMatch || isCriterionMatch) && strncmpi(varargin{i}, 'ReferencePoint', cmpLen)
        nvPairIndex = i;
        break;
    end

    % More than one flag matches, ambiguous choice
    coder.internal.errorIf(~(isDirectionMatch || isCriterionMatch), 'MATLAB:polyshape:sortParameter')
end

coder.unroll()
for i=nvPairIndex:2:nargin
    coder.internal.assert(coder.internal.isConst(varargin{i}), ...
        'Coder:toolbox:OptionInputsMustBeConstant','sortboundaries');
    coder.internal.assert(coder.internal.isTextRow(varargin{i}),  ...
        'MATLAB:polyshape:sortReferenceName');

    coder.internal.errorIf(i+1>nargin, 'MATLAB:polyshape:nameValuePairError');
    
    coder.internal.errorIf(criterion~='c', 'MATLAB:polyshape:sortReference')
    
    % Check value
    param.allow_inf = false;
    param.allow_nan = false;
    param.one_point_only = true;
    param.errorOneInput = 'MATLAB:polyshape:sortRefPoint';
    param.errorTwoInput = 'MATLAB:polyshape:sortRefPoint';
    param.errorValue = 'MATLAB:polyshape:sortRefPointValue';
    [X, Y] = coder.internal.polyshape.checkPointArray(param, varargin{i+1});
    refPoint = [X Y];
end