classdef Entries
    % ENTRIES class contains the ClassName of the View and Controller
    % classes to be created, and also any custom input arguments needed
    % by the client apps to be passed in to the View and Controller
    % classes.

    % Copyright 2020 The MathWorks, Inc.
    properties
        % The ClassName of the View/Controller class that gets created.
        ClassName (1,1) string

        % Property that serves as additional input arguments for a custom
        % View/Controller class
        AdditionalParams = []
    end

    methods
        function obj = Entries(varargin)
            % Constructor
            narginchk(0,2);
            switch nargin
                case 1
                    obj.ClassName = varargin{1};
                case 2
                    obj.ClassName = varargin{1};
                    obj.AdditionalParams = varargin{2};
            end
        end
    end
end