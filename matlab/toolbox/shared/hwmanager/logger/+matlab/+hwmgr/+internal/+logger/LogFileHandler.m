classdef LogFileHandler < handle
    %LOGFILEHANDLER handler to log file. Provides an interface to log data from
    %MATLAB.

    %Copyright 2021 The MathWorks, Inc.

    properties (Constant)
        ALL = 1;
        INFO = 2;
        WARN = 3
        ERROR = 4;
    end

    properties
        %CurrentLevel- log level for logger
        CurrentLevel
        %LogFile- handle to the actual log file
        LogFile
    end

    properties(Access = private)
        %NAMESPACE to print in the logs
        Namespace
        %LEVELSTR strings corresponding to levels
        LevelStr = {'ALL', 'INFO', 'WARN', 'ERROR'};
    end

    methods
        function obj = LogFileHandler(logFile, namespace)
            %LOGFILEHANDLER constructor
            obj.LogFile = logFile;
            obj.Namespace = namespace;
        end

        function setLevel(obj, level)
            %SETLEVEL(OBJ, LEVEL) setter for CurrentLevel - initializes log level
            obj.CurrentLevel = level;
        end

        function set.LogFile(obj, logFile)
            %SET.LOGFILE set log file that data should be added to
            [fid, msg] = fopen(logFile, 'a');

            if(fid < 0)
                error(['Error while opening log file: ' msg]);
            end
            fclose(fid);

            obj.LogFile = logFile;
        end

        function log(obj, level, msg)
            %LOG appends msg to log file, along with timestamp and log level
            try
                fid = fopen(obj.LogFile, 'a');
                fprintf(fid, '%s %s\n%s: %s\n',...
                    datestr(now, 'mmm dd, yyyy HH:MM:SS AM'),...
                    obj.Namespace,...
                    char(obj.LevelStr(level)), msg);
                fclose(fid);
            catch %ignore
            end
        end
    end
end