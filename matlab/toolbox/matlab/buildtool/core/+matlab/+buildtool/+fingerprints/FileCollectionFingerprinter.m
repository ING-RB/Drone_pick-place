classdef (Hidden) FileCollectionFingerprinter < matlab.buildtool.fingerprints.Fingerprinter
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2022-2024 The MathWorks, Inc.

    methods (Access = protected)
        function tf = supportsArray(printer, allPrinters, array) %#ok<INUSD>
            tf = isa(array, "matlab.buildtool.io.FileCollection");
        end

        function print = fingerprintArray(printer, allPrinters, array, context)
            arguments
                printer (1,1) matlab.buildtool.fingerprints.FileCollectionFingerprinter
                allPrinters matlab.buildtool.fingerprints.Fingerprinter %#ok<INUSA>
                array matlab.buildtool.io.FileCollection
                context (1,1) matlab.buildtool.fingerprints.FingerprintContext
            end

            import matlab.buildtool.fingerprints.FileCollectionFingerprint;

            elements = arrayfun(@(e)printer.fingerprintElement(e,context), array);
            elements = [elements struct("FileHashes",{})];

            print = FileCollectionFingerprint(elements);
        end
    end

    methods (Access = private)
        function print = fingerprintElement(~, collection, context)
            import matlab.internal.crypto.BasicDigester;
            import matlab.io.internal.glob;
            import matlab.buildtool.internal.fingerprints.HashCode;

            paths = relativizePath(collection.paths(), context.RootFolder);
            files = fileInfo(paths);

            folders = files(files.IsFolder, :);
            for i = 1:height(folders)
                folder = folders(i, :);
                expandedPaths = glob(fullfile(folder.Path,"**","*"), IncludeDotFiles=true);
                files = [files; fileInfo(expandedPaths)]; %#ok<AGROW>
            end

            [~,ia] = unique(files.AbsolutePath);
            files = files(ia, :);

            fileHashes = dictionary(string.empty(), HashCode.empty());

            digester = BasicDigester("Blake-2b");
            for i = 1:height(files)
                file = files(i, :);
                if file.IsFile
                    hash = digester.computeFileDigest(file.AbsolutePath);
                elseif file.IsFolder
                    hash = uint8('folder');
                else
                    hash = uint8.empty(1,0);
                end
                fileHashes(file.NormalizedPath) = hash;
            end

            print = struct();
            print.FileHashes = fileHashes;
        end
    end
end

function info = fileInfo(paths)
import matlab.buildtool.internal.io.absolutePath;
paths = paths(:);
absPaths = absolutePath(paths);
info = table(paths, normalizePath(paths), absPaths, isfile(absPaths), isfolder(absPaths), ...
    'VariableNames', ["Path", "NormalizedPath", "AbsolutePath", "IsFile", "IsFolder"]);
end

function n = normalizePath(p)
n = replace(p, filesep(), "/");
end

function r = relativizePath(paths, baseFolder)
r = matlab.buildtool.internal.io.relativePath(paths, baseFolder);

% Keep paths that have no common root with the base as-is
tf = r == "";
r(tf) = paths(tf);
end