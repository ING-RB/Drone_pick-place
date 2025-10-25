function validSeq = validateEulerSequence( seq )
%This function is for internal use only. It may be removed in the future.

%validateEulerSequence Parse an Euler sequence input
%   This function parses the input string that is given by the user and
%   resolves it to a valid Euler rotation sequence.
%
%   If your function supports the full set of 12 axis orders, use this
%   validation function, validateEulerSequence.
%   If your function only supports the 3 legacy axis orders, (ZYX, ZYZ, XYZ),
%   use this validation function, validateLegacyEulerSequence.
%
%   See also validateLegacyEulerSequence.

%   Copyright 2014-2023 The MathWorks, Inc.

%#codegen

    if nargin == 0
        % Use default rotation sequence
        validSeq = 'ZYX';
        return;
    end

    % Otherwise, validate the input rotation sequence
    validSeq = convertStringsToChars(seq);
    validateattributes(validSeq, {'char','string'}, {'nonempty'}, ...
                       'validateEulerSequence', 'seq');

    upperSeq = upper(validSeq);
    switch upperSeq
      case robotics.internal.validation.supportedEulerSequences
        validSeq = upperSeq;
        found = true;
      otherwise
        found = false;
    end

    coder.internal.errorIf(~found, 'shared_robotics:robotcore:utils:EulerSequenceNotSupported', ...
                           validSeq, strjoin(robotics.internal.validation.supportedEulerSequences, ', '));

end
