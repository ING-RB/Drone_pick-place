classdef AppArgumentException < appdesigner.internal.appalert.TrimmedException
    %APPARGUMENTEXCEPTION Captures App Designer app argument error information
    %   An AppArgumentException decorates the actual MException thrown by
    %   the app when it is run with arguments that cause errors.
    %   It provides a client appropriate message for the Run Button
    %   infrastructure
    
    % Copyright 2017-2021 The MathWorks, Inc.
    
    properties
        % defines line for TrimmedException
        ErrorLineInApp = 1;
    end
    
    methods
        function obj = AppArgumentException(originalException)
            
            % Call super constructor to setup the identifier and
            % message properties using the otherException
            obj@appdesigner.internal.appalert.TrimmedException(originalException);
            
            obj.message = obj.cleanMessageForClient(originalException.message);            
        end
        
        function report = getReport(obj, varargin)
            % STACK = GETREPORT(OBJ, VARARGIN) This method overrides the
            % inherited GETREPORT method from TrimmedException.
            
            % Before returning the report from MException, need to reset
            % the type to that of the original exception so that the report
            % message is correct. This is necessary because the type gets
            % modified when "throw" is executed (g1484207).
            obj.type = obj.OriginalException.type;
            report = obj.message;
        end
    end
end

