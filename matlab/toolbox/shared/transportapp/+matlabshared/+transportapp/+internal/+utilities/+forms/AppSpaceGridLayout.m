classdef AppSpaceGridLayout
    %APPSPACEGRIDLAYOUT class defines the GridLayout properties of a UI
    %Element that has a parent uigridlayout.

    % Copyright 2020 The MathWorks, Inc.

    properties
       Row {validateAppspaceLayoutFormInput(Row)} = 1
       Column {validateAppspaceLayoutFormInput(Column)} = 1
    end

    methods
        function obj = AppSpaceGridLayout(varargin)
            narginchk(0,2);
            if nargin == 1
                throw(MException(message("transportapp:utilities:IncorrectNumInputArguments", ...
                    "AppSpaceGridLayout")));
            elseif nargin == 2
                obj.Row = varargin{1};
                obj.Column = varargin{2};
            end
        end
    end
end

function validateAppspaceLayoutFormInput(data)
% Validation function for Row and Column entries for the AppSpaceGridLayout
% class.
validateattributes(data, "numeric", ["integer", "increasing", "nonempty", "nonzero", "nonnegative"]);

rowIndex = 1;
columnIndex = 2;

% data must always have 1 row, and 1-2 columns
if size(data, rowIndex) ~= 1 || size(data, columnIndex) > 2
    throw(MException(message("transportapp:utilities:InvalidLayoutEntry")));
end
end