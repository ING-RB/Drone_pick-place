classdef ProgressBar < matlab.hwmgr.internal.hwsetup.Widget
    %PROGRESSBAR This class provides an instance of a ProgressBar widget as
    %a result of calling getInstance.A progress bar will display a
    %representation of how complete a task is or an indication that a task
    %is processing.
    %
    %   PROGRESSBAR Widget Properties
    %   Position        -Location and Size [left bottom width height]
    %   Visible         -Widget visibility specified as 'on' or 'off'
    %   Value           -Value of the progress bar. empty: 0, full: 100
    %   Indeterminate   -Activation flag for indeterminate mode (logical)
    %
    %   EXAMPLE:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   p = matlab.hwmgr.internal.hwsetup.Panel.getInstance(w);
    %   pb = matlab.hwmgr.internal.hwsetup.ProgressBar.getInstance(p);
    %   pb.Position = [20 20 200 20];
    %   pb.Value = 42;
    %   pb.show();
    %
    %See also matlab.hwmgr.internal.hwsetup.widget

    % Copyright 2016-2021 The MathWorks, Inc.
    
    properties(Dependent)
        %Value - Value to be displayed on the progress bar (0 through 100)
        Value
        
        %Indeterminate - Value for the indeterminate mode of the progress bar.
        %Indeterminate mode is a non distinct value that just indicates
        %that something is processing but we don't know how close to
        %completion we are. Can be set to true, false, 0 or 1. While
        %Indeterminate is set value can be modified or read but will not
        %affect the display until Indeterminate is set to false.
        Indeterminate
    end

    methods(Access = protected)
        function obj = ProgressBar(varargin)
            %ProgressBar - construct ProgressBar with defaults.
            
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});

            obj.Position = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.ProgressBarPosition;
            obj.Value = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.ProgressBarValue;
            obj.Indeterminate = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.ProgressBarIndeterminate;
        end
    end

    methods(Static)
       function obj = getInstance(aParent)
           %getInstance - returns instance of ProgressBar widget.

            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent,...
                mfilename);
        end
    end

    methods
        function set.Value(obj, value)
            %set.Value - set value on progress bar.
            
            validateattributes(value, {'numeric'}, {'nonempty', 'scalar',...
                '>=', 0, '<=', 100});
            obj.setValue(value);
        end

        function valueValue = get.Value(obj)
            %get.Value - get value of progress bar.
            
            valueValue = obj.getValue();
        end

        function set.Indeterminate(obj, value)
            %set.Indeterminate - indeterminate mode. Value can be 0, 1, 
            %true or false.
            
            validateattributes(value, {'numeric', 'logical'}, {'binary',...
                'nonempty', 'scalar'});
            obj.setIndeterminate(value);
        end

        function indeterminateValue = get.Indeterminate(obj)
            %get.Indeterminate - get indeterminate state.
            
            indeterminateValue =  obj.getIndeterminate();
        end
    end

    methods(Abstract, Access = protected)
        %setValue - Technology implementation of setting value.
        setValue(obj, value)
        
        %setIndeterminate - Technology implementation of setting
        %Indeterminate.
        setIndeterminate(obj, value)
        
        %getValue - Technology implementation of getting Value
        value = getValue(obj)
        
        %getIndeterminate - Technology implementation of getting Indeterminate
        value = getIndeterminate(obj)
    end
end