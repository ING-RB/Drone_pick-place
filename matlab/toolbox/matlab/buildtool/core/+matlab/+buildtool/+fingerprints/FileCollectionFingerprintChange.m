classdef (Hidden) FileCollectionFingerprintChange < matlab.buildtool.fingerprints.FingerprintChange
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2024 The MathWorks, Inc.

    properties (GetAccess = private, SetAccess = private)
        AddedPaths (1,:) string = missing()
        RemovedPaths (1,:) string = missing()
        CreatedFiles (1,:) string = missing()
        DeletedFiles (1,:) string = missing()
        ModifiedFiles (1,:) string = missing()
    end

    properties (Constant, GetAccess = private)
        FileCollectionFingerprintClass = "matlab.buildtool.fingerprints.FileCollectionFingerprint"
        EmptyHash = matlab.buildtool.internal.fingerprints.HashCode()
    end

    methods
        function change = FileCollectionFingerprintChange(previousFingerprint, currentFingerprint)
            arguments
                previousFingerprint matlab.buildtool.fingerprints.Fingerprint {mustBeScalarOrEmpty}
                currentFingerprint matlab.buildtool.fingerprints.Fingerprint {atLeastOneMustBeFileCollectionFingerprint(previousFingerprint,currentFingerprint)}
            end
            change@matlab.buildtool.fingerprints.FingerprintChange(previousFingerprint, currentFingerprint);
        end

        function p = addedPaths(changes)
            % addedPaths - Paths added since previous fingerprint
            %
            %   PATHS = addedPaths(CHANGES) returns paths added to the current
            %   fingerprint since the previous fingerprint. If the previous fingerprint
            %   is empty, then the method returns all paths in the current fingerprint.
            %
            %   Example:
            %
            %      import matlab.buildtool.io.File
            %      import matlab.buildtool.fingerprints.FileCollectionFingerprinter
            %      import matlab.buildtool.fingerprints.FileCollectionFingerprintChange
            %
            %      printer = FileCollectionFingerprinter;
            %
            %      prevPrint = printer.fingerprint(File(["a","b"]));
            %      currPrint = printer.fingerprint(File(["a","b","c","d"]));
            %
            %      change = FileCollectionFingerprintChange(prevPrint,currPrint);
            %      added = change.addedPaths;  % Returns ["c","d"]

            arguments
                changes matlab.buildtool.fingerprints.FileCollectionFingerprintChange                
            end
            p = string.empty(1,0);
            for c = changes(:)'
                p = [p c.elementAddedPaths()]; %#ok<AGROW>
            end
            p = unique(p);
        end

        function p = removedPaths(changes)
            % removedPaths - Paths removed since previous fingerprint
            %
            %   PATHS = removedPaths(CHANGES) returns paths removed from the current
            %   fingerprint since the previous fingerprint. If the previous fingerprint
            %   is empty, then the method returns no paths.
            %
            %   Example:
            %
            %      import matlab.buildtool.io.File
            %      import matlab.buildtool.fingerprints.FileCollectionFingerprinter
            %      import matlab.buildtool.fingerprints.FileCollectionFingerprintChange
            %
            %      printer = FileCollectionFingerprinter;
            %
            %      prevPrint = printer.fingerprint(File(["a","b","c","d"]));
            %      currPrint = printer.fingerprint(File(["a","b"]));
            %
            %      change = FileCollectionFingerprintChange(prevPrint,currPrint);
            %      removed = change.removedPaths;  % Returns ["c","d"]

            arguments
                changes matlab.buildtool.fingerprints.FileCollectionFingerprintChange                
            end
            p = string.empty(1,0);
            for c = changes(:)'
                p = [p c.elementRemovedPaths()]; %#ok<AGROW>
            end
            p = unique(p);
        end

        function f = createdFiles(changes)
            % createdFiles - Files created since previous fingerprint
            %
            %   FILES = createdFiles(CHANGES) returns paths to the files created on
            %   disk since the previous fingerprint. If the previous fingerprint is
            %   empty, then the method returns no paths.
            %
            %   Example:
            %
            %      import matlab.buildtool.io.File
            %      import matlab.buildtool.fingerprints.FileCollectionFingerprinter
            %      import matlab.buildtool.fingerprints.FileCollectionFingerprintChange
            %
            %      printer = FileCollectionFingerprinter;
            %
            %      prevPrint = printer.fingerprint(File(["a","b","c","d"]));
            %
            %      writelines("","c");
            %      writelines("","d");
            %      currPrint = printer.fingerprint(File(["a","b","c","d"]));
            %
            %      change = FileCollectionFingerprintChange(prevPrint,currPrint);
            %      created = change.createdFiles;  % Returns ["c","d"]

            arguments
                changes matlab.buildtool.fingerprints.FileCollectionFingerprintChange                
            end
            f = string.empty(1,0);
            for c = changes(:)'
                f = [f c.elementCreatedFiles()]; %#ok<AGROW>
            end
            f = unique(f);
        end

        function f = deletedFiles(changes)
            % deletedFiles - Files deleted since previous fingerprint
            %
            %   FILES = deletedFiles(CHANGES) returns paths to the files deleted on
            %   disk since the previous fingerprint. If the previous fingerprint is
            %   empty, then the method returns no paths.
            %
            %   Example:
            %
            %      import matlab.buildtool.io.File
            %      import matlab.buildtool.fingerprints.FileCollectionFingerprinter
            %      import matlab.buildtool.fingerprints.FileCollectionFingerprintChange
            %
            %      printer = FileCollectionFingerprinter;
            %
            %      writelines("","c");
            %      writelines("","d");
            %      prevPrint = printer.fingerprint(File(["a","b","c","d"]));
            %
            %      delete("c");
            %      delete("d");
            %      currPrint = printer.fingerprint(File(["a","b","c","d"]));
            %
            %      change = FileCollectionFingerprintChange(prevPrint,currPrint);
            %      deleted = change.deletedFiles;  % Returns ["c","d"]

            arguments
                changes matlab.buildtool.fingerprints.FileCollectionFingerprintChange
            end
            f = string.empty(1,0);
            for c = changes(:)'
                f = [f c.elementDeletedFiles()]; %#ok<AGROW>
            end
            f = unique(f);
        end

        function f = modifiedFiles(changes)
            % modifiedFiles - Files modified since previous fingerprint
            %
            %   FILES = modifiedFiles(CHANGES) returns paths to the files modified on
            %   disk since the previous fingerprint. If the previous fingerprint is
            %   empty, then the method returns no paths.
            %
            %   Example:
            %
            %      import matlab.buildtool.io.File
            %      import matlab.buildtool.fingerprints.FileCollectionFingerprinter
            %      import matlab.buildtool.fingerprints.FileCollectionFingerprintChange
            %
            %      printer = FileCollectionFingerprinter;
            %
            %      writelines("original content","c");
            %      writelines("original content","d");
            %      prevPrint = printer.fingerprint(File(["a","b","c","d"]));
            %
            %      writelines("modified content","c");
            %      writelines("modified content","d");
            %      currPrint = printer.fingerprint(File(["a","b","c","d"]));
            %
            %      change = FileCollectionFingerprintChange(prevPrint,currPrint);
            %      modified = change.modifiedFiles;  % Returns ["c","d"]

            arguments
                changes matlab.buildtool.fingerprints.FileCollectionFingerprintChange
            end
            f = string.empty(1,0);
            for c = changes(:)'
                f = [f c.elementModifiedFiles()]; %#ok<AGROW>
            end
            f = unique(f);
        end
    end

    methods (Access = private)
        function p = elementAddedPaths(change)
            arguments
                change (1,1) matlab.buildtool.fingerprints.FileCollectionFingerprintChange
            end
            if isempty(change.PreviousFingerprint) || ~isa(change.PreviousFingerprint, change.FileCollectionFingerprintClass)
                p = change.CurrentFingerprint.paths();
                return;
            end
            if isempty(change.CurrentFingerprint) || ~isa(change.CurrentFingerprint, change.FileCollectionFingerprintClass)
                p = string.empty(1,0);
                return;
            end
            if anymissing(change.AddedPaths)
                previousPaths = change.PreviousFingerprint.paths();
                currentPaths = change.CurrentFingerprint.paths();
                change.AddedPaths = setdiff(currentPaths, previousPaths);
            end
            p = change.AddedPaths;
        end

        function p = elementRemovedPaths(change)
            arguments
                change (1,1) matlab.buildtool.fingerprints.FileCollectionFingerprintChange
            end
            if isempty(change.PreviousFingerprint) || ~isa(change.PreviousFingerprint, change.FileCollectionFingerprintClass)
                p = string.empty(1,0);
                return;
            end
            if isempty(change.CurrentFingerprint) || ~isa(change.CurrentFingerprint, change.FileCollectionFingerprintClass)
                p = change.PreviousFingerprint.paths();
                return;
            end
            if anymissing(change.RemovedPaths)
                previousPaths = change.PreviousFingerprint.paths();
                currentPaths = change.CurrentFingerprint.paths();
                change.RemovedPaths = setdiff(previousPaths, currentPaths);
            end
            p = change.RemovedPaths;
        end

        function f = elementCreatedFiles(change)
            arguments
                change (1,1) matlab.buildtool.fingerprints.FileCollectionFingerprintChange
            end
            if isempty(change.PreviousFingerprint) || ~isa(change.PreviousFingerprint, change.FileCollectionFingerprintClass) ... 
                    || isempty(change.CurrentFingerprint) || ~isa(change.CurrentFingerprint, change.FileCollectionFingerprintClass)
                f = string.empty(1,0);
                return;
            end
            if anymissing(change.CreatedFiles)
                previousPaths = change.PreviousFingerprint.paths();
                currentPaths = change.CurrentFingerprint.paths();
                commonPaths = intersect(currentPaths, previousPaths);

                previousHashes = change.PreviousFingerprint.lookupHash(commonPaths);
                currentHashes = change.CurrentFingerprint.lookupHash(commonPaths);

                change.CreatedFiles = commonPaths( ...
                    previousHashes == change.EmptyHash & ...
                    currentHashes ~= change.EmptyHash);
            end
            f = change.CreatedFiles;
        end

        function f = elementDeletedFiles(change)
            arguments
                change (1,1) matlab.buildtool.fingerprints.FileCollectionFingerprintChange
            end
            if isempty(change.PreviousFingerprint) || ~isa(change.PreviousFingerprint, change.FileCollectionFingerprintClass) ...
                    || isempty(change.CurrentFingerprint) || ~isa(change.CurrentFingerprint, change.FileCollectionFingerprintClass)
                f = string.empty(1,0);
                return;
            end
            if anymissing(change.DeletedFiles)
                previousPaths = change.PreviousFingerprint.paths();
                currentPaths = change.CurrentFingerprint.paths();
                commonPaths = intersect(currentPaths, previousPaths);

                previousHashes = change.PreviousFingerprint.lookupHash(commonPaths);
                currentHashes = change.CurrentFingerprint.lookupHash(commonPaths);

                change.DeletedFiles = commonPaths( ...
                    previousHashes ~= change.EmptyHash & ...
                    currentHashes == change.EmptyHash);
            end
            f = change.DeletedFiles;
        end

        function f = elementModifiedFiles(change)
            arguments
                change (1,1) matlab.buildtool.fingerprints.FileCollectionFingerprintChange
            end
            if isempty(change.PreviousFingerprint) || ~isa(change.PreviousFingerprint, change.FileCollectionFingerprintClass) ...
                    || isempty(change.CurrentFingerprint) || ~isa(change.CurrentFingerprint, change.FileCollectionFingerprintClass)
                f = string.empty(1,0);
                return;
            end
            if anymissing(change.ModifiedFiles)
                previousPaths = change.PreviousFingerprint.paths();
                currentPaths = change.CurrentFingerprint.paths();
                commonPaths = intersect(currentPaths, previousPaths);
                
                previousHashes = change.PreviousFingerprint.lookupHash(commonPaths);
                currentHashes = change.CurrentFingerprint.lookupHash(commonPaths);
                
                change.ModifiedFiles = commonPaths( ...
                    previousHashes ~= currentHashes & ...
                    previousHashes ~= change.EmptyHash & ...
                    currentHashes ~= change.EmptyHash);
            end
            f = change.ModifiedFiles;
        end
    end

    methods (Access = {?matlab.buildtool.fingerprints.FingerprintChange, ?matlab.buildtool.diagnostics.TaskChangeDiagnostic})
        function conds = conditions(change)
            import matlab.automation.diagnostics.StringDiagnostic;

            conds = StringDiagnostic.empty(1,0);

            if ~change.isChanged()
                return;
            end

            addedPaths = change.addedPaths();
            if ~isempty(addedPaths)
                label = string(message("MATLAB:buildtool:FileCollectionFingerprintChange:PathsAddedLabel"));
                conds(end+1) = StringDiagnostic(sprintf("%s '%s'", label, strjoin(addedPaths, "', '")));
            end

            removedPaths = change.removedPaths();
            if ~isempty(removedPaths)
                label = string(message("MATLAB:buildtool:FileCollectionFingerprintChange:PathsRemovedLabel"));
                conds(end+1) = StringDiagnostic(sprintf("%s '%s'", label, strjoin(removedPaths, "', '")));
            end

            createdFiles = change.createdFiles();
            if ~isempty(createdFiles)
                label = string(message("MATLAB:buildtool:FileCollectionFingerprintChange:FilesCreatedLabel"));
                conds(end+1) = StringDiagnostic(sprintf("%s '%s'", label, strjoin(createdFiles, "', '")));
            end

            deletedFiles = change.deletedFiles();
            if ~isempty(deletedFiles)
                label = string(message("MATLAB:buildtool:FileCollectionFingerprintChange:FilesDeletedLabel"));
                conds(end+1) = StringDiagnostic(sprintf("%s '%s'", label, strjoin(deletedFiles, "', '")));
            end

            modifiedFiles = change.modifiedFiles();
            if ~isempty(modifiedFiles)
                label = string(message("MATLAB:buildtool:FileCollectionFingerprintChange:FilesModifiedLabel"));
                conds(end+1) = StringDiagnostic(sprintf("%s '%s'", label, strjoin(modifiedFiles, "', '")));
            end
        end
    end
end

function atLeastOneMustBeFileCollectionFingerprint(a, b)
import matlab.buildtool.fingerprints.FileCollectionFingerprintChange;
if isempty(a) || ~isa(a, FileCollectionFingerprintChange.FileCollectionFingerprintClass)
    mustBeNonempty(b);
    mustBeA(b, FileCollectionFingerprintChange.FileCollectionFingerprintClass);
end
end

% LocalWords:  Fingerprinter prev curr writelines
