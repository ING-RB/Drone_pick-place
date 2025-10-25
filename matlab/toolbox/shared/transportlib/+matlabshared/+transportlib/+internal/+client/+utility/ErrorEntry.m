classdef ErrorEntry
    %ERRORENTRY contains properties that serve as entries to the ErrorRegistry
    % container

    % Copyright 2019-2020 The MathWorks, Inc.

    properties
        % Error Id
        ID (1, 1) string

        % Error message
        MessageText (1, 1) string
    end

    %% Lifetime
    methods
        function obj = ErrorEntry(varargin)
            narginchk(0, 2);
            if nargin > 0
                obj.ID = varargin{1};
            end
            if nargin > 1
                obj.MessageText = varargin{2};
            end
        end
    end
end