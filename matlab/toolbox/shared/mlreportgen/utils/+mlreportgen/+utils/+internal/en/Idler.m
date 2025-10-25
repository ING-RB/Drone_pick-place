classdef Idler< handle
% Object that idles until told to stop idling or until a specified
% amount of time has passed.
%
% Idler methods:
%   Idler       - Creates an instance of an idler
%   startIdling - Starts idling for up to a specified time
%   stopIdling  - Stops idling

     
    %   Copyright 2019 The MathWorks, Inc.

    methods
        function out=Idler
            % Idler Creates idler instance
        end

        function out=startIdling(~) %#ok<STOUT>
            % startIdling Cause the idler to start idling
            % status = startIdling(idler, timeout) causes the idler to
            % idle until its stopIdling method is called or until the
            % specified maximum idle time has elapsed. This method 
            % returns true if it stops idling before the maximum idle
            % time has elapsed; otherwise, false.
        end

        function out=stopIdling(~) %#ok<STOUT>
            % stopIdling Causes the idler to stop idling.
        end

    end
end
