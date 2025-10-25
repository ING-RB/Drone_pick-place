classdef DataPump < handle
    %DATAPUMP Transfer data out of a buffer at a fixed rate.
    %
    % Usage:
    %    dp = matlabshared.asyncio.buffer.DataPump(buffer, sink, count, period) 
    %
    %    BUFFER is a matlabshared.asyncio.buffer.Buffer. The pump moves
    %    data from the buffer to the DATASINK
    %
    %    DATASINK is a matlabshared.asyncio.buffer.DataSink
    %
    %    COUNT is the amount of data to move per PERIOD.
    
    %    PERIOD is the the maximum amount of time to wait before COUNT
    %    elements are sent from the BUFFER to the DATASINK.
    %
    % Example:
    %   buffer = matlabshared.asyncio.buffer.Buffer();
    %   sink = matlabshared.asyncio.buffer.DataSink()
    %   dp = matlabshared.asyncio.buffer.DataPump(buffer, sink, 100, 0.100);
    %
    %   data = linspace(-1, 1, 100/0.1)';
    %
    %   % prefill the buffer
    %   buffer.write(data)
    %   dp.start();
    %   % add data while the pump is active
    %   buffer.write(3*data);
    %   while dp.NumElementsInBuffer > 0
    %      pause(0.100);
    %   end
    %   dp.stop();
    %
    %   numElementsInBuffer = dp.NumElementsInBuffer; % 0  
    %   numElementsInSink = dp.NumElementsInSink;     % 2 * 100/.1
    %
    %   clear buffer sink dp;
    %
    % Notes: none
    %
    % Copyright 2018 The MathWorks, Inc.   
    
    properties
        % The maximum amount of time to wait before the pump sends data
        % from the buffer to the sink; 0.002 is the minimum period of the
        % internal.IntervalTimer; 0.004 indicates that we want the timer to
        % check at least twice as often as it needs to trigger
        OutputPeriod (1, 1) double {mustBePositive, mustBeFinite, mustBeNonNan, ...
                                    mustBeGreaterThanOrEqual(OutputPeriod, 0.004)} = 0.1
                                
        % Nominally, the number of elements to send, if available, on each
        % timer tick, from the buffer to the data sink.
        OutputCount (1, 1) double {mustBePositive, mustBeFinite, mustBeNonNan} = 1
    end
    
    properties (Dependent)
        % The number of elements available in the data buffer
        NumElementsInBuffer (1, 1) double {mustBeNonnegative}
        
        % The total number of elements written to the data sink
        NumElementsInSink (1, 1) double {mustBeNonnegative}
    end
    
    properties (Hidden, Transient)
        % Action to take after stopping the pump
        StopAction (1, 1) matlabshared.asyncio.buffer.internal.enum.DataPumpStopAction = "None"            
        
        % The number of times the timer executes (and checks for data
        % available in the pump's buffer). Can also be thought of as a
        % "greed" factor because a pump that contains a lot more data than
        % the OutputCount data will write it to the sink this many times
        % more often.
        NumTimerPeriodsPerOutputPeriod (1, 1) double {mustBePositive} = 10    
        
        % The number of elements to leave in the buffer so as to ensure
        % glitch-free operation (by default, when the OutputCount reaches
        % the specified level, all data is extracted from the buffer)
        Occupancy (1, 1) double {mustBeNonnegative} = 0        
    end
    
    properties (Hidden, Dependent)
        % Computed average output period based on measured average timer
        % period
        AverageOutputPeriod (1, 1) double {mustBeNonnegative}

        % Measured average timer period
        AverageTimerPeriod (1, 1) double {mustBeNonnegative}
        
        % Maximum output period attainable given the standard number of
        % timer executions per output period
        % (NumTimerPeriodsPerOutputPeriod)
        OutputPeriodThreshold (1, 1) double {mustBeNonnegative} 
    end
    
    methods
        function obj = DataPump(buffer, dataSink, outputCount, outputPeriod)
            % DATAPUMP Accepts data at irregular intervals and periodically
            % emits OUTPUTCOUNT elements at a maximum interval of
            % OUTPUTPERIOD. Accepts any data-type that can be represented
            % as a MATLAB DATA ARRAY (MDA)
            %
            % OBJ = DATAPUMP(BUFFER, DATASINK, OUTPUTCOUNT, OUTPUTPERIOD)
            %
            % Inputs:            
            % BUFFER - A container for data (may be any data-type that can
            % be represented as a MDA). 
            %
            % DATASINK - The destination of the data sent from the buffer
            % by the pump. Typically, a data sink is written by the
            % end-user (note that a data sink can, and sometimes should,
            % contain another buffer; this buffer can be passed to another
            % pump).
            %
            % OUTPUTCOUNT - Amount of data to emit each output period.
            %
            % OUTPUTPERIOD - Maximum time to wait, in seconds, before
            % sending data from the buffer to the sink.
            %
            %            
            % See also: matlabshared.asyncio.Buffer.Buffer,
            % matlabshared.asyncio.Buffer.DataSink
            
            narginchk(4, 4)            
            
            obj.Buffer = buffer; 
            obj.DataSink = dataSink;
            obj.OutputCount = outputCount;            
            obj.OutputPeriod = outputPeriod;            
            
            try
                obj.initializeTimer();
            catch e
               throwAsCaller(e);
            end   
        end
        
        function delete(obj)
            if obj.isvalid
                obj.stop();
                obj.uninitializeTimer();
            end
        end
    end
    
    %% Set/Get
    
    methods
        function timerPeriod = get.TimerPeriod(obj)
            outputPeriod = obj.OutputPeriod;
            if outputPeriod <= obj.OutputPeriodThreshold
                timerPeriod = obj.MinimumTimerPeriod;
            else
                timerPeriod = round(outputPeriod/obj.NumTimerPeriodsPerOutputPeriod, 3);
            end            
        end
        
        function set.TimerPeriod(obj, period)
            obj.IntervalTimer.Period = period;
        end
        
        function count = get.NumElementsInBuffer(obj)
            count = obj.Buffer.NumElementsAvailable;
        end
        
        function totalHandled = get.NumElementsInSink(obj)
            totalHandled = obj.DataSink.TotalElementsHandled;
        end
        
        function averageTimerPeriod = get.AverageTimerPeriod(obj)
            averageTimerPeriod = round(obj.IntervalTimer.AveragePeriod, 3);
        end
        
        function averageOutputPeriod = get.AverageOutputPeriod(obj)
            averageOutputPeriod = round(obj.IntervalTimer.AveragePeriod * obj.NumTimerPeriodsPerOutputPeriod, 3);
        end
        
        function outputPeriodThreshold = get.OutputPeriodThreshold(obj)
            outputPeriodThreshold = obj.MinimumTimerPeriod * obj.NumTimerPeriodsPerOutputPeriod;
        end
        
        function set.NumTimerPeriodsPerOutputPeriod(obj, numTimerPeriodsPerOutputPeriod)
            obj.NumTimerPeriodsPerOutputPeriod = numTimerPeriodsPerOutputPeriod;
            obj.TimerPeriod = obj.TimerPeriod;
        end
    end
    
    %% Operations
    
    methods
        function start(obj)
            % START Prepares the data sink to receive data and starts the
            % timer counting.
            if obj.isvalid
                obj.DataSink.open();
                start(obj.IntervalTimer);
            end
        end
        
        function stop(obj)
            % STOP Turn off the timer, handle remaining data in the pump,
            % as necessary, and tell the sink that no more data is
            % expected.
            if obj.isvalid
                stop(obj.IntervalTimer);
                
                switch obj.StopAction
                    case "Drain"
                        obj.drain();
                    case "Flush"
                        obj.flush();
                end
                
                obj.DataSink.close();
            end
        end
    end
    
    %% Buffer
    
    properties (Hidden, Transient)
        Buffer (1, :) matlabshared.asyncio.buffer.Buffer
        DataSink (1, :) matlabshared.asyncio.buffer.DataSink
    end
    
    methods (Access = private)
        function data = read(obj, count)
            % READ retrieve data from the pump's buffer            
            narginchk(1, 2)
            
            if nargin < 2
                data = obj.Buffer.read();
            else
                data = obj.Buffer.read(count);
            end
        end
        
        function drain(obj)
            % DRAIN Transfer any data remaining, from the buffer, to the
            % sink.            
            if obj.Buffer.NumElementsAvailable > 0
                obj.DataSink.handleData(obj.read())
            end            
        end
        
        function flush(obj)
            % FLUSH Remove all data remaining in the buffer 
            obj.Buffer.flush()
        end         
    end    
    
    %% Timer
    
    properties(Constant, Access = private)
        % Minimum timer period supported by the IntervalTimer
        MinimumTimerPeriod = 0.002 
    end
    
    properties (Transient, Access = private)
        IntervalTimer (1, :) internal.IntervalTimer  
        
        % Listener for the 'Executing' event issued by the session timer
        TimerListener   
    end
    
    properties (Dependent, Access = private)
        TimerPeriod (1, 1) double {mustBeNonnegative, mustBeFinite, mustBeNonNan}
    end    
    
    methods (Access = private)
        function initializeTimer(obj)
            narginchk(1,1)

            obj.IntervalTimer = internal.IntervalTimer(obj.TimerPeriod);
            obj.TimerListener = event.listener(obj.IntervalTimer,...
                                               'Executing',...
                                               @obj.execute);
        end        
        
        function uninitializeTimer(obj)
            if isempty(obj.IntervalTimer) || ~isvalid(obj.IntervalTimer)
                return
            end
            
            delete(obj.TimerListener);
        end
        
        function execute(obj, ~, ~) % evtSrc, evtData
            % Check whether the buffer contains at least the number of
            % elements specified by the output count and, if it does, send
            % these elements to the data sink. Note that when the number of
            % elements in the buffer greatly exceeds the output count, the
            % timer will send data every _timer_ period, which is typically
            % a bigger than the user-specified _output_ period.
            
            if obj.Buffer.NumElementsAvailable >= obj.OutputCount + obj.Occupancy
                obj.DataSink.handleData(obj.read(obj.OutputCount));
            end
        end         
    end
    
    %% Save / Load  
    methods (Hidden, Static)
        function bc = loadobj(s)
            bc = s;
            delete(bc);
            warning(message('testmeaslib:AsyncioBuffer:CannotSaveDataPump'))
        end
    end     
    
end

