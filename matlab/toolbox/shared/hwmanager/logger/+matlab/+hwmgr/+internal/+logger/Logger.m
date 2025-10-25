classdef Logger < handle
    % LOGGER The Logger is intended for MathWorks internal use only and is
    % subject to change at anytime without warning. This class provides an
    % interface for generating log output to files and the MATLAB Command
    % Window.

    %Copyright 2016-2021 The MathWorks, Inc.

    properties(Access = 'private')
        %LogFileHandler - A File Handler used to manage the output stream
        LogFileHandler
        %CurrentLogLevel - the default log level of the logger
        CurrentLogLevel
    end

    properties(Access = 'public')
        %ConsoleEnable - A logical flag that represents whether or not
        %   console output is active
        ConsoleEnable = false;
        %FileEnable - A logical flag that represents whether or not file
        %   output is active
        FileEnable = true;
    end

    properties(GetAccess = 'public', SetAccess = 'immutable')
        %FilePath -A string representing the full path to the logger's
        %   output file
        FilePath
    end

    properties(Constant)
        SubsystemNamespace = 'com.mathworks.hwservices.logging';
    end


    methods
        function set.ConsoleEnable(obj, enableFlag)

            validateattributes(enableFlag, {'logical'}, {'scalar'});
            obj.ConsoleEnable = enableFlag;

        end

        function set.FileEnable(obj, enableFlag)

            validateattributes(enableFlag, {'logical'}, {'scalar'});
            obj.FileEnable = enableFlag;

        end
    end

    methods(Access = 'public')
        function obj = Logger(filePath)
            %check if path is relative if it is convert to absolute
            absolutePath = obj.validateFilePath(filePath);
            obj.FilePath = absolutePath;

            %get an instance of the File handler
            obj.LogFileHandler = matlab.hwmgr.internal.logger.LogFileHandler(filePath, obj.SubsystemNamespace);

            %configure the logger
            obj.configureLogger();
        end

        function log(obj, msg)
            %LOG(OBJ, MSG) - outputs message to the loggers enabled
            %output locations. By default output is only sent to the
            %log file.

            validateattributes(msg, {'char'}, {'nonempty'});
            if(obj.ConsoleEnable)
                s1 = datestr(datetime);
                disp(['(', s1, ') ', msg]);
            end

            if(obj.FileEnable)
                obj.LogFileHandler.log(obj.CurrentLogLevel, msg);
            end

        end

        function delete(~)
        end

    end

    methods(Access = 'private')

        function absoluteFilePath = validateFilePath(~, filePath)
            %VALIDATEFILEPATH -validates and sets the fullPath of the Logger.
            validateattributes(filePath, {'char'}, {'nonempty'});

            %check if path is empty. If so, reject and require absolute path
            try
                fid = fopen(filePath, 'a');

            catch
                fid = -1;
            end

            %fid will be -1 if the file could not be opened
            if(fid == -1)
                error('hwmanager:logger:UnusableFilePath', ...
                    'File path provided could not be opened or created.');
            else
                [~, fileAttributes] = fileattrib(filePath);
                absoluteFilePath = fileAttributes.Name;
                fclose(fid);
            end

        end

        function configureLogger(obj)
            %CONFIGURELOGGER(obj) - set the default log level
            obj.CurrentLogLevel = matlab.hwmgr.internal.logger.LogFileHandler.INFO;
            obj.LogFileHandler.setLevel(obj.CurrentLogLevel);
        end

        function close(obj)
            if ~isempty(obj.LogFileHandler)
                obj.LogFileHandler.close();
            end
        end
    end

end

% LocalWords:  utils hwservices filepath fid hwmanager
