classdef ros2bagwriter < ros.internal.mixin.ROSInternalAccess & ...
        robotics.core.internal.mixin.Unsaveable & dynamicprops & ...
        fusion.internal.UnitDisplayer

    %ROS2BAGWRITER Create and write logs to ros2bag log file
    %
    % Use the ros2bagwriter object to create a folder and a ros2bag log file  
    % (.db3 or .mcap) in it. Use the write function to write logs to the ros2bag file. 
    % Each log contains a topic, its corresponding timestamp, and a ROS2 message. 
    % After writing the logs to the ros2bag file, call the delete function 
    % to close the opened ros2bag file, create the metadata.yaml file, and 
    % remove the object from the memory.
    %
    % Note: The ros2bagwriter object locks the created ros2bag file for use, 
    % it is necessary to delete and clear the ros2bagwriter object in order 
    % to use the ros2bag file.
    %
    % BAGWRITER = ros2bagwriter(PATH) creates ros2bag file in the location  
    % specified by PATH and returns its corresponding ros2bagwriter object, 
    % BAGWRITER, which can be used to write records into the ros2bag file. 
    % The PATH input argument sets the Path property.
    %
    % The name of the ros2bag file is the name of the folder containing it. 
    % If the folders specified in PATH are not present in the directory, the 
    % object creates them and places the ros2bag file accordingly.
    %
    % BAGWRITER = ros2bagwriter(___,Name=Value) provides additional options
    %   specified by one or more Name,Value pair arguments: CacheSize,
    %   SplitSize, SplitDuration, CompressionFormat, CompressionMode,
    %   properties using name-value argument. Use this syntax with the input
    %   argument in the previous syntax. You can specify several name-value pair
    %   arguments in any order as Name1=Value1,...,NameN=ValueN.
    %
    %   ros2bagwriter properties:
    %      Path                - Path to the bag folder
    %      StartTime           - Earliest timestamp of messages written to 
    %                            ros2bag file
    %      EndTime             - Latest timestamp of messages written to 
    %                            ros2bag file
    %      NumMessages         - Number of messages written to ros2bag file
    %      CacheSize           - Size of cache for writing messages to 
    %                            ros2bag file
    %      SplitSize           - Size in KB before the bagfile will be split.
    %                            Default value is Inf.
    %      SplitDuration       - Duration in seconds before the bagfile
    %                            will be split. Default value is Inf.
    %      CompressionFormat   - Compression format/algorithm for creating
    %                            a ros2bag file. Default is 'none'. Options are:
    %                              "none"     - No compression is enabled.                                         
    %                              "zstd"     - Compression format using zstd
    %                                           compression.
    %      CompressionMode     - Determine whether to compress by file or
    %                            message. Default is 'none'. Options are:
    %                              "none"     - No compression Mode is enabled.
    %                                           This should be set to "file"
    %                                           or "message", if compression
    %                                           format is selected as "zstd".
    %                              "file"     - Compress bag by file.
    %                              "message"  - Compress bag by message.
    %
    %      StorageFormat       - Storage format of ros2bag file. Default 
    %                            value is 'sqlite3'. Options are:
    %                              "sqlite3"  - Storage format is "sqlite3" 
    %                                            which creates .db3 log files.
    %                               "mcap"    - Storage format is "mcap"  
    %                                           which creates .mcap log
    %                                           files.
    %      StorageConfigurationProfile - Configuration profile that is used
    %                           to write the messages into bag file. This
    %                           name value argument is supported only when
    %                           StorageFormat is MCAP. Default profile 
    %                           is none. Options are:
    %                              "none"      - No profile is used.
    %                              "fastwrite" - Configures the MCAP writer 
    %                                            for the highest possible 
    %                                            write throughput and lowest
    %                                            resource utilization.
    %                              "zstd_fast" - Configures the MCAP writer 
    %                                            to use chunk compression
    %                                            with zstd compression. Chunk  
    %                                            compression yields file sizes 
    %                                            comparable to bags compressed 
    %                                            with file-level compression, 
    %                                            but allows tools to efficiently 
    %                                            read messages without decompressing 
    %                                            the entire bag.
    %                             "zstd_small" - Configures the MCAP writer 
    %                                            to write 4MB chunks, compressed
    %                                            with zstd using its highest 
    %                                            compression ratio. This produces 
    %                                            very small bags, but can be
    %                                            resource-intensive to write.
    %                              "custom"    - By selecting this, MCAP writer 
    %                                            can be configured with customized  
    %                                            settings by providing the 
    %                                            storage configuration file
    %                                            path.
    %                                            
    %      StorageConfigurationFile - This is path to a .yaml file which contains 
    %                          customized settings to configure the MCAP writer.    
    %                          This name-value argument is supported only when  
    %                          storage configuration profile is selected as "custom". 
    %
    %      SerializationFormat      - Serialization format of messages in ros2bag 
    %                                 file.
    %
    %   NOTE: If both SplitSize and SplitDuration are specified, the bag file
    %   will be split at whicever threshold is reached first. These options can 
    %   be used with Compression options enabled.
    %
    %   ros2bagwriter methods:
    %      write - Write logs to ros2bag log file
    %      delete - Remove ros2bagwriter object from memory
    %
    %   Example 1: Write Single Log to ros2bag File
    %     %Create a ros2bagwriter object and a ros2bag file in the specified path.
    %     bagWriter = ros2bagwriter("myRos2bag");
    %     
    %     %Write a single log to the ros2bag file.
    %     topic = "/odom";
    %     msg = ros2message("nav_msgs/Odometry");
    %     timeStamp = ros2time(1.6170e+09);
    %     write(bagWriter,topic,timeStamp,msg)
    %
    %     %Close the bagfile, remove the ros2bagwriter object from memory 
    %     %and clear the associated object handle.
    %     delete(bagWriter)
    %     clear bagWriter
    %
    %
    %   Example 2: Write Multiple Logs to ros2bag File          
    %     %Create a ros2bagwriter object and a ros2bag file in the specified path.
    %     %Specify the size of cache for each message.
    %     bagWriter = ros2bagwriter("new_bag_files/my_bag_file",CacheSize=1500);
    %     
    %     %Write multiple logs to the ros2bag file.
    %     msg1 = ros2message("nav_msgs/Odometry");
    %     msg2 = ros2message("geometry_msgs/Twist");
    %     msg3 = ros2message("sensor_msgs/Image");
    %     write(bagWriter, ...
    %           ["/odom","cmd_vel","/camera/rgb/image_raw"], ...
    %           {ros2time(1.6160e+09),ros2time(1.6170e+09),ros2time(1.6180e+09)}, ...
    %           {msg1,msg2,msg3})
    %     
    %     %Close the bagfile, remove the ros2bagwriter object from memory 
    %     %and clear the associated object handle.
    %     delete(bagWriter)
    %     clear bagWriter
    %
    %   Example 3: Write Multiple Logs for Same Topic to ros2bag File
    %     %Create a ros2bagwriter object and a ros2bag file in the specified path.
    %     bagWriter = ros2bagwriter("myBag");
    %     
    %     %Write multiple logs for same topic to the ros2bag file.
    %     pointMsg1 = ros2message("geometry_msgs/Point");
    %     pointMsg1.x = 1;
    %     pointMsg2 = ros2message("geometry_msgs/Point");
    %     pointMsg2.x = 2;
    %     pointMsg3 = ros2message("geometry_msgs/Point");
    %     pointMsg3.x = 3;
    %     write(bagWriter, ...
    %           "/point", ...
    %           {1.6190e+09, 1.6200e+09,1.6210e+09}, ...
    %           {pointMsg1,pointMsg2,pointMsg3})
    %     
    %     %Close the bagfile, remove the ros2bagwriter object from memory 
    %     %and clear the associated object handle.
    %     delete(bagWriter)
    %     clear bagWriter
    %
    %
    %   Example 4: Write Multiple Logs to ros2bag Files with split options enabled         
    %     %Create ros2bagwriter objects in the specified path.
    %     %Create multiple log files and each bag file of size 100KB
    %     bagWriter1 = ros2bagwriter("new_bag_files/bag_split_size",SplitSize=100);
    %
    %     %Specify the duration of 60 seconds before the bag splits.
    %     bagWriter2 = ros2bagwriter("new_bag_files/bag_split_duration",SplitDuration=60);
    %     
    %     %Write multiple logs to the ros2bag file.
    %     msg1 = ros2message("nav_msgs/Odometry");
    %     msg2 = ros2message("geometry_msgs/Twist");
    %     msg3 = ros2message("sensor_msgs/Image");
    %     msgTime1 = ros2time(1.6160e+09);
    %     msgTime2 = ros2time(1.6170e+09);
    %     msgTime3 = ros2time(1.6180e+09);
    %     for i=1:100
    %        msgTime1.sec = msgTime1.sec+1;
    %        msgTime2.sec = msgTime1.sec+1;
    %        msgTime3.sec = msgTime2.sec+1;
    %        write(bagWriter1, ...
    %              ["/odom","cmd_vel","/camera/rgb/image_raw"], ...
    %              {msgTime1,msgTime2,msgTime3}, ...
    %              {msg1,msg2,msg3})
    %        write(bagWriter2, ...
    %              ["/odom","/camera/rgb/image_raw"], ...
    %              {msgTime1,msgTime2}, ...
    %              {msg1,msg2})
    %     end
    %     
    %     %Close the bagfile, remove the ros2bagwriter object from memory 
    %     %and clear the associated object handle.
    %     delete(bagWriter1)
    %     delete(bagWriter2)
    %     clear bagWriter1
    %     clear bagWriter2
    %
    %
    %   Example 5: Write Multiple Logs to ros2bag Files with compression options enabled         
    %     %Create ros2bagwriter objects in the specified path.
    %     %Specify the compression format as zstd and compression mode as file.
    %     bagWriter1 = ros2bagwriter("new_bag_files/bag_file_compressed", ...
    %                                CompressionFormat="zstd", CompressionMode="file");
    %
    %     %Specify the compression format as zstd and compression mode as message.
    %     bagWriter2 = ros2bagwriter("new_bag_files/bag_message_compressed", ...
    %                                CompressionFormat="zstd", CompressionMode="message");
    %     
    %     %Write multiple logs to the ros2bag file.
    %     msg1 = ros2message("nav_msgs/Odometry");
    %     msg2 = ros2message("geometry_msgs/Twist");
    %     msg3 = ros2message("sensor_msgs/Image");
    %     msgTime1 = ros2time(1.6160e+09);
    %     msgTime2 = ros2time(1.6170e+09);
    %     msgTime3 = ros2time(1.6180e+09);
    %     for i=1:100
    %        msgTime1.sec = msgTime1.sec+1;
    %        msgTime2.sec = msgTime1.sec+1;
    %        msgTime3.sec = msgTime2.sec+1;
    %        write(bagWriter1, ...
    %              ["/odom","cmd_vel","/camera/rgb/image_raw"], ...
    %              {msgTime1,msgTime2,msgTime3}, ...
    %              {msg1,msg2,msg3})
    %        write(bagWriter2, ...
    %              ["/odom","/camera/rgb/image_raw"], ...
    %              {msgTime1,msgTime2}, ...
    %              {msg1,msg2})
    %     end
    %     
    %     %Close the bagfile, remove the ros2bagwriter object from memory 
    %     %and clear the associated object handle.
    %     delete(bagWriter1)
    %     delete(bagWriter2)
    %     clear bagWriter1
    %     clear bagWriter2
    %
    %   Example 6: Write Single Logs to mcap ros2bag File with storage
    %   configuration profile as "fastwrite".
    %     %Create a ros2bagwriter object with storage format as mcap.
    %     bagWriter =
    %           ros2bagwriter("myRos2MCAPbag","StorageFormat","mcap", ...
    %               "StorageConfigurationProfile","fastwrite");
    %     
    %     %Write a single log to the ros2bag file.
    %     topic = "/odom";
    %     msg = ros2message("nav_msgs/Odometry");
    %     timeStamp = ros2time(1.6170e+09);
    %     write(bagWriter,topic,timeStamp,msg)
    %
    %     %Close the bagfile, remove the ros2bagwriter object from memory 
    %     %and clear the associated object handle.
    %     delete(bagWriter)
    %     clear bagWriter
    %
    %   See also ros2bagreader, ros2bag.

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties (Dependent, SetAccess = private)
        % Path Path to ros2bag folder
        % Path to the ros2bag folder, specified as a string or character vector.
        % 
        % This property is read-only.
        Path
        
        % StartTime Earliest timestamp of messages written to ros2bag file
        % The earliest timestamp of the messages written to the ros2bag file, 
        % specified as a numeric scalar in seconds.
        % 
        % This property is read-only.
        StartTime

        % EndTime Latest timestamp of messages written to ros2bag file
        % The latest timestamp of the messages written to the ros2bag file,  
        % specified as a numeric scalar in seconds.
        % 
        % This property is read-only.
        EndTime

        % NumMessages Number of messages written to ros2bag file
        % Number of messages written to the ros2bag file, specified as a 
        % numeric scalar.
        % 
        % This property is read-only.
        NumMessages
    end
    properties (SetAccess = private)
        % Storage format of the ros2bag file.
        % 
        % Default: sqlite3
        StorageFormat

        % CacheSize Size of cache for writing messages to ros2bag file
        % Size of cache for writing messages to ros2bag file, specified as
        % a nonzero positive integer in bytes. The value specify the buffer 
        % within the ros2bag file object. Reducing this value results in more 
        % writes to disk.
        % 
        % Default: 104857600
        CacheSize

        % SplitSize Size in KB before the bagfile is split into a new bag file.
        % Size is specified as a nonzero positive numeric scalar in KB.
        % The value specified should be greater than 84KB (86016 bytes).
        % The default value is Inf KB, meaning bag files will not be split
        % and data is written to a single bag file.
        % 
        % Default: Inf
        SplitSize

        % SplitDuration Duration in seconds before the bagfile is
        % split into a new bag file. Duration is specified as a nonzero positive
        % numeric scalar or a struct representing ros2time or ros2duration.
        % The default value is Inf seconds, meaning bag files will not be
        % split and data is written to a single bag file.
        % 
        % Default: Inf
        SplitDuration
    end

    properties (Constant)
       
        % SerializationFormat Serialization format of messages in ros2bag file
        % Serialization format of messages in the ros2bag file, specified as 'cdr'.
        % 
        % This property is read-only.
        SerializationFormat = 'cdr'
    end

    properties (SetAccess = private)
        % CompressionFormat Compression format/algorithm for creating
        % a ros2bag file specified as char or string
        %
        % Default: "none"
        CompressionFormat

        % CompressionFormat Compression mode specified as char or string
        % for compressing a ros2bag file by either "file" or "message".
        %
        % Default: "none"
        CompressionMode
    end

    properties (SetAccess = private, Hidden)
        % CompressionQueueSize Number of files/messages that may be queued
        % for compression before being dropped.
        %
        % Default: uint64(1)
        CompressionQueueSize

        % CompressionThreads Number of files/messages that may be
        % compressed in parallel. The default value Inf will be interpreted as 
        % number of CPU cores.
        %
        % Default: Inf
        CompressionThreads
    end

    properties (Hidden)
        CacheSizeUnits = 'Bytes';
        SplitSizeUnits = 'KB';
    end

    properties (Constant, Access = private)
        
        DefaultStorageFormat = 'sqlite3'

        DefaultStorageConfigurationProfile = 'none'

        %DefaultCacheSize - Default CacheSize value is 100 mb
        DefaultCacheSize = uint64(100*1024*1024)

        DefaultSplitSize = inf

        DefaultSplitDuration = inf

        DefaultCompressionFormat = 'none'

        DefaultCompressionMode = 'none'

        DefaultCompressionQueueSize = uint64(1)

        DefaultCompressionThreads = inf

        MinSizeRequiredForBagSplit = 84
    end

    properties (Transient, Access = ?matlab.unittest.TestCase)
        %InternalBagWriter - MCOS C++ object for reading from rosbag
        InternalBagWriter
    end

    methods
        function obj = ros2bagwriter(path, varargin)
            %ROS2BAGWRITER Constructor for ros2bagwriter class
            %   BAGWRITER = ROS2BAGWRITER(path) creates ros2bag file in 
            %   the specified path and returns a new ros2bagwriter object  
            %   which is used to write the bag file.
            %
            %   If the input path is not available, it creates the path by
            %   creating the folders and sub folders.
            %
            %   Please see the class documentation (help ros2bagwriter)
            %   for more details.

            try
                narginchk(1, 21);

                % Convert all string arguments to characters
                [bagPath, varargin{:}] = convertStringsToChars(path, varargin{:});

                % Parse the input parameters.
                paramParser = getParsers(obj);
                parse(paramParser, bagPath, varargin{:});
                
                dirInfo = dir(bagPath);
                whichPkgs = ~ismember({dirInfo.name}, {'.', '..'});
                fList = {dirInfo(whichPkgs).name};
                if ~isempty(whichPkgs)
                    bagPath = dirInfo.folder;
                end

                if isfolder(bagPath)
                    % Throw the error if input folder exists and contains .db3 or .mcap or .yaml files.
                    for fi = 1:length(fList)
                        if(endsWith(fList{fi},'.db3') || endsWith(fList{fi},'.mcap') || endsWith(fList{fi},'.yaml'))
                            newEx = MException(message('ros:mlros2:bag:Ros2bagWriterCreationError'));
                            ex = MException(message('ros:mlros2:bag:InputPathAlreadyHasRos2bagFile',fList{fi}));
                            throw(newEx.addCause(ex));
                        end
                    end
                    %create a bag folder name appended with timestamps of
                    %each bag folder creation. This will be later used for
                    %bag folder creation.
                    bagPath = fullfile(bagPath,['rosbag2_',char(datetime('now'), 'yyyy_MM_dd-HH_mm_ss')]);
                end

                obj.CacheSize = uint64(paramParser.Results.CacheSize);
                splitSize = paramParser.Results.SplitSize;
                splitDuration = paramParser.Results.SplitDuration;

                obj.StorageFormat = validatestring(lower(convertStringsToChars(paramParser.Results.StorageFormat)),{'sqlite3','mcap'});

                % Extract full matched value if there was a partial match
                obj.CompressionFormat = validatestring(lower(convertStringsToChars(paramParser.Results.CompressionFormat)),{'none','zstd'});
                
                % Message compression is not supported for mcap format 
                if strcmp(obj.StorageFormat,'sqlite3')
                    obj.CompressionMode = validatestring(lower(convertStringsToChars(paramParser.Results.CompressionMode)),{'none', 'file', 'message'});
                    storageConfigurationProfile = validatestring(lower(convertStringsToChars(paramParser.Results.StorageConfigurationProfile)),{'none'});
                elseif strcmp(obj.StorageFormat,'mcap')
                    obj.CompressionMode = validatestring(lower(convertStringsToChars(paramParser.Results.CompressionMode)),{'none', 'file'});
                    
                    addprop(obj,'StorageConfigurationProfile');
                    storageConfigurationProfile = validatestring(lower(convertStringsToChars(paramParser.Results.StorageConfigurationProfile)), ...
                                                            {'none', 'fastwrite', 'zstd_fast', 'zstd_small', 'custom'});
                    obj.StorageConfigurationProfile = storageConfigurationProfile;
                end

                storageConfigurationFile = convertStringsToChars(paramParser.Results.StorageConfigurationFile);
                if strcmp(storageConfigurationProfile,'custom')
                    addprop(obj,'StorageConfigurationFile');
                    
                    if isfile(storageConfigurationFile)
                        storageConfigurationFile = ros.internal.Parsing.validateFilePath(storageConfigurationFile);
                        [~,~,extension] = fileparts(storageConfigurationFile);
                        if strcmp(extension,'.yaml') 
                            obj.StorageConfigurationFile = storageConfigurationFile;
                        else
                            error(message('ros:mlros2:bag:InvalidStorageConfigFile',storageConfigurationFile));%add newly
                        end
                    else
                        error(message('ros:mlros2:bag:InvalidStorageConfigFile',storageConfigurationFile));%add newly
                    end
                elseif ~isempty(storageConfigurationFile)
                    error(message('ros:mlros2:bag:ConfigFileAllowedOnlyForCustom'));%add newly
                end

                obj.CompressionQueueSize = uint64(paramParser.Results.CompressionQueueSize);
                compressionThreads = paramParser.Results.CompressionThreads;

                if ~isfinite(splitSize)
                    obj.SplitSize = splitSize;
                    splitSize = uint64(0);
                else
                    splitSize = uint64(splitSize);
                    obj.SplitSize = splitSize;
                end

                if isstruct(splitDuration)
                    if ~(isfield(splitDuration, 'MessageType') && ismember(splitDuration.MessageType, {'builtin_interfaces/Time','builtin_interfaces/Duration'}))
                       error(message('ros:mlros2:bag:InvalidMessageType'));
                    end
                    if ~isfield(splitDuration,'sec') || ~isfield(splitDuration,'nanosec')
                        error(message('ros:mlros2:time:InvalidStructureInput'));
                    end
                    splitDuration = uint64(splitDuration.sec)*1e9 + uint64(splitDuration.nanosec);
                    obj.SplitDuration = splitDuration;
                elseif ~isfinite(splitDuration)
                    obj.SplitDuration = splitDuration;
                    splitDuration = uint64(0);
                else
                    splitDuration = uint64(splitDuration);
                    obj.SplitDuration = splitDuration;
                end
                
                % set CompressionThreads property set by user only if the
                % CompressionFormat is not none, otherwise set it to
                % default value.
                if ~isequal(obj.CompressionFormat,'none')
                    if ~isfinite(compressionThreads)
                        obj.CompressionThreads = compressionThreads;
                        compressionThreads = uint64(0);
                    else
                        compressionThreads = uint64(compressionThreads);
                        obj.CompressionThreads = compressionThreads;
                    end
                else
                    if ~isequal(obj.CompressionMode,'none')
                        throw(MException(message('ros:mlros2:bag:CompressionFormatError')));
                    end
                    obj.CompressionMode = obj.DefaultCompressionMode;
                    obj.CompressionQueueSize = obj.DefaultCompressionQueueSize;
                    obj.CompressionThreads = obj.DefaultCompressionThreads;
                end 

                [pathEnv, amentPrefixEnv, cleanPath, cleanAmentPath] = ros.internal.ros2.setupRos2Env(); %#ok<ASGLU> 

                %Create the mcos object for ros2bagwriter and open a bag file
                obj.InternalBagWriter = ...
                    rosbag2.bag2.internal.Ros2bagWriterWrapper(bagPath, ...
                                                               obj.CacheSize, ...
                                                               splitSize*uint64(1024), ...
                                                               splitDuration, ...
                                                               obj.SerializationFormat, ...
                                                               obj.StorageFormat, ...
                                                               obj.CompressionFormat, ...
                                                               obj.CompressionMode, ...
                                                               obj.CompressionQueueSize, ...
                                                               compressionThreads, ...
                                                               storageConfigurationProfile, ...
                                                               storageConfigurationFile);
            catch ex
                newEx = MException(message('ros:mlros2:bag:Ros2bagWriterCreationError'));
                throw(newEx.addCause(ex));
            end
            
            function paramParser = getParsers(obj)
                % Set up separate parsers for parameters and other input

                paramParser = inputParser;

                addRequired(paramParser, 'bagPath', ...
                    @(x) validateattributes(x, ...
                    {'char', 'string'}, ...
                    {'scalartext', 'nonempty'}, ...
                    'ros2bagwriter', ...
                    'bagPath'));

                addParameter(paramParser, 'CacheSize', obj.DefaultCacheSize, ...
                    @(x) validateattributes(x, ...
                    {'numeric'}, ...
                    {'scalar', 'finite', 'nonnegative', 'integer'}, ...
                    'ros2bagwriter', ...
                    'CacheSize'));

                % Minimum value of size allowed for bag splitting is 84KB
                addParameter(paramParser, 'SplitSize', obj.DefaultSplitSize, ...
                    @(x) validateattributes(x, ...
                    {'numeric'}, ...
                    {'nonempty','scalar','positive','>=',obj.MinSizeRequiredForBagSplit}, ...
                    'ros2bagwriter', ...
                    'SplitSize'));

                addParameter(paramParser, 'SplitDuration', obj.DefaultSplitDuration, ...
                    @(x) validateattributes(x, ...
                    {'struct','numeric'}, ...
                    {'scalar', 'nonempty','nonnegative'}, ...
                    'ros2bagwriter', ...
                    'SplitDuration'));

                addParameter(paramParser, 'CompressionFormat', obj.DefaultCompressionFormat, ...
                    @(x) validateStringParameter(x, ...
                    {'none', 'zstd'},...
                    'ros2bagwriter', ...
                    'CompressionFormat'));

                addParameter(paramParser, 'CompressionMode', obj.DefaultCompressionMode, ...
                    @(x) validateStringParameter(x, ...
                    {'none', 'file', 'message'},...
                    'ros2bagwriter', ...
                    'CompressionMode'));

                addParameter(paramParser, 'CompressionQueueSize', obj.DefaultCompressionQueueSize, ...
                    @(x) validateattributes(x, ...
                    {'numeric'}, ...
                    {'scalar', 'finite', 'positive', 'integer'}, ...
                    'ros2bagwriter', ...
                    'CompressionQueueSize'));

                addParameter(paramParser, 'CompressionThreads', obj.DefaultCompressionThreads, ...
                    @(x) validateattributes(x, ...
                    {'numeric'}, ...
                    {'scalar','nonnegative'}, ...
                    'ros2bagwriter', ...
                    'CompressionThreads'));

                addParameter(paramParser, 'StorageFormat', obj.DefaultStorageFormat, ...
                    @(x) validateStringParameter(x, ...
                    {'sqlite3', 'mcap'},...
                    'ros2bagwriter', ...
                    'StorageFormat'));

                addParameter(paramParser, 'StorageConfigurationProfile', obj.DefaultStorageConfigurationProfile, ...
                    @(x) validateStringParameter(x, ...
                    {'none', 'fastwrite', 'zstd_fast', 'zstd_small', 'custom'},...
                    'ros2bagwriter', ...
                    'StorageConfigurationProfile'));

                addParameter(paramParser, 'StorageConfigurationFile', '', ...
                    @(x) validateattributes(x, ...
                    {'char', 'string'}, ...
                    {'scalartext', 'nonempty'}, ...
                    'ros2bagwriter', ...
                    'StorageConfigurationFile'));

                function validateStringParameter(value, options, funcName, varName)
                    % Separate function to suppress output and just validate
                    validatestring(value, options, funcName, varName);
                end
            end
        end

        function delete(obj)
            %DELETE Remove ros2bagwriter object from memory
            %  delete(BAGWRITER) removes the ros2bagwriter object from memory. 
            %  The function closes the opened ros2bag file and creates the 
            %  metadata.yaml file before deleting the object.
            % 
            %  If multiple references to the ros2bagwriter object exist in 
            %  the workspace, deleting the ros2bagwriter object invalidates 
            %  the remaining reference. Use the clear command to delete the 
            %  remaining references to the object from the workspace.
            %
            %  Note: The ros2bagwriter object locks the created ros2bag file 
            %  for use, it is necessary to delete and clear the ros2bagwriter 
            %  object in order to use the ros2bag file.

            obj.InternalBagWriter = [];
        end

        function write(obj, topic, timeStamp, ros2Message)
            %WRITE Write logs to ros2bag log file
            %  write(BAGWRITER,TOPIC,TIMESTAMP,MESSAGE) writes a single or 
            %  multiple logs to a ros2bag log file. A log contains a topic, 
            %  its corresponding timestamp, and a ROS message.
            % 
            %  To write a single log to a ros2bag log file, specify the topic 
            %  as a string or character vector, the timestamp as a ros2time  
            %  structure or numeric scalar, and the message as a ros2message 
            %  structure.
            % 
            %  To write a multiple logs to a ros2bag log file, specify the 
            %  topic as a cell array of string scalars or cell array of character 
            %  vectors, the timestamp as a cell array of ros2time structure  
            %  or cell array of numeric scalars, and the message as a cell 
            %  array of ros2message structure.
            % 
            %  To write a multiple logs of same topic to a ros2bag log file, 
            %  specify the topic as a string or character vector, the timestamp 
            %  as a cell array of ros2time structure or cell array of numeric 
            %  scalars, and the message as a cell array of ros2message structure.
            %
            %  Example 1: Write Single Log to ros2bag File
            %     %Create a ros2bagwriter object and a ros2bag file in the specified path.
            %     bagWriter = ros2bagwriter("myRos2bag");
            %     
            %     %Write a single log to the ros2bag file.
            %     topic = "/odom";
            %     msg = ros2message("nav_msgs/Odometry");
            %     timeStamp = ros2time(1.6170e+09);
            %     write(bagWriter,topic,timeStamp,msg)
            %
            %     %Close the bagfile, remove the ros2bagwriter object from memory 
            %     %and clear the associated object handle.
            %     delete(bagWriter)
            %     clear bagWriter
            %
            %
            %   Example 2: Write Multiple Logs to ros2bag File          
            %     %Create a ros2bagwriter object and a ros2bag file in the specified path.
            %     %Specify the size of cache for each message.
            %     bagWriter = ros2bagwriter("bag_files/my_bag_file",CacheSize=1500);
            %     
            %     %Write multiple logs to the ros2bag file.
            %     msg1 = ros2message("nav_msgs/Odometry");
            %     msg2 = ros2message("geometry_msgs/Twist");
            %     msg3 = ros2message("sensor_msgs/Image");
            %     write(bagWriter, ...
            %           ["/odom","cmd_vel","/camera/rgb/image_raw"], ...
            %           {ros2time(1.6160e+09),ros2time(1.6170e+09),ros2time(1.6180e+09)}, ...
            %           {msg1,msg2,msg3})
            %     
            %     %Close the bagfile, remove the ros2bagwriter object from memory 
            %     %and clear the associated object handle.
            %     delete(bagWriter)
            %     clear bagWriter
            %
            %   Example 3: Write Multiple Logs for Same Topic to ros2bag File
            %     %Create a ros2bagwriter object and a ros2bag file in the specified path.
            %     bagWriter = ros2bagwriter("myBag");
            %     
            %     %Write multiple logs for same topic to the ros2bag file.
            %     pointMsg1 = ros2message("geometry_msgs/Point");
            %     pointMsg1.x = 1;
            %     pointMsg2 = ros2message("geometry_msgs/Point");
            %     pointMsg2.x = 2;
            %     pointMsg3 = ros2message("geometry_msgs/Point");
            %     pointMsg3.x = 3;
            %     write(bagWriter, ...
            %           "/point", ...
            %           {1.6190e+09, 1.6200e+09,1.6210e+09}, ...
            %           {pointMsg1,pointMsg2,pointMsg3})
            %     
            %     %Close the bagfile, remove the ros2bagwriter object from memory 
            %     %and clear the associated object handle.
            %     delete(bagWriter)
            %     clear bagWriter

            if ~isscalar(ros2Message)

                validateattributes(topic, {'string', 'cell', 'char'}, ...
                    {'vector', 'nonempty'}, 'write', 'topic');
                validateattributes(ros2Message, {'cell', 'struct'}, ...
                    {'vector', 'nonempty'}, 'write', 'ros2Message');
                validateattributes(timeStamp, {'cell', 'double', 'struct'}, ...
                    {'vector', 'nonempty'}, 'write', 'timeStamp');

                if(ischar(topic) || isequal(length(topic) , 1))
                    if iscell(topic)
                        topic = topic{1};
                    end
                    topic = repmat({topic},1,length(ros2Message));
                elseif ~isequal(length(topic), length(ros2Message))
                    error(message('ros:mlros2:bag:TopicListError'))
                end

                if ~isequal(length(timeStamp), length(ros2Message))
                    error(message('ros:mlros2:bag:TimeStampListError'))
                end

                for ii = 1:length(ros2Message)
                    %Get the time stamp
                    if iscell(timeStamp)
                        ts = timeStamp{ii};
                    else
                        ts = timeStamp(ii);
                    end
                    %Get the ros message
                    if iscell(ros2Message)
                        ros2Msg = ros2Message{ii};
                    else
                        ros2Msg = ros2Message(ii);
                    end
                    %Send the current record to write
                    write(obj, topic{ii}, ts, ros2Msg);
                end
            else
                try
                    msgType = ros2Message.MessageType;
                    if ~ifMessageTypeRegistered(obj.InternalBagWriter, msgType)
                        [pathEnv, amentPrefixEnv, cleanPath, cleanAmentPath] = ros.internal.ros2.setupRos2Env(); %#ok<ASGLU>
                        registerMessageType(obj, msgType);
                    end
                    
                    if isa(timeStamp,'double')
                        timeStamp = ros2time(timeStamp);
                    end

                    write(obj.InternalBagWriter,...
                        msgType, topic, ...
                            timeStamp.sec, timeStamp.nanosec, ros2Message);

                catch ex
                    validateattributes(topic, {'string','char'}, ...
                        {'scalartext'}, 'write', 'topic');
                    validateattributes(ros2Message, {'struct'}, ...
                        {'scalar'}, 'write', 'ros2Message');
                    validateattributes(timeStamp, {'struct','double'}, ...
                        {'scalar'}, 'write', 'timeStamp');

                    newEx = MException(message('ros:mlros2:bag:Ros2bagWriteError', ...
                        topic, msgType));
                    throw(newEx.addCause(ex));
                end
            end
        end

        function path = get.Path(obj)
            % Gets the path of the bag file.
            path = getBagFilePath(obj.InternalBagWriter);
        end
        
        function numMessages = get.NumMessages(obj)
            %Gets number-of-messages written to the bag-file.
            numMessages = getNumMessages(obj.InternalBagWriter);
        end

        function startTime = get.StartTime(obj)
            %Gets end-time of all the messages written to the bag file.
            startTime = double(getStartTime(obj.InternalBagWriter))/1e9;
        end

        function endTime = get.EndTime(obj)
            %Gets end-time of all the messages written to the bag file.
            endTime = double(getEndTime(obj.InternalBagWriter))/1e9;
        end
    end
    methods (Access = ?matlab.unittest.TestCase)
        function registerMessageType(obj, ros2MessageType)
            %registerMessageType This is an internal method used to
            % register and load all dependent libraries of a message type.
            % It is called only once when ever a message type is going to be
            % written first time in a bag file.
 
            messageInfo = ros.internal.ros2.getMessageInfo(ros2MessageType);
            [cppFactoryClass , cppElementType] = ...
                ros.internal.ros2.getCPPFactoryClassAndType(ros2MessageType);
            dllPaths = ros.internal.utilities.getPathOfDependentDlls(ros2MessageType,'ros2');
            dllPaths{end + 1} = messageInfo.path;

            registerMessageType(obj.InternalBagWriter, ...
                ros2MessageType, cppFactoryClass, cppElementType, dllPaths)
        end
    end
    methods (Access = protected)
        function displayScalarObject(obj)
            displayScalarObjectWithUnits(obj);
        end
    end
end
