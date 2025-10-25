classdef (HandleCompatible) CustomLinks
    %CUSTOMLINKS class contains the custom method link details for
    %matlabshared.testmeas.CustomDisplay.
    %matlabshared.testmeas.CustomDisplay class parses the objects of this
    %class for displaying custom method links.

    % Copyright 2020 The MathWorks, Inc.

    properties
        % The link text for the custom link that shows up in the footer.
        LinkText (1, 1) string

        % The name of the method on the user's interface that gets invoked 
        % when the custom link is clicked.
        MethodName (1, 1) string

        % Flag to show the custom link on a new line with a "Show " for
        % true, or in the same line as the previous link for false.
        NewLine (1, 1) logical = false
    end

    methods
        function obj = CustomLinks(varargin)
           narginchk(2, 3);
           obj.MethodName = varargin{1};
           obj.LinkText = varargin{2};
           if nargin == 3
               obj.NewLine = varargin{3};
           end
        end
    end
end