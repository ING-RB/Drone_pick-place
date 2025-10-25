classdef DsManager < handle
    %This class is for internal use only. It may be removed in the future.

    % DSMANAGER - A key-value store to manage a collection of
    % matlab.io.datastore.SimulationDataStore variables.
    % Example:
    % dsManager = DsManager();
    % dsManager.addToMap("header.stamp.frame_id", frame_datastore);
    % frame_val = dsManager.read("header.stamp.frame_id");

    %   Copyright 2024 The MathWorks, Inc.

    properties(Access=private)
        dsMap % Main dictionary to store the key-value paris.
        rs = 100 % Current readSize for all datastore variables managed by this class.
        isSet = false % Checks if dictionary is created or not.
        Tout; % Current duration values.
        tIdx = 1; % Cursor inside the Tout array.
    end

    properties(Access=public)
        numMsgs = 0; % Num of messages stored inside the datastore variables;
    end

    methods
        function obj = DsManager

        end

        function addToMap(obj,  dsKey, dsValue )
            % addToMap Adds a datastore variable to be managed. The entry stores
            % three things:
            % 1. DataStore variable
            % 2. Cache to store data read from MAT file
            % 3. Cursor pointing inside the cache
            dsValue.reset();
            dsValue.ReadSize = obj.rs;
            entry = struct('dsPtr', dsValue, 'dsIdx', 1, 'cacheTimeTable', timetable());
            if ~obj.isSet
                obj.dsMap = dictionary(dsKey, entry);
                obj.isSet = true;

                % Setting this once as Number of Samples will be same for all the fields inside the signal
                obj.numMsgs = dsValue.NumSamples;
            else
                obj.dsMap(dsKey) = entry;
            end
        end

        function t = getTime(obj)
            % Returns the cached time.
            if (obj.tIdx > obj.rs)
                obj.tIdx = 1;
            end
            
            if isempty(obj.Tout)
                %If Tout is empty then none of the datastore variables were
                %read -> All fields are empty -> Blank message. Since, we
                %are logging a blank message we still need a timestamp. So,
                %read 'all' the time values from a cached datastore and set
                %batch size (rs) to NumSamples. (g3463409)

                obj.rs = obj.numMsgs;
                dsValues = obj.dsMap.values;
                dsVar = dsValues(1).dsPtr; % Get the first datastore variable
                data = dsVar.readall;
                obj.Tout = data.Time;
            end
            
            t = seconds(obj.Tout(obj.tIdx));
            obj.tIdx = obj.tIdx + 1;
        end

        function data = read(obj, dsKey, s)
            % read Read data from the datastore variable pointed by dsId.
            % resizes the output based on argument s.

            if (obj.dsMap(dsKey).dsIdx == 1)
                % Caching data and duration values. Caching is done whenver
                % cursor is reset (dsIdx == 1).
                tt = obj.dsMap(dsKey).dsPtr.read();
                obj.dsMap(dsKey).cacheTimeTable = tt.Data;
                obj.Tout = tt.Time;
            end

            % Sets data and resize if required.
            if nargin < 3
                data = obj.dsMap(dsKey).cacheTimeTable(obj.dsMap(dsKey).dsIdx);
            else
                data = obj.dsMap(dsKey).cacheTimeTable(obj.dsMap(dsKey).dsIdx, 1:s);
            end

            % Increments the cursor.
            obj.dsMap(dsKey).dsIdx = obj.dsMap(dsKey).dsIdx + 1;
            if obj.dsMap(dsKey).dsIdx > obj.rs
                obj.dsMap(dsKey).dsIdx = 1;
            end

        end

        function reset(obj)
            for v = obj.dsMap.values
                v.dsPtr.reset();
            end
        end


        function setBatchSize(obj, size)
            %Set cache size for all variables
            obj.rs = size;

            %dsMap can be empty if no message is detected while setting up
            %tables.
            if ~isempty(obj.dsMap)
                keys = obj.dsMap.keys;
                for kIdx = 1:numel(keys)
                    k = keys{kIdx};
                    obj.dsMap(k).dsPtr.ReadSize = size;
                    obj.dsMap(k).dsPtr.reset();
                end
            end
        end
    end
end

