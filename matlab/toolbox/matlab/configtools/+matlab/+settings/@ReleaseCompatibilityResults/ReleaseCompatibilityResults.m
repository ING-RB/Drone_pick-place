classdef ReleaseCompatibilityResults
    % ReleaseCompatibilityResults is the top-level
    % class that stores the results of upgrading the
    % personal settings of a toolbox.
    % Upgrading the personal settings of a toolbox
    % is required if the settings for the current toolbox
    % differ from the settings for the previous toolbox.

    %   Copyright 2019 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = immutable)
        % Version of the toolbox that personal settings
        % were upgraded to.
        VersionLabel(1,1) string
        % Result type: user settings upgrade results or 
        % name dependency model results
        ResultType(1,1) string
        % Log of pre-validation exceptions for the 
        % upgraded personal settings
        PreValidationExceptions matlab.settings.ReleaseCompatibilityException
        % Results of the upgrade for each toolbox version
        Results matlab.settings.VersionResults
    end
end
