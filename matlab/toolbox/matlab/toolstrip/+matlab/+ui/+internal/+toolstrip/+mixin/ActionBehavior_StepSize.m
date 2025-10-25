classdef (Abstract) ActionBehavior_StepSize < handle
    % Mixin class inherited by Spinner

    % Author(s): Rong Chen
    % Copyright 2015 The MathWorks, Inc.
    
    properties (Dependent, Access = public)
        % Property "NumberFormat": 
        %
        %   Numeric format taken by the value such as integer or double. It
        %   is a char array and the default value is 'integer'. It is
        %   writable.
        %
        %   Example:
        %       spinner = matlab.ui.internal.toolstrip.Spinner();
        %       spinner.NumberFormat = 'double';
        NumberFormat
        % Property "DecimalFormat": 
        %
        %   Specify display format for double value. It accepts a char
        %   array such as '4f' or '5e', where the number is precision
        %   (digits displayed after decimal point).  'f' stands for
        %   fixed-point notation and 'e' stands for exponential/scientific
        %   notation.  The default value is '3f'. It is writable.
        %
        %   Note: (1) choose precision based on step size.  For example, if
        %   step size is 1e-6, '6f' or above should be used to guarantee
        %   the proper display in the spinner.  (2) If NumberFormat is
        %   'integer', DecimalFormat is ignored.
        %
        %   Example:
        %       spinner = matlab.ui.internal.toolstrip.Spinner();
        %       spinner.NumberFormat = 'double';
        %       spinner.DecimalFormat = '5e';
        DecimalFormat
        % Property "StepSize": 
        %
        %   The step size used when up or down arrow key is pressed. It is
        %   a real number and the default value is 1. It is writable.
        %
        %   Example:
        %       spinner = matlab.ui.internal.toolstrip.Spinner();
        %       spinner.StepSize = 0.5;
        StepSize
    end
    
    methods (Abstract, Access = protected)
        
        getAction(this)
        
    end
    
    %% ----------------------------------------------------------------------------
    % Public methods
    methods
        
        %% Public API: Get/Set
        function value = get.NumberFormat(this)
            % GET function for NumberFormat property.
            action = this.getAction;
            value = action.NumberFormat;
        end
        function set.NumberFormat(this, value)
            % SET function for NumberFormat property.
            action = this.getAction();
            switch value
                case 'double'
                    % Set the default Decimal format if no other format is
                    % set before number format is set to 'double'
                    if strcmp(action.DecimalFormat, '0f')
                        action.DecimalFormat = '3f';
                    end
                case 'integer'
                    action.DecimalFormat = '0f';
            end
            action.NumberFormat = value;
        end
        function value = get.DecimalFormat(this)
            % GET function for DecimalFormat property.
            action = this.getAction;
            value = action.DecimalFormat;
        end
        function set.DecimalFormat(this, value)
            % SET function for DecimalFormat property.
            action = this.getAction();
            if strcmp(action.NumberFormat, 'integer')
                action.NumberFormat = 'double';
            end
            action.DecimalFormat = value;
        end
        function value = get.StepSize(this)
            % GET function for MinorStepSize property.
            action = this.getAction;
            value = action.MinorStepSize;
        end
        function set.StepSize(this, value)
            % SET function for MinorStepSize property.
            action = this.getAction();
            action.MinorStepSize = value;
            action.MajorStepSize = value;
        end
        
    end
    
end
