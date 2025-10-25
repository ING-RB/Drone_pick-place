function shortPath = shortenpath(navPathObj, stateValidator)
%

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    arguments
        navPathObj  (1,1) navPath % navPathObj must be a navPath object
        stateValidator (1,1) nav.StateValidator % stateValidator must be nav.StateValidator.
    end

    % validate that stateSpace object is same between input path and
    % stateValidator
    validateSameStateSpace(navPathObj, stateValidator);

    if navPathObj.NumStates > 0
        % validate that all states in input path is valid.
        validateAllPathStates(navPathObj, stateValidator);
    end

    % If path contain less than 3 states, no shortening is possible
    if navPathObj.NumStates < 3
        shortPath = navPathObj;
        return;
    end

    % shorten path using shortenpathImpl
    obj = nav.algs.internal.ShortenpathImpl(navPathObj, stateValidator);
    shortPath = shorten(obj);
end

function validateSameStateSpace(path, stateValidator)
% validateSameStateSpace If the input path's stateSpace and stateValidator's stateSpace don't
% match, then the path can't be shortened
    coder.internal.errorIf(path.StateSpace ~= stateValidator.StateSpace, ...
                           'nav:navalgs:shortenpath:RequireSameStateSpace');
end

function validateAllPathStates(path, stateValidator)
% validateAllPathStates If the input states are invalid, then the path can't be shortened

    statesValid = isStateValid(stateValidator, path.States);
    coder.internal.errorIf(~all(statesValid), ...
                           'nav:navalgs:shortenpath:StateNotValid');
end
