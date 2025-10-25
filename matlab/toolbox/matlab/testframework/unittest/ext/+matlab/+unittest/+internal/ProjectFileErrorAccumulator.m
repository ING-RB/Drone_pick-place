classdef ProjectFileErrorAccumulator < matlab.unittest.internal.ProjectFileErrorHandler & handle
    %

    % Copyright 2022 The MathWorks, Inc.

    properties (SetAccess=private)
        Errors = struct("Exception",{}, "Filename",{});
    end

    methods
        function handle(handler, exception, filename)
            handler.Errors(end+1) = struct("Exception",exception, "Filename",filename);
        end
    end
end

