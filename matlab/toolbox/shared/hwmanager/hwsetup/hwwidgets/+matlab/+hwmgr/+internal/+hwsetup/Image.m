classdef Image < matlab.hwmgr.internal.hwsetup.Widget
    %matlab.hwmgr.internal.hwsetup.Image is a class that defines a HW
    %   Setup Image widget.
    %
    %   Image Widget Properties
    %   Position        -Location and Size [left bottom width height]
    %   Visible         -Widget visibility specified as 'on' or 'off'
    %   ImageFile       -Full path to the image file to be displayed, can
    %                    be set to an null image using empty strings.
    %   Tag             -Unique identifier for the button widget.
    %   ScaleMethod     -Image rendering mechanism within a component area.
    %
    %   EXAMPLE:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   i = matlab.hwmgr.internal.hwsetup.Image.getInstance(w);
    %   i.Position = [20 80 200 200];
    %   i.ImageFile = 'C:\Temp\my-image.jpg';
    %   i.show();
    %
    %See also matlab.hwmgr.internal.hwsetup.Widget
    
    % Copyright 2016-2021 The MathWorks, Inc.
    
    properties
        %ImageFile - full path to the image file that will be displayed
        % The image will be scaled to best fit the specified height and
        % width. Supported formats - PNG, GIF, JPEG, BMP, SVG (for UI
        % Component only)
        ImageFile
        
        %ScaleMethod - Specify how the image should be rendered within a 
        % component area. Supported values - fit, fill, none, scaledown,
        % scaleup, stretch. Only available with uiimage implementation. 
        ScaleMethod
    end
    
    properties(Access = public, Dependent, SetObservable)
        % Inherited Properties
        % Visible
        % Tag
        % Position
    end
    
    properties(SetAccess = protected, GetAccess = protected)
        % Inherited Properties
    end
    
    properties(SetAccess = immutable, GetAccess = protected)
        % Inherited Properties
        % Parent
    end
    
    properties(SetAccess = private, GetAccess = private)
        % Inherited Properties
        % DeleteFcn
    end
    
    %% Constructor
    methods(Access = protected)
        function obj = Image(varargin)
            %Image - Image constructor
            
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});
            
            %set defaults
            if ~isequal(class(obj.Parent),...
                    'matlab.hwmgr.internal.hwsetup.appdesigner.Grid')
                [pW, pH] = obj.getParentSize();
                obj.Position = [pW*0.25 pH*0.25 pW*0.5 pH*0.5];
            end
            obj.DeleteFcn = @matlab.hwmgr.internal.hwsetup.Widget.close;
        end
    end
    
    %% Overridden properties
    methods(Static)
        function obj = getInstance(aParent)
            %getInstance - returns instance of Image object
            
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent, mfilename);
        end
    end
    
    %% Property Setters and Getters
    methods
        function set.ImageFile(obj, imFile)
            %set.ImageFile - set image to the user specified file.
            % Validate the file and invoke the technology specific
            %implementation.
            
            obj.validateImage(imFile);
            obj.ImageFile = imFile;
            obj.setImage(imFile)
        end
        
        function set.ScaleMethod(obj, method)
            %set.ScaleMethod - set image scaling mechanism. Validate the
            %supplied method and invoke the technology specific
            %implementation.
            
            validatestring(method, {'fit', 'fill', 'none', 'scaledown',...
                'scaleup', 'stretch'});
            obj.ScaleMethod = method;
            obj.setScaleMethod(method);
        end
    end
    
    methods(Abstract)
        %setImage - Set the image based on the technology
        setImage(obj, imFile)
    end
    
    methods(Abstract, Access = protected)
        %validateImage - check if the supplied filename points to a valid image
        validateImage(obj, imFile); 
        
        %setScaleMethod - set image scaling mechanism
        setScaleMethod(obj, method);
    end
end

% LocalWords:  hwmgr hwsetup SVG scaledown scaleup uiimage
