function [PG, shapeId, vertexId] = booleanFun(subject, clip, collinear, boolFunEnum, simplify)
%MATLAB Code Generation Library Function
% Wrapper function used in boolean operation to fill collinear value

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen
if nargin < 5
    simplify = true;
end

PG = coder.internal.polyshape();
if numel(clip) == 0 || numel(subject) == 0
    % Empty polyshape returned
    return;
else
    if collinear == 'd' || collinear == 'f'
        keepCollinear = false;
    else
        keepCollinear = true;
    end

    if collinear == 'd'
        % user didn't specify, determined by 2 input objects
        keepCollinear = (subject.KeepCollinearPoints && clip.KeepCollinearPoints);
    end

    [PG.polyImpl, shapeId, vertexId] = booleanFunDispatch(subject, clip, keepCollinear, boolFunEnum, simplify);

    PG.SimplifyState = cast(simplify,'like',PG.SimplifyState);
    PG.KeepCollinearPoints = keepCollinear;
end