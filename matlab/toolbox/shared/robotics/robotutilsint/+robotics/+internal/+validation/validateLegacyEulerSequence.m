function validSeq = validateLegacyEulerSequence( seq )
%This function is for internal use only. It may be removed in the future.

%validateLegacyEulerSequence Parse an Euler sequence input (legacy)
%   This function parses the input string that is given by the user and
%   resolves it to a valid Euler rotation sequence. This function is
%   parsing the legacy (pre-23a) set of axis orders (ZYX, ZYZ, XYZ), not
%   all 12 orders that are started for most functions involving Euler
%   angles in 23a.
%
%   If your function only supports the 3 legacy axis orders, (ZYX, ZYZ, XYZ),
%   use this validation function, validateLegacyEulerSequence.
%   If your function supports the full set of 12 axis orders, use
%   validateEulerSequence.
%
%   See also validateEulerSequence.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    if nargin == 0
        % Use default rotation sequence
        validSeq = 'ZYX';
        return;
    end

    % Otherwise, validate the input rotation sequence
    validSeq = convertStringsToChars(seq);
    validateattributes(validSeq, {'char','string'}, {'nonempty'}, ...
                       'validateLegacyEulerSequence', 'seq');

    upperSeq = upper(validSeq);
    switch upperSeq
      case robotics.internal.validation.supportedLegacyEulerSequences
        validSeq = upperSeq;
        found = true;
      otherwise
        found = false;
    end

    coder.internal.errorIf(~found, 'shared_robotics:robotcore:utils:EulerSequenceNotSupported', ...
                           validSeq, strjoin(robotics.internal.validation.supportedLegacyEulerSequences, ', '));

end
