classdef (HandleCompatible) CustomProperties
    %CUSTOMPROPERTIES class contains the custom properties link details for
    %matlabshared.testmeas.CustomDisplay.
    %matlabshared.testmeas.CustomDisplay class parses the objects of this
    %class for displaying custom property links.

    % Copyright 2020 The MathWorks, Inc.

    properties
        % The group names of the properties that get displayed on clicking
        % the custom link
        GroupName (1, :) string

        % The list of properties that get displayed for each group name
        % mentioned above.
        PropertyList (1, :) cell

        % The link text for the custom link that shows up in the footer.
        LinkText (1, 1) string

        % Flag to show the custom link on a new line with a "Show " for
        % true, or in the same line as the previous link for false.
        NewLine (1, 1) logical = false
    end

    methods
        function obj = CustomProperties(varargin)
           narginchk(3, 4);
           obj.GroupName = varargin{1};
           obj.PropertyList = varargin{2};
           obj.LinkText = varargin{3};
           if nargin == 4
               obj.NewLine = varargin{4};
           end
        end
    end
end