classdef (Hidden, Abstract) Fingerprint < matlab.mixin.Heterogeneous
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Fingerprint - Unique identifier of data array
    %
    %   The matlab.buildtool.fingerprints.Fingerprint class uniquely identifies
    %   an array of data, typically with a smaller representation such as a
    %   hash.
    %
    %   See also matlab.buildtool.fingerprints.Fingerprinter

    %   Copyright 2022-2024 The MathWorks, Inc.

    methods
        function c = changeWith(previous, current)
            arguments
                previous matlab.buildtool.fingerprints.Fingerprint {mustBeScalarOrEmpty}
                current matlab.buildtool.fingerprints.Fingerprint {mustBeScalarOrEmpty}
            end
            c = matlab.buildtool.fingerprints.FingerprintChange(previous, current);
        end
    end
end

% LocalWords:  Fingerprinter
