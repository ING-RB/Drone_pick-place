% This class is unsupported and might change or be removed without notice in a
% future version.

% This class is the abstract base class for file-specific importer functionality
% in the Import Tool

% Copyright 2022 The MathWorks, Inc.

classdef Importer < handle

    properties
        % Filename being imported
        FileName (1,1) string

        % Properties related to the data source
        DataSourceProps

        % RulesStrategy for the imported file type
        RulesStrategy

        % Identifier for the imported file type
        Identifier (1,1) string
    end

    events
        DataChange
    end

    methods(Abstract, Access = public)
        % Implementations must implement getState, setState
        state = getState(this)
        setState(this, state)
    end

    methods
        function this = Importer(dataSource)
            arguments
                dataSource = struct();
            end

            this.DataSourceProps = dataSource;
        end
    end

    methods(Access = protected)
        function dataChanged(this, ~, ed)
            % By default just propagate the event
            this.notify("DataChange", ed);
        end
    end
end
