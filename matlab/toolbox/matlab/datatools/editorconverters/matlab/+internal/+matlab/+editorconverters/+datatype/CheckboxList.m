classdef CheckboxList
    % CheckboxList - datatype used to represent a CheckboxList in the Property
    % Inspector
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties
        % Full set of items to display as a checkbox list table
        Items
        
        % Current value of the selection
        Value
        
        % Label to show in the checkbox list table
        Label string = strings(0);

        ImmediateApply (1,1) logical = false;
    end
    
    methods
        function this = CheckboxList(value, varargin)
            % Standardize on working with chars/cellstrs for easy
            % pass-through to the client
            this.Value = convertStringsToChars(value);
            
            if nargin > 1
                % The second argument is the full set of items to select from
                this.Items = convertStringsToChars(varargin{1});
            end
            
            if nargin > 2
                % the third argument is the label to display for the table
                this.Label = varargin{2};
            end

            if nargin > 3
                % Last argument is whether to immediate apply changes or not
                this.ImmediateApply = varargin{3};
            end
        end
        
        function b = char(this)
            b = char(this.Value);
        end
        
        function b = string(this)
            b = string(this.Value);
        end
    end
end

