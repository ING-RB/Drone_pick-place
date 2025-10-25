function abstractMembers = abstractDetails(classReference)
    %abstractDetails meta.abstractDetails will be removed in a future 
    %release. Use matlab.metadata.abstractDetails instead.
    %
    % Copyright 2012-2023 The MathWorks, Inc.

    warning(message('MATLAB:class:DeprecatedFunction','meta.abstractDetails', ...
    'matlab.metadata.abstractDetails'));

    if nargout > 0
        abstractMembers = matlab.metadata.abstractDetails(classReference);
    else
        matlab.metadata.abstractDetails(classReference);
    end
end