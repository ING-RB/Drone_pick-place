function varargout = profile(varargin)
%PROFILE Profile execution time for function
%   PROFILE ON starts the profiler and clears previously recorded
%   profile statistics.
%
%   PROFILE takes the following options:
%
%      -TIMER CLOCK
%         This option specifies the type of time to be used in profiling.
%         If CLOCK is 'cpu', the profiler measures the compute time across
%         all threads.   Otherwise the profiler measures wall clock time.
%         For example, the cpu time for the PAUSE function is very short,
%         but wall clock time accounts for the actual time spent paused.
%         If CLOCK is 'real', the profiler measures the wall clock time
%         reported by the operating system.  This is the most
%         computationally expensive measurement and, therefore, has the
%         most impact on the performance of profiled code. If CLOCK is
%         'performance' (the default value), the profiler uses the wall
%         clock time reported by the clock that the operating system uses
%         to measure performance. If CLOCK is 'processor', the profiler
%         uses the wall clock time directly from the processor.  This
%         measurement may be inconsistent if power savings options are
%         enabled.
%
%      -HISTORY
%         If this option is specified, MATLAB records the exact
%         sequence of function calls so that a function call
%         history report can be generated.  NOTE: MATLAB will
%         not record more than 5000000 function entry and exit events
%         (see -HISTORYSIZE below).  However, MATLAB will continue
%         recording other profiling statistics after this limit has
%         been reached.
%
%      -NOHISTORY
%         If this option is specified, MATLAB will disable history
%         recording.  All other profiler statistics will continue
%         to be collected.
%
%      -TIMESTAMP
%         If this option is specified, MATLAB records the exact
%         sequence of function calls so that a function call
%         history report can be generated similar to the -HISTORY option
%         above. However, this report will also include a
%         timestamp for each entry and exit event.
%
%      -HISTORYSIZE SIZE
%         This option specifies the length of the function call history
%         buffer.  The default is 5000000.
%
%      Options may appear either before or after ON in the same command,
%      but they may not be changed if the profiler has been started in a
%      previous command and has not yet been stopped.
%
%   PROFILE OFF stops the profiler.
%
%   PROFILE VIEWER stops the profiler and opens the graphical profile browser.
%   The file listing at the bottom of the function profile page shows four
%   columns to the left of each line of code.
%         Column 1 (red) is total time spent on the line in seconds.
%         Column 2 (blue) is number of calls to that line.
%         Column 3 is the line number
%
%   PROFILE RESUME restarts the profiler without clearing
%   previously recorded function statistics.
%
%   PROFILE CLEAR clears all recorded profile statistics.
%
%   S = PROFILE('STATUS') returns a structure containing
%   information about the current profiler state.  S contains
%   these fields:
%
%       ProfilerStatus   -- 'on' or 'off'
%       DetailLevel      -- 'mmex'
%       Timer            -- 'cpu', 'real', 'performance', or 'processor'
%       HistoryTracking  -- 'on', 'off', or 'timestamp'
%       HistorySize      -- 5000000 (default)
%
%   STATS = PROFILE('INFO') stops the profiler and returns
%   a structure containing the current profiler statistics.
%   STATS contains these fields:
%
%       FunctionTable    -- structure array containing stats
%                           about each called function
%       FunctionHistory  -- function call history table
%       ClockPrecision   -- precision of profiler time
%                           measurement
%       ClockSpeed       -- Estimated clock speed of the cpu (or 0)
%       Name             -- name of the profiler (i.e. MATLAB)
%
%   The FunctionTable array is the most important part of the STATS
%   structure. Its fields are:
%
%       FunctionName     -- function name, includes subfunction references
%       FileName         -- file name is a fully qualified path
%       Type             -- MATLAB function, MEX-function
%       NumCalls         -- number of times this function was called
%       TotalTime        -- total time spent in this function
%       Children         -- FunctionTable indices to child functions
%       Parents          -- FunctionTable indices to parent functions
%       ExecutedLines    -- array detailing line-by-line details (see below)
%       IsRecursive      -- is this function recursive? boolean value
%       PartialData      -- did this function change during profiling?
%                           boolean value
%
%   The ExecutedLines array has several columns. Column 1 is the line
%   number that executed. If a line was not executed, it does not appear in
%   this matrix. Column 2 is the number of times that line was executed,
%   and Column 3 is the total spent on that line. Note: The sum of Column 3
%   does not necessarily add up to the function's TotalTime.
%
%   If you want to save the results of your profiler session to disk, use
%   the PROFSAVE command.
%
%   Examples:
%
%       profile on
%       plot(magic(35))
%       profile viewer
%       profsave(profile('info'),'profile_results')
%
%       profile on -history
%       plot(magic(4));
%       p = profile('info');
%       for n = 1:size(p.FunctionHistory,2)
%           if p.FunctionHistory(1,n)==0
%               str = 'entering function: ';
%           else
%               str = ' exiting function: ';
%           end
%           disp([str p.FunctionTable(p.FunctionHistory(2,n)).FunctionName]);
%       end
%
%   See also PROFSAVE, PROFVIEW.

%   Copyright 1984-2023 The MathWorks, Inc.

import matlab.internal.capability.Capability
import matlab.internal.profiler.cli.ProfileCLIAction
import matlab.internal.profiler.cli.ProfileCLIOption

profParser = matlab.internal.profiler.cli.ProfileArgParser();

%% Profile Actions %%

profParser.addAction('on', ProfileCLIAction.On);
profParser.addAction('off', ProfileCLIAction.Off);
profParser.addAction('resume', ProfileCLIAction.Resume);
profParser.addAction('clear', ProfileCLIAction.Clear);
profParser.addAction('reset', ProfileCLIAction.Reset);
profParser.addAction('viewer', ProfileCLIAction.Viewer);
profParser.addAction('status', ProfileCLIAction.Status);
profParser.addAction('info', ProfileCLIAction.Info);
profParser.addAction('report', ProfileCLIAction.Report);

%% Profile Options %%

% MATLAB Default
profParser.addOptionWithArg('detail', ProfileCLIOption.Detail, ...
    'LEVEL', {'mmex', 'builtin'});
profParser.addOptionWithArg('timer', ProfileCLIOption.Timer, ...
    'CLOCK', {'none', 'cpu', 'real', 'performance', 'processor'});
profParser.addOptionWithArg('remove_overhead', ProfileCLIOption.RemoveOverhead, ...
    'ON/OFF', {'off', 'on'});
profParser.addOptionWithArg('historysize', ProfileCLIOption.HistorySize, ...
    'SIZE', @getIntegerOptionArg);
profParser.addOption('nohistory', ProfileCLIOption.NoHistory);
profParser.addOption('history', ProfileCLIOption.History);
profParser.addOption('timestamp', ProfileCLIOption.TimeStamp);
profParser.addOption('nomemory', ProfileCLIOption.NoMemory);
profParser.addOption('callmemory', ProfileCLIOption.CallMemory);
profParser.addOption('memory', ProfileCLIOption.Memory);

% PCT Specific
profParser.addOptionWithArg('mpiloglevel', ProfileCLIOption.MpiLogLevel, ...
    'LOGLEVEL', {'full', 'simplified', 'off'});
profParser.addOption('nopool', ProfileCLIOption.NoPool);
profParser.addOption('pool', ProfileCLIOption.Pool);

%% Parsing and Action Execution %%

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

narginchk(1, inf);

% Hide error stack for parsing errors.
try
    [action, configOpts] = profParser.parse(varargin{:});
catch e
    throwAsCaller(e);
end

% TODO(g2864775): Wrap this code in a try/catch using an umbrella exception
% for internal profiling errors.
profilerService = matlab.internal.profiler.ProfilerService.getInstance();

% Options are permanently set for the duration of the MATLAB session.
if ~isempty(configOpts)
    profilerService.configureProfilers(configOpts);
end

[varargout{1:nargout}] = iExecuteProfileCLIAction(profilerService, action);

end

%% Internal Functions %%

function varargout = iExecuteProfileCLIAction(profilerService, action)
    import matlab.internal.capability.Capability
    import matlab.internal.profiler.cli.ProfileCLIAction

    switch action
        case ProfileCLIAction.On
            iAddFileFilters();
            profilerService.turnOnProfiling();

        case ProfileCLIAction.Off
            profilerService.turnOffProfiling();

        case ProfileCLIAction.Resume
            iAddFileFilters();
            profilerService.resumeProfiling();

        case ProfileCLIAction.Clear
            profilerService.clearProfilingData();

        case ProfileCLIAction.Reset
            profilerService.resetProfiling();

        case ProfileCLIAction.Report
            profreport

        case ProfileCLIAction.Viewer
            profilerService.turnOffProfiling();

            Capability.require([Capability.LocalClient]);
            matlab.internal.profileviewer.invokeProfiler();

        case ProfileCLIAction.Status
            varargout{1} = profilerService.getProfilingStatus();

        case ProfileCLIAction.Info
            varargout{1} = profilerService.getProfilingData();

        case ProfileCLIAction.None
            % Nothing to do

        otherwise
            error(message('MATLAB:profiler:UnknownInputAction', upper(char(action))));
    end
end

function iAddFileFilters()
    files = {...,
        'profile.m', ...
        'profview.m', ...
        'profsave.m', ...
        'profreport.m', ...
        ... The next three files are kept as they were in the original profile
        ... implementation, but these should be revisited as they are too broad.
        'connector.internal.fevalJSON', ...
        'connector.internal.fevalMatlab', ...
        'onCleanup', ...
        'matlab.internal.profiler.cli.ProfileArgParser', ...
        'matlab.internal.profiler.cli.ProfileCLIOption', ...
        'matlab.internal.profiler.cli.ProfileCLIAction', ...
        };
    matlab.internal.profiler.addFileFilters(files);
end

% Validation Functions

function value = getIntegerOptionArg(optionName, value)
    if ischar(value)
        value = str2double(value);
    end
    if isnan(value) || value < 0 || mod(value, 1)
        error(message('MATLAB:profiler:NonIntegerInputArgument', upper(optionName)));
    end
end
