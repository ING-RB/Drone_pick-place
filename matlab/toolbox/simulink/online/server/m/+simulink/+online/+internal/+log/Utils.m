% Copyright 2021 The MathWorks, Inc.
% Log util functions; all static functions

classdef Utils
    methods (Static, Access = public)
        function logExceptionForCallback(callback, logger, varargin)
            try
                callback(varargin{:});
            catch ex
                logger.error(getReport(ex));

                % Resource doesn't know how to handle exceptions from callbacks
                % Just rethrow
                rethrow(ex);
            end
        end  % logExceptionForCallbacks

        % TODO: add functions to get log namespaces here
    end

    methods (Access = private)
      function obj = Utils()
      end
    end
end
