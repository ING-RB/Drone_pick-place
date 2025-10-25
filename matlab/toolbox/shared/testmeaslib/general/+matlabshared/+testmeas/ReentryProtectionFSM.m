classdef ReentryProtectionFSM < handle
%REENTRYPROTECTIONFSM provides a mechanism to protect against Reentrancy.
%
%   It registers methods for protection with this constructor, enables
%   protection when setupReentryProtection is called and cleans up the state
%   on completion of the registered method, whether normal or exception.
%
%   How to use?
%   1. Create an object of ReentryProtectionFSM as a property of your class.
%
%   properties
%       ReentryProtector matlabshared.testmeas.ReentryProtectionFSM
%   end
%
%   2. Construct the object with a string array of methods to be protected.
%
%   obj.ReentryProtector =
%   matlabshared.testmeas.ReentryProtectionFSM(["read", "write"])
%
%   3. Write the following as the first snippet of code in the method. Once 
%   this call completes, rest of the method body is protected against 
%   Reentrancy.
%
%   [stateCleanup, err] = setupReentryProtection(obj.ReentryProtector, <method name>)
%   if ~isempty(err)
%       return
%   end
%
%   Example:
%   1. obj.ReentryProtector =
%   matlabshared.testmeas.ReentryProtectionFSM(["read", "write"])
%   2. In read:
%   [stateCleanup, err] = setupReentryProtection(obj.ReentryProtector,
%   "read")
%   In write:
%   [stateCleanup, err] = setupReentryProtection(obj.ReentryProtector,
%   "write")
%   3. Truncate the call by using the "err" string
%   if ~isempty(err)
%       return
%   end
%   (OR)
%   if err == "Reentrancy Prohibited"
%       return
%   end
%
%   Details on state machine:
%   After construction obj.ReentrancyProtector =
%   matlabshared.testmeas.ReentryProtectorFSM(["read", "write"]);
%   ----------------
%   read  | "DONE"
%   ----------------
%   write | "DONE"
%   ----------------
%
%   After calling [stateCleanup, err] = setupReentryProtection(obj.ReentryProtector, "read")
%   as the first line in read method,
%   ----------------
%   read  | "RUNNING"
%   ----------------
%   write | "DONE"
%   ----------------
%
%   After completion of read method, whether normal or through exception,
%   ----------------
%   read  | "DONE"
%   ----------------
%   write | "DONE"
%   ----------------
%
%   Scenarios of no protection:
%   If default constructed, no protection is provided.
%   If setupReentryProtection is called without registration in constructor,
%   no protection is provided.

%   Copyright 2024 The MathWorks, Inc.

    properties (Access = 'private')
        StateDictionary dictionary
    end

    methods (Access = public)
        function obj = ReentryProtectionFSM(varargin)
            if 0 == nargin
                % No protection
                return;
            end
            assert(nargin == 1, "testmeaslib:ReentryProtectionFSM:maxrhs", "ReentryProtectionFSM: expected one string or string array of method names to be protected against Reentrancy");

            methods = varargin{1};
            assert(isstring(methods) && (isscalar(methods) || isvector(methods)), "testmeaslib:ReentryProtectionFSM:InvalidMethodType", "ReentryProtectionFSM: methods input for registration is expected to be a scalar or vector string.");
            stateValues = repmat("DONE", 1, length(methods));
            obj.StateDictionary = dictionary(methods, stateValues);
        end

        function [stateCleanFcn, err] = setupReentryProtection(obj, method)
        % varargout is needed to supply an onCleanup function to the
        % caller.

            assert(nargin == 2, "testmeaslib:ReentryProtectionFSM:Only2Inputs", "setupReentryProtection: needs exactly two inputs, object and method name");
            assert(nargout == 2, "testmeaslib:ReentryProtectionFSM:Only2Outputs", "setupReentryProtection: need exactly two outputs, one for state cleanup and another for error status");
            assert(isstring(method) && isscalar(method), "testmeaslib:ReentryProtectionFSM:InvalidMethodTypeForSetupReentryProtection", "setupReentryProtection: method input is expected to be a scalar string");

            % No state cleanup by default. No err by default.
            stateCleanFcn = [];
            err = string.empty();
            if ~isConfigured(obj.StateDictionary) || ~isKey(obj.StateDictionary, method)
                % FSM itself is not configured (OR)
                % Method not registered in constructor.
                % Hence no protection
                return;
            end
            if isState(obj, method, "RUNNING")
                % Reentrancy detected. No cleanup required. Set error and
                % exit.
                err = "Reentrancy Prohibited";
                return;
            end
            % No Reentrancy. Provide state cleanup. No error.
            stateCleanFcn = onCleanup(@()stateCleanup(obj, method));
            setState(obj, method, "RUNNING");
        end
    end

    methods (Access = private)
        function setState(obj, method, state)
            obj.StateDictionary(method) = state;
        end

        function status = isState(obj, method, state)
            status = (obj.StateDictionary(method) == state);
        end

        function stateCleanup(obj, method)
            setState(obj, method, "DONE");
        end
    end
end

% LocalWords:  ReentryProtection FSM Reentrancy
