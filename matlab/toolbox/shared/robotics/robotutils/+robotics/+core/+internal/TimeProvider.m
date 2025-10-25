classdef (Abstract) TimeProvider < handle
    %TimeProvider Interface for time sources used in rate objects.
    %   Note that all time providers provide time (in seconds) relative to 
    %   the most recent call to RESET.
    %
    %   See also robotics.core.internal.SystemTimeProvider
    
    %   Copyright 2015-2020 The MathWorks, Inc.
    
    %#codegen
    
    properties (Abstract, SetAccess = protected)
        %IsInitialized - Indication if the time provider has been initialized
        %   Use the RESET method to initialize the time provider.
        IsInitialized
    end
    
    methods (Abstract)
        %RESET Reset the time provider
        %   This resets the initial state of the time provider. You have to
        %   call RESET before you can call any other methods on the object.
        %   This function returns whether the time provider has been
        %   successfully reset.
        success = reset(obj)
        
        %getElapsedTime Returns the elapsed time since the time provider was reset (seconds)
        %   You need to call RESET to initialize the time provider before 
        %   you can call this method.
        %   This function is not affected by time adjustments like
        %   Daylight Savings Time or leap years. Although not a strict
        %   requirement, it is preferred if the method returns
        %   monotonically increasing values.
        time = getElapsedTime(obj)
        
        %SLEEP Sleep for a number of seconds 
        %   The internal mechanism for achieving this sleep behavior is
        %   dependent on the type of time source.
        %   You need to call RESET to initialize the time provider before 
        %   you can call this method.
        sleep(obj, seconds)
    end
    
end
