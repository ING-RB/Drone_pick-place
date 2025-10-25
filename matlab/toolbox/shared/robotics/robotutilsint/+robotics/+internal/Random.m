classdef Random < handle
%This class is for internal use only. It may be removed in the future.

%RANDOM Class for some creating random values.

%   Copyright 2015-2023 The MathWorks, Inc.

    properties (SetAccess = ?matlab.unittest.TestCase)
        %TimeSourceFcn - The source of the current time as function handle
        %   By default, this class uses the MATLAB now function.
        TimeSourceFcn = @now
    end

    methods
        function set.TimeSourceFcn(obj, timeSource)
        %set.TimeSourceFcn Setter function for TimeSourceFcn property
        %   The input needs to be a valid function handle. This setter
        %   can be used by unit test for dependency injection. If you
        %   do this, make sure to reset the TimeSourceFcn to its
        %   original value at the end of the test.

            validateattributes(timeSource, {'function_handle'}, {'nonempty'}, 'Random', 'TimeSourceFcn');
            obj.TimeSourceFcn = timeSource;
        end
    end

    methods
        function [numStr, num] = timeNumericString(obj, digits)
        %timeNumericString Create a randomized numeric string with fixed number of digits
        %
        %   NUMSTR = robotics.internal.Random.timeNumericString(DIGITS)
        %   creates a numeric string with a fixed number of DIGITS that
        %   is based on the current time. Since the system time is always
        %   changing, the output appears to be pseudo-random.
        %
        %   [NUMSTR, NUM] = robotics.internal.Random.timeNumericString(DIGITS)
        %   also returns the numeric value, NUM, that is used to
        %   generate the numeric string, NUMSTR. Please note that NUM
        %   might not have the required DIGITS length, since it can
        %   contain leading zeros.

            validateattributes(digits, {'numeric'}, {'real', 'positive', 'scalar', '<=', 15}, 'timeNumericString', 'digits');

            % Get fractional part of time source return
            n = rem(feval(obj.TimeSourceFcn),1);

            % Get a good amount of fractional digits as an integer.
            % All digits past 10^6 are in the milli and microsecond range,
            % thus providing enough variance for a good random source.
            n = round(n*10^(6+digits));

            % The random number is determined by taking the last digits of the integer.
            % Note that the number could have a length of less than "digits", since it
            % might contain leading zeros.
            num = rem(n, 10^digits);

            % Convert number to string and add leading zeros
            numStr = num2str(num, ['%0' num2str(digits) 'u']);
        end
    end
end
