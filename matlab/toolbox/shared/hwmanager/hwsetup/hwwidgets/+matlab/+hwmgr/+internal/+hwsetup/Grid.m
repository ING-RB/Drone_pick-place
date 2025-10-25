classdef Grid < matlab.hwmgr.internal.hwsetup.Widget &...
        matlab.hwmgr.internal.hwsetup.Container &...
        matlab.hwmgr.internal.hwsetup.mixin.BackgroundColor
    %matlab.hwmgr.internal.hwsetup.Grid is a class that defines a Hardware
    %Setup grid for placing elements relative to each other, instead of 
    %hard-coding pixel positions.
    
    % w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    % g = matlab.hwmgr.internal.hwsetup.Grid.getInstance(w);
    
    % Copyright 2021 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
        %RowHeight- cell array of row heights, specified as numbers of
        %string 'fit'.
        RowHeight
        %ColumnWidth- cell array of column widths, specified as numbers of
        %string 'fit'.
        ColumnWidth
        % Padding- padding around the outer perimeter of the grid, specified
        % as a vector of the form [left bottom right top]
        Padding
        % Row spacing, specified as a scalar number of pixels between
        % adjacent rows in the grid
        RowSpacing
        % Column spacing, specified as a scalar number of pixels between
        % adjacent columns in the grid
        ColumnSpacing
    end
    
    methods(Access = protected)
        function obj = Grid(varargin)
            %Grid- constructor
            
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});
            obj.DeleteFcn = @matlab.hwmgr.internal.hwsetup.Widget.close;
        end
    end
    
    methods(Static)
          function obj = getInstance(aParent)
              %getInstance- create an instance of a Grid.
              
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent,...
                mfilename);
        end
    end
    
    methods(Access = ?matlab.hwmgr.internal.hwsetup.TemplateBase)
        function disable(obj)
            set(findall(obj.Peer, '-property', 'enable'), 'enable', 'off')
        end

        function enable(obj)
            try
                set(findall(obj.Peer, '-property', 'enable'), 'enable', 'on')
            catch
                % During renable of screens on cleanup, if found that the
                % parent HW setup window is terminated then throw an error.
                % Instead of 'Invalid or deleted object.' error we will now
                % throw 'Hardware Setup Terminated, please try again.' in
                % command window.
                error(message('hwsetup:widget:HWSetupTerminated'));
            end
        end
    end

    %----------------------------------------------------------------------
    % Getter methods
    %----------------------------------------------------------------------
    methods
        function value = get.RowHeight(obj)
           value = get(obj.Peer, 'RowHeight'); 
        end
        
        function value = get.ColumnWidth(obj)
            value = get(obj.Peer, 'ColumnWidth');
        end
       
        function value = get.Padding(obj)
            value = get(obj.Peer, 'Padding');
        end

        function value = get.RowSpacing(obj)
            value = get(obj.Peer, 'RowSpacing');
        end

        function value = get.ColumnSpacing(obj)
            value = get(obj.Peer, 'ColumnSpacing');
        end
    end

    %----------------------------------------------------------------------
    % Setter methods
    %----------------------------------------------------------------------
    methods
        function set.RowHeight(obj, value)
            set(obj.Peer, 'RowHeight', value);
        end

        function set.ColumnWidth(obj, value)
            set(obj.Peer, 'ColumnWidth', value);
        end

        function set.Padding(obj, value)
            set(obj.Peer, 'Padding', value);
        end

        function set.RowSpacing(obj, value)
            set(obj.Peer, 'RowSpacing', value);
        end

        function set.ColumnSpacing(obj, value)
            set(obj.Peer, 'ColumnSpacing', value);
        end
    end
end