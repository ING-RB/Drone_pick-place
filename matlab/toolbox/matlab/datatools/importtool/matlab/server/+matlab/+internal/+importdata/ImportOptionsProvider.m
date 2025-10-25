% This class is unsupported and might change or be removed without notice in a
% future version.

% This class is the base class for importing file types which provide
% additional options to be displayed.

% Copyright 2022 The MathWorks, Inc.

classdef ImportOptionsProvider < matlab.internal.importdata.ImportProvider

    methods
        function this = ImportOptionsProvider(filename)
            arguments
                filename (1,1) string = "";
            end

            this = this@matlab.internal.importdata.ImportProvider(filename);
        end
    end
end