classdef FixtureLiaison < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = immutable)
        RootFolder (1,1) string
    end

    properties
        Fixtures (1,:) matlab.buildtool.internal.fixtures.Fixture
    end

    methods
        function liaison = FixtureLiaison(rootFolder)
            liaison.RootFolder = rootFolder;
        end
    end
end