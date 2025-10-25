classdef (Hidden, InferiorClasses = {?matlab.buildtool.fingerprints.Fingerprint}) FileCollectionFingerprint < matlab.buildtool.fingerprints.Fingerprint
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (GetAccess = private, SetAccess = immutable)
        Elements struct {mustHaveField(Elements,"FileHashes")} = struct("FileHashes",{})
    end

    methods (Access = ?matlab.buildtool.fingerprints.FileCollectionFingerprinter)
        function print = FileCollectionFingerprint(elements)
            print.Elements = elements;
        end
    end

    methods
        function c = changeWith(previous, current)
            arguments
                previous matlab.buildtool.fingerprints.Fingerprint {mustBeScalarOrEmpty}
                current matlab.buildtool.fingerprints.Fingerprint {mustBeScalarOrEmpty}
            end
            c = matlab.buildtool.fingerprints.FileCollectionFingerprintChange(previous, current);
        end
    end

    methods (Hidden)
        function p = paths(print)
            p = string.empty();
            for e = print.Elements(:)'
                p = [p e.FileHashes.keys()']; %#ok<AGROW>
            end
            p = denormalizePath(p);
        end

        function h = lookupHash(print, path)
            import matlab.buildtool.internal.fingerprints.HashCode;
            path = normalizePath(path);
            allHashes = dictionary(string.empty(), HashCode.empty());
            for e = print.Elements(:)'
                allHashes = allHashes.insert(e.FileHashes.keys(), e.FileHashes.values());
            end
            h = allHashes(path);
        end
    end
end

function mustHaveField(varargin)
matlab.buildtool.internal.mustHaveField(varargin{:});
end

function n = denormalizePath(p)
n = replace(p, "/", filesep());
end

function n = normalizePath(p)
n = replace(p, filesep(), "/");
end