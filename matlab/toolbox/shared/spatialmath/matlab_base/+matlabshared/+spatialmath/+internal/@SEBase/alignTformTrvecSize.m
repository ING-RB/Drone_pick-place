function [tfValid,arraySize] = alignTformTrvecSize(tf, transl, rotArraySize)
%This method is for internal use only. It may be removed in the future.

%alignTformTrvecSize Align size differences between transform matrix and translation vector inputs
%   The rotArraySize describes the shape of the rotation array
%   if it was provided as an object array, e.g. so3 or
%   quaternion. If there are multiple rotations, use
%   rotArraySize to reshape the output accordingly.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    numRot = size(tf, 3);
    numTransl = size(transl, 1);

    if nargin > 2
        arraySize = rotArraySize;
    else
        % rotArraySize input not specified. Pick reasonable
        % default.
        arraySize = [1 max(numTransl,numRot)];
    end

    % Check for compatible dimensions
    if numRot == numTransl
        % No action needed. Assignment below will work.
        transValid = transl;
        tfValid = tf;
        validInput = true;
    elseif numRot > 1 && numTransl == 1
        % Expand number of translations to match rotations
        transValid = repmat(transl,[numRot,1]);
        tfValid = tf;
        validInput = true;
    elseif numRot == 1 && numTransl > 1
        % Expand number of rotations to match translations
        transValid = transl;
        tfValid = repmat(tf,[1,1,numTransl]);
        % Output array size is only dependent on number of
        % translations. This is important if user provides
        % rotArraySize as input.
        arraySize = [1 numTransl];
        validInput = true;
    else
        % Have to define transValid and tfValid here for
        % codegen.
        transValid = transl;
        tfValid = tf;
        validInput = false;
    end

    % Incompatible dimensions. Throw runtime error.
    % Use errorIf to error out at compile-time when numRot
    % and numTransl are compile-time constants. Will also
    % throw a run-time error if RuntimeChecks are on.
    coder.internal.errorIf(~validInput, "shared_spatialmath:matobj:RotTransDimMismatch", numRot, numTransl);

    % Assign translation to last column
    tfValid(1:end-1,end,:) = transValid.';

end
