classdef PersistentTaskTraceRepository < matlab.buildtool.internal.fingerprints.TaskTraceRepository
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (Access = private)
        TracesFolder (1,1) string
    end

    methods
        function repo = PersistentTaskTraceRepository(folder)
            import matlab.buildtool.internal.io.absolutePath;
            repo.TracesFolder = absolutePath(fullfile(folder, "taskTraces"));
        end

        function trace = lookupTrace(repo, key)
            arguments
                repo (1,1) matlab.buildtool.internal.fingerprints.PersistentTaskTraceRepository
                key (1,1) string
            end

            import matlab.buildtool.internal.fingerprints.TaskTrace;

            [traceFile, traceName] = repo.traceFile(key);

            if isfile(traceFile)
                vars = load(traceFile, "-mat", traceName);
                trace = vars.(traceName);
            else
                trace = TaskTrace.empty();
            end
        end

        function updateTrace(repo, key, trace)
            arguments
                repo (1,1) matlab.buildtool.internal.fingerprints.PersistentTaskTraceRepository
                key (1,1) string
                trace (1,1) matlab.buildtool.internal.fingerprints.TaskTrace
            end

            if ~isfolder(repo.TracesFolder)
                mkdir(repo.TracesFolder);
            end

            [traceFile, traceName] = repo.traceFile(key);

            vars.(traceName) = trace;
            save(traceFile, "-fromStruct", vars, "-mat", "-v7.3");
        end

        function removeTrace(repo, keys)
            arguments
                repo (1,1) matlab.buildtool.internal.fingerprints.PersistentTaskTraceRepository
                keys (1,:) string
            end

            if ~isfolder(repo.TracesFolder) 
                return;
            end

            for key = keys
                traceFile = repo.traceFile(key);
    
                if isfile(traceFile)
                    delete(traceFile);
                end
            end
        end

        function traces = allTraces(repo)
            arguments
                repo (1,1) matlab.buildtool.internal.fingerprints.PersistentTaskTraceRepository
            end

            import matlab.buildtool.internal.fingerprints.TaskTrace;

            traces = TaskTrace.empty(1, 0);

            if ~isfolder(repo.TracesFolder)
                return;
            end

            for file = repo.traceFiles()
                s = load(file, "-mat");
                ns = fieldnames(s);

                trace = s.(ns{1});
                traces(end+1) = trace; %#ok<AGROW>
            end
        end

        function removeAllTraces(repo)
            arguments
                repo (1,1) matlab.buildtool.internal.fingerprints.PersistentTaskTraceRepository
            end

            if ~isfolder(repo.TracesFolder)
                return;
            end

            for file = repo.traceFiles()
                delete(file);
            end
        end
    end

    methods (Access = protected)
        function [file, name] = traceFile(repo, key)
            import matlab.buildtool.internal.fingerprints.stringHash;
            name = "T" + dec2hex(stringHash(key), 16);
            file = fullfile(repo.TracesFolder, name);
        end

        function files = traceFiles(repo)
            import matlab.io.internal.glob;
            files = glob(fullfile(repo.TracesFolder, "T*"))';
            files = validTraceNames(files);
        end
    end
end

function validTraceFiles = validTraceNames(traceFiles)
    matches = false(size(traceFiles));
    for i = 1:numel(traceFiles)
        matches(i) = ~isempty(regexp(traceFiles(i), "T[0-9A-F]{16}$", "once"));
    end
    validTraceFiles = traceFiles(matches);
end
