classdef SharedMapProperties < matlabshared.autonomous.map.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%SharedMapProperties A handle class to share properties between map layesr and multi-layer maps
%
%   Copyright 2021-2024 The MathWorks, Inc.

    %#codegen
   
    properties (SetAccess = ?matlabshared.autonomous.map.internal.InternalAccess)
        %Resolution Grid resolution in cells per meter
        Resolution = 1;
        
        %GridSize Size of the grid in [rows, cols] (number of cells)
        GridSize = [10 10];
    end
    
    properties
        %XLocalLimits Min and max values of X in local frame
        XLocalLimits = [0 10];
        
        %YLocalLimits Min and max values of Y in local frame
        YLocalLimits = [0 10];
        
        %XWorldLimits Min and max values of X in world frame
        %   A vector [MIN MAX] representing the world limits of the grid
        %   along the X axis.
        XWorldLimits = [0 10];

        %YWorldLimits Min and max values of Y in world frame
        %   A vector [MIN MAX] representing the world limits of the grid
        %   along the Y axis.
        YWorldLimits = [0 10];
        
        %GridLocationInWorld Location of the grid in world coordinates
        %   A vector defining the [X Y] location of the bottom-left
        %   corner of the grid, relative to the world frame.
        %   Default: [0 0]
        GridLocationInWorld = [0 0]
        
        %GridOriginInLocal Location of the grid in local coordinates
        %   A vector defining the [X Y] location of the bottom-left
        %   corner of the grid, relative to the local frame.
        %   Default: [0 0]
        GridOriginInLocal = [0 0]
        
        %LocalOriginInWorld Location of the local frame in world coordinates
        %   A vector defining the [X Y] location of the local frame,
        %   relative to the world frame.
        %   Default: [0 0]
        LocalOriginInWorld = [0 0]
    end
    
    properties (Access = {?matlabshared.autonomous.map.internal.InternalAccess,...
            ?matlab.unittest.TestCase})
        
        %Width length of the map along X direction
        Width = 10;
        
        %Height length of the map along Y direction
        Height = 10;
        
        %LocalOriginInWorldInternal stores world coordinate the lower left
        %of the current grid lower left [obj.GridSize(1),1]. In case of non
        %integer resolutions move the local origin in world is different from 
        %local origin in world.
        LocalOriginInWorldInternal
    end
    
    methods
        function obj = SharedMapProperties(varargin)
            narginchk(1,2);
            if nargin == 1
            % obj = SharedMapProperties(other)
                % Resolution and GridSize must be set during construction
                other = varargin{1};
                obj.Resolution = other.Resolution;
                obj.GridSize   = other.GridSize;
                obj.Width = other.Width;
                obj.Height = other.Height;
                copyImpl(obj,other);
            else
            % obj = SharedMapProperties(gridSize, resolution)
                coder.internal.prefer_const(varargin{1}); % g2607528
                coder.internal.prefer_const(varargin{2}); % g2607528
                obj.GridSize = varargin{1};
                obj.Resolution = varargin{2};
                obj.Width  = obj.GridSize(2)/obj.Resolution;
                obj.Height = obj.GridSize(1)/obj.Resolution;
            end
        end
        
        function newObj = copy(obj)
            newObj = matlabshared.autonomous.internal.SharedMapProperties(obj);
        end
    end
    
    methods % Getters for dependent properties
        function val = get.XLocalLimits(obj)
        %get.XLocalLimits Getter for XLocalLimits property
            val = [obj.GridOriginInLocal(1),obj.GridOriginInLocal(1)+obj.Width];
        end
        
        function val = get.YLocalLimits(obj)
        %get.YLocalLimits Getter for YLocalLimits property
            val = [obj.GridOriginInLocal(2),obj.GridOriginInLocal(2)+obj.Height];
        end
        
        function xlims = get.XWorldLimits(obj)
        %get.XWorldLimits Getter for XWorldLimits property
            xlims = obj.LocalOriginInWorld(1) + obj.GridOriginInLocal(1) + ...
                [0 obj.Width];
        end

        function ylims = get.YWorldLimits(obj)
        %get.YWorldLimits Getter for YWorldLimits property
            ylims = obj.LocalOriginInWorld(2) + obj.GridOriginInLocal(2) + ...
                [0 obj.Height];
        end
        
        function location = get.GridLocationInWorld(obj)
        %get.GridLocationInWorld Getter for bottom-left corner of the grid
            location = obj.LocalOriginInWorld + obj.GridOriginInLocal;
        end
    end
    
    methods (Access = protected)
        function copyImpl(newObj, obj)
            % Update tunable properties
            newObj.GridOriginInLocal = obj.GridOriginInLocal;
            newObj.LocalOriginInWorld = obj.LocalOriginInWorld;
            newObj.LocalOriginInWorldInternal = obj.LocalOriginInWorldInternal;
        end
    end
    
    methods (Static, Hidden)
        function obj = loadobj(s)
            if isstruct(s)
                obj = matlabshared.autonomous.internal.SharedMapProperties(s);
            else
                obj = s;
            end
        end
        
        function result = matlabCodegenSoftNontunableProperties(~)
        %matlabCodegenSoftNontunableProperties Mark properties as nontunable during codegen
        %
        % Marking properties as 'Nontunable' indicates to Coder that
        % the property should be made compile-time Constant.
            result = {'Resolution','GridSize','Width','Height'};
        end
    end
end
