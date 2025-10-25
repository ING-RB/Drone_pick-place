classdef ProfileCLIOption
    % ProfileCLIOption Enumeration with the options supported by profile.
    %   Not all options are user-visible.

    %   Copyright 2022 The MathWorks, Inc.

    enumeration
        History
        NoHistory
        Detail
        TimeStamp
        Timer
        HistorySize
        CallMemory
        Memory
        NoMemory
        RemoveOverhead
        NoPool
        Pool
        MpiLogLevel
        None
    end

    methods
        function value = getOptionValue(obj, arg)
            % Maps an option string, and its argument (if exists), to a
            % matlab.internal.profiler.interface.ConfigOption.
            arguments
                obj
                arg = '' % Argument not necessarily a string.
            end

            import matlab.internal.profiler.types.*
            import parallel.internal.profiler.types.*
            import matlab.internal.profiler.cli.ProfileCLIOption

            % This is provided as a NO-OP option with consistent type.
            value = matlab.internal.profiler.types.NullOption;

            % Matlab options.
            switch obj
                case ProfileCLIOption.History
                    value = HistoryTracking.On;
                case ProfileCLIOption.NoHistory
                    value = HistoryTracking.Off;
                case ProfileCLIOption.TimeStamp
                    value = HistoryTracking.TimeStamp;
                case ProfileCLIOption.Detail
                    switch(arg)
                        case 'builtin'
                            value = LogLevel.Builtin;
                        case 'mmex'
                            value = LogLevel.Mmex;
                    end
                case ProfileCLIOption.Timer
                    switch(arg)
                        case 'none'
                            value = Timer.None;
                        case 'cpu'
                            value = Timer.Cpu;
                        case 'real'
                            value = Timer.Real;
                        case 'performance'
                            value = Timer.Performance;
                        case 'processor'
                            value = Timer.Processor;
                    end
                case ProfileCLIOption.HistorySize
                    value = HistorySize(arg);
                case ProfileCLIOption.CallMemory
                    value = MemoryLogging.CallMemory;
                case ProfileCLIOption.Memory
                    value = MemoryLogging.On;
                case ProfileCLIOption.NoMemory
                    value = MemoryLogging.Off;
                case ProfileCLIOption.RemoveOverhead
                    switch arg
                        case 'on'
                            value = RemoveOverhead.On;
                        case 'off'
                            value = RemoveOverhead.Off;
                    end
            end

            % PCT options. If PCT is not installed the NullOption is
            % returned and profiling can carry on without throwing error.
            if matlab.internal.parallel.isPCTInstalled
                switch obj
                    case ProfileCLIOption.Pool
                        value = PoolProfilerState.On;
                    case ProfileCLIOption.NoPool
                        value = PoolProfilerState.Off;
                    case ProfileCLIOption.MpiLogLevel
                        switch arg
                            case 'full'
                                value = MpiLogLevel.Full;
                            case 'simplified'
                                value = MpiLogLevel.Simplified;
                            case 'off'
                                value = MpiLogLevel.Off;
                        end
                end
            end
        end
    end
end