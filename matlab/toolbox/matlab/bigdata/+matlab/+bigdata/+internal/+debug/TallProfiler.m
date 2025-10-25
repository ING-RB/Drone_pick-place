%TallProfiler
% TallProfiler for tall expression evaluation.

%   Copyright 2018-2022 The MathWorks, Inc.

classdef TallProfiler < handle
    
    properties (Access = private)
        % Whether the tall profiler is currently running.
        Running (1,1) = false
        
        % Folder path to store all timing results during evaluation.
        ResultsFolder (1,1) string = missing
        
        % Method to use for measuring profiling stats. This can be either
        % "Callstats" or "TicToc".
        MeasureType (1,1) string = "Callstats"
        
        % Cleanup tasks to revert back to state prior to TallProfiler/start.
        StopCleanup (1,:) cell = cell(1, 0)
        
        % Cleanup tasks to revert back to state prior to TallProfiler
        % initialization.
        ResetCleanup (1,:) cell = cell(1, 0)
    end
    
    methods (Static)
        function setResultsFolder(resultsFolder)
            % Set the intermediate results folder to point to the given
            % local path or URL location. This is necessary for profiling
            % code in parallel where the temp folder is not shared by all
            % workers.
            import matlab.bigdata.internal.debug.TallProfiler
            obj = TallProfiler.singleton();
            assert(~obj.Running, ...
                "Assertion Failed: Cannot modify the profiler while it is running.");
            obj.reset();
            obj.ResultsFolder = resultsFolder;
        end
        
        function setMeasureType(measureType)
            % Set the measurement type used to collect profiling
            % information.
            import matlab.bigdata.internal.debug.TallProfiler
            obj = TallProfiler.singleton();
            assert(~obj.Running, ...
                "Assertion Failed: Cannot modify the profiler while it is running.");
            obj.reset();
            obj.MeasureType = validatestring(measureType, ["Callstats", "TicToc"]);
        end
        
        function on()
            % Turn tall profiling on.
            import matlab.bigdata.internal.debug.TallProfiler
            obj = TallProfiler.singleton();
            obj.reset();
            obj.start();
        end
        
        function off()
            % Turn tall profiling off.
            import matlab.bigdata.internal.debug.TallProfiler
            obj = TallProfiler.singleton();
            obj.stop();
        end
        
        function viewer()
            % Open a profile window to the collected profile stats.
            import matlab.bigdata.internal.debug.TallProfiler
            obj = TallProfiler.singleton();
            obj.stop();
            s = obj.stats();
            profview(0, s.asStruct());
        end
        
        function resume()
            % Resume tall profiling.
            import matlab.bigdata.internal.debug.TallProfiler
            obj = TallProfiler.singleton();
            obj.start();
        end
        
        function clear()
            % Clear all collected profile stats.
            import matlab.bigdata.internal.debug.TallProfiler
            obj = TallProfiler.singleton();
            obj.reset();
        end
        
        function out = info()
            % Retrieve collected statistics in a form compatible with
            % profview.
            import matlab.bigdata.internal.debug.TallProfiler
            obj = TallProfiler.singleton();
            obj.stop();
            s = obj.stats();
            out = s.asStruct();
        end
        
        
        function tf = enabled()
            % Check whether the profiler is running.
            import matlab.bigdata.internal.debug.TallProfiler
            obj = TallProfiler.singleton();
            tf = obj.Running;
        end
        
        function tasks = annotate(tasks, operationStack)
            % Add the necessary annotations to the given back-end
            % ExecutionTask in order to collect profiling stats.
            import matlab.bigdata.internal.debug.TallProfiler
            import matlab.bigdata.internal.debug.TicTocProcessorFactory
            import matlab.bigdata.internal.debug.CallstatsProcessorFactory
            obj = TallProfiler.singleton();
            assert(~isempty(obj), "Assertion Failed: TallProfiler is not enabled");
            
            useTicToc = (obj.MeasureType == "TicToc");
            
            for ii = 1:numel(tasks)
                factory = tasks(ii).DataProcessorFactory;
                if useTicToc
                    factory = TicTocProcessorFactory(factory, operationStack, obj.ResultsFolder);
                else
                    factory = CallstatsProcessorFactory(factory, operationStack, obj.ResultsFolder);
                end
                tasks(ii) = copyWithReplacedProcessorFactory(tasks(ii), factory);
            end
        end
    end
    
    methods
        function start(obj)
            % Start the tall profiler. This does not clear existing stats.
            if obj.Running
                return;
            end
            if ismissing(obj.ResultsFolder)
                tempFolder = matlab.bigdata.internal.util.TempFolder();
                obj.addResetCleanup(@() delete(tempFolder));
                obj.ResultsFolder = tempFolder.Path;
                obj.addResetCleanup(@() obj.setResultsFolderProperty(missing));
            else
                oldPath = obj.ResultsFolder;
                [~, rndName] = fileparts(tempname('_'));
                if matlab.io.datastore.internal.isIRI(char(oldPath))
                    newPath = matlab.io.datastore.internal.iriFullfile(oldPath, rndName);
                else
                    newPath = fullfile(oldPath, rndName);
                    mkdir(newPath);
                end
                newPath = string(newPath);
                obj.addResetCleanup(@() obj.setResultsFolderProperty(oldPath));
                obj.setResultsFolderProperty(newPath);
            end
            
            % All optimizations have to be disabled to map execution back
            % to line of code.
            import matlab.bigdata.internal.Optimizer
            import matlab.bigdata.internal.optimizer.NullOptimizer
            oldOptimizer = Optimizer.default(NullOptimizer());
            obj.addStopCleanup(@() Optimizer.default(oldOptimizer));
            
            % Turn on profiler annotation on the client as this displays
            % the "TallProfiler on" desktop message.
            callstats('start');
            callstats('pause');
            obj.incrementCallstatsCount();
            obj.addStopCleanup(@obj.decrementCallstatsCount);
            
            obj.Running = true;
            obj.addStopCleanup(@obj.clearRunningProperty);
        end
        
        function stop(obj)
            % Stop the tall profiler. This does not clear existing stats.
            for ii = numel(obj.StopCleanup):-1:1
                obj.StopCleanup(ii) = [];
            end
        end
        
        function reset(obj)
            % Reset existing stats, stopping the object if necessary.
            stop(obj);
            for ii = numel(obj.ResetCleanup):-1:1
                obj.ResetCleanup(ii) = [];
            end
        end
        
        function s = stats(obj)
            % Retrieve stats from the tall profiler.
            assert(~obj.Running, ...
                "Assertion failed: Cannot report profiler statistics while it is running");
            assert(~ismissing(obj.ResultsFolder), ...
                "Assertion failed: Cannot get profiler statistics before profiler has run");
            try
                ds = fileDatastore(obj.ResultsFolder, "ReadFcn", @iLoadInfoVariable);
            catch err
                error("Failed to load profiling statistics:\n%s\n", err.getReport());
            end
            entries = readall(ds);
            s = entries{1};
            for ii = 2:numel(entries)
                s = combine(s, entries{ii});
            end
        end
        
        function delete(obj)
            reset(obj);
        end
    end
    
    methods (Access = private)
        function clearRunningProperty(obj)
            % Helper method to clear running property as a cleanup task.
            obj.Running = false;
        end
        
        function setResultsFolderProperty(obj, newValue)
            % Helper method to set result folder property as a cleanup task.
            obj.ResultsFolder = string(newValue);
        end
        
        function addStopCleanup(obj, cleanupFunction)
            % Add a task to be executed on stop.
            obj.StopCleanup{end + 1} = onCleanup(cleanupFunction);
        end
        
        function addResetCleanup(obj, cleanupFunction)
            % Add a task to be executed on reset.
            obj.ResetCleanup{end + 1} = onCleanup(cleanupFunction);
        end
    end
    
    methods (Static)
        function out = singleton(in)
            % Singleton for TallProfiler object itself.
            import matlab.bigdata.internal.debug.TallProfiler
            persistent state
            if isempty(state)
                state = TallProfiler();
            end
            if nargout
                out = state;
            end
            if nargin
                state = in;
            end
        end
    end
    
    methods (Static, Hidden)
        function writeResults(info, id, resultsFolder)
            % Write profiling stats to the given results folder.
            
            % In order to support Hadoop, ResultsFolder is allowed to be in
            % HDFS or other non-local file-systems.
            filename = id + ".mat";
            if matlab.io.datastore.internal.isIRI(char(resultsFolder))
                tempFolder = matlab.bigdata.internal.util.TempFolder;
                localFilename = fullfile(tempFolder.Path, filename);
                remoteFilename = resultsFolder + "/" + filename;
                iSaveInfoVariable(localFilename, info);
                matlab.bigdata.internal.io.uploadfile(localFilename, remoteFilename);
            else
                iSaveInfoVariable(fullfile(resultsFolder, filename), info);
            end
        end
        
        function incrementCallstatsCount()
            % Increment the count of ProfileProcessorDecorators in the
            % local process. This is counted in order to ensure callstats
            % is not drooled after execution.
            import matlab.bigdata.internal.debug.TallProfiler
            count = TallProfiler.profilerCount();
            TallProfiler.profilerCount(count + 1);
            mlock;
        end
        
        function decrementCallstatsCount()
            % Decrement the count of ProfileProcessorDecorators in the
            % local process. This is counted in order to ensure callstats
            % is not drooled after execution.
            import matlab.bigdata.internal.debug.TallProfiler
            count = TallProfiler.profilerCount();
            TallProfiler.profilerCount(count - 1);
            if count == 1
                callstats('stop');
                munlock;
            end
        end
        
        function out = profilerCount(in)
            % Persistent around the count of ProfileProcessorDecorators in
            % the local process. This is counted in order to ensure callstats
            % is not drooled after execution.
            persistent count
            if isempty(count)
                count = 0;
            end
            if nargout
                out = count;
            end
            if nargin
                count = in;
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function iSaveInfoVariable(filename, Info)
% Helper function around saving an "Info" variable to MAT file
save(filename, "Info");
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function out = iLoadInfoVariable(filename, varargin)
% Helper function around loading an "Info" variable from MAT file
out = load(filename);
out = out.Info;
end
