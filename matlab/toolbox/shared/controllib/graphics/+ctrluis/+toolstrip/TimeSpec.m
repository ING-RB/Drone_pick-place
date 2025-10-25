classdef TimeSpec
   %TIMESPEC Class representing uniform time vector parameters.
   
   % Copyright 2013 The MathWorks, Inc.
   
   properties
      % Start time 
      StartTime
      
      % Onset time Lag for an event 
      EventOnsetLag % event happens at t = StartTime+EventOnsetLag
      
      % Sampling interval
      SampleTime
      
      % End time
      EndTime
   end
   
   methods
      function this = TimeSpec(t0,tonset,ts,tend)
         % Constructor.
         if nargin==0
            t0 = 0;
            tonset = 0;
            tend = 10;
            ts = 1;
         end
         this.StartTime = t0;
         this.EventOnsetLag = tonset;
         this.SampleTime = ts;
         this.EndTime = tend;
      end
      
      function t = getTimeVector(this)
         % Construct time vector based on start, end and sample time.
         Ts = this.SampleTime;
         t = (this.StartTime:Ts:this.EndTime)';
         t = round(t/Ts)*Ts;
      end
   end
end
