function [eul,eulAlt] = rotm2eul(R,seq)
%This method is for internal use only. It may be removed in the future.

%ROTM2EUL Convert rotation matrix to Euler angles
%   EUL = ROTM2EUL(R, SEQ) converts a 3D rotation matrix, R, into the corresponding
%   Euler angles, EUL. R is an 3-by-3-by-N matrix containing N rotation
%   matrices. The output, EUL, is an N-by-3 matrix of Euler rotation angles.
%   Rotation angles are in radians.
%   The Euler angles are specified by the body-fixed (intrinsic) axis rotation
%   sequence, SEQ.
%
%   [EUL, EULALT] = ROTM2EUL(___) also returns a second output, EULALT, that
%   is a different set of euler angles that represents the same rotation.
%
%   The following rotation sequences, SEQ, are supported: "ZYX", "ZYZ",
%   "XYZ", "ZXY", "ZXZ", "YXZ", "YXY", "YZX", "YZY", "XYX", "XZY", and
%   "XZX".
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%   See also rotm2eul.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

    seq = convertStringsToChars(seq);

    % Pre-allocate output
    eul = zeros(size(R,3), 3 , 'like', R); %#ok<PREALL>
    eulShaped = zeros(1, 3, size(R,3), 'like', R);

    % The parsed sequence will be in all upper-case letters and validated
    % We have this awkward switch/case statement here, so that
    % seqSettings.(seq) below is recognized as constant during code generation.
    % Replacing with "eulShaped = calculateEulerAngles(R, seq)" does not work.
    switch seq
      case 'ZYX'
        eulShaped = calculateEulerAngles(R, 'ZYX');
      case 'ZYZ'
        eulShaped = calculateEulerAngles(R, 'ZYZ');
      case 'XYZ'
        eulShaped = calculateEulerAngles(R, 'XYZ');
      case 'ZXY'
        eulShaped = calculateEulerAngles(R, 'ZXY');
      case 'ZXZ'
        eulShaped = calculateEulerAngles(R, 'ZXZ');
      case 'YXZ'
        eulShaped = calculateEulerAngles(R, 'YXZ');
      case 'YXY'
        eulShaped = calculateEulerAngles(R, 'YXY');
      case 'YZX'
        eulShaped = calculateEulerAngles(R, 'YZX');
      case 'YZY'
        eulShaped = calculateEulerAngles(R, 'YZY');
      case 'XYX'
        eulShaped = calculateEulerAngles(R, 'XYX');
      case 'XZY'
        eulShaped = calculateEulerAngles(R, 'XZY');
      case 'XZX'
        eulShaped = calculateEulerAngles(R, 'XZX');
    end

    % Shape output as a series of row vectors
    eul = reshape(eulShaped,[3, numel(eulShaped)/3]).';

    if nargout > 1
        eulAlt = robotics.core.internal.generateAlternateEulerAngles(eul, seq);
    end

end

function eul = calculateEulerAngles(R, seq)
%calculateEulerAngles Calculate Euler angles from rotation matrix
%   EUL = calculateEulerAngles(R, SEQ) calculates the Euler angles, EUL,
%   corresponding to the input rotation matrix, R. The Euler angles follow
%   the axis order specified in SEQ.

% Preallocate output
    eul = zeros(1, 3, size(R,3), 'like', R);  %#ok<PREALL>

    nextAxis = [2, 3, 1, 2];

    % Pre-populate settings for different axis orderings
    % Each setting has 4 values:
    %   1. firstAxis : The right-most axis of the rotation order. Here, X=1,
    %      Y=2, and Z=3.
    %   2. repetition : If the first axis and the last axis are equal in
    %      the sequence, then repetition = 1; otherwise repetition = 0.
    %   3. parity : Parity is 0 if the right two axes in the sequence are
    %      YX, ZY, or XZ. Otherwise, parity is 1.
    %   4. movingFrame : movingFrame = 1 if the rotations are with
    %      reference to a moving frame. Otherwise (in the case of a static
    %      frame), movingFrame = 0.
    seqSettings.ZYX = [1, 0, 0, 1];
    seqSettings.ZYZ = [3, 1, 1, 1];
    seqSettings.XYZ = [3, 0, 1, 1];

    seqSettings.ZXY = [2, 0, 1, 1];
    seqSettings.ZXZ = [3, 1, 0, 1];
    seqSettings.YXZ = [3, 0, 0, 1];

    seqSettings.YXY = [2, 1, 1, 1];
    seqSettings.YZX = [1, 0, 1, 1];
    seqSettings.YZY = [2, 1, 0, 1];

    seqSettings.XYX = [1, 1, 0, 1];
    seqSettings.XZY = [2, 0, 0, 1];
    seqSettings.XZX = [1, 1, 1, 1];

    % Retrieve the settings for a particular axis sequence
    setting = seqSettings.(seq);
    firstAxis = setting(1);
    repetition = setting(2);
    parity = setting(3);
    movingFrame = setting(4);

    % Calculate indices for accessing rotation matrix
    i = firstAxis;
    j = nextAxis(i+parity);
    k = nextAxis(i-parity+1);

    if repetition
        % Find special cases of rotation matrix values that correspond to Euler
        % angle singularities.
        sySq = R(i,j,:).*R(i,j,:) + R(i,k,:).*R(i,k,:); % sin(y)^2
        singular = sySq < 10 * eps(class(R));
        sy = sqrt(sySq);

        % Calculate Euler angles
        eul = [atan2(R(i,j,:), R(i,k,:)), atan2(sy, R(i,i,:)), atan2(R(j,i,:), -R(k,i,:))];

        % Singular matrices need special treatment (in this case, both z angles
        % cannot be uniquely determined, so just set one to zero)
        numSingular = sum(singular,3);
        assert(numSingular <= length(singular));
        if numSingular > 0
            eul(:,:,singular) = [atan2(-R(j,k,singular), R(j,j,singular)), ...
                                 atan2(sy(:,:,singular), R(i,i,singular)), zeros(1,1,numSingular,'like',R)];
        end

    else
        % Find special cases of rotation matrix values that correspond to Euler
        % angle singularities.

        cySq = R(i,i,:).*R(i,i,:) + R(j,i,:).*R(j,i,:); % cos(y)^2
        singular = cySq < 10 * eps(class(R));
        cy = sqrt(cySq);

        % Calculate Euler angles
        eul = [atan2(R(k,j,:), R(k,k,:)), atan2(-R(k,i,:), cy), atan2(R(j,i,:), R(i,i,:))];

        % Singular matrices need special treatment (in this case, x and z
        % angles cannot be uniquely determined, so just assume one is zero)
        numSingular = sum(singular,3);
        assert(numSingular <= length(singular));
        if numSingular > 0
            eul(:,:,singular) = [atan2(-R(j,k,singular), R(j,j,singular)), ...
                                 atan2(-R(k,i,singular), cy(:,:,singular)), zeros(1,1,numSingular,'like',R)];
        end
    end

    if parity
        % Invert the result
        eul = -eul;
    end

    if movingFrame
        % Swap the X and Z columns
        eul(:,[1,3],:)=eul(:,[3,1],:);
    end

end
