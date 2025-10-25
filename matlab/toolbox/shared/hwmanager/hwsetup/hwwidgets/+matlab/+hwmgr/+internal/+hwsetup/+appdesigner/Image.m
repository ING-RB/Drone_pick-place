classdef Image < matlab.hwmgr.internal.hwsetup.Image
    % matlab.hwmgr.internal.hwsetup.appdesigner.Image is a class that
    % implements a Hardware Setup Image using uiimage.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            %createWidgetPeer creates a UI Component peer for Image
            %widget.
            
            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {}, 'createPeer', 'aParent');
            
            aPeer = uiimage('Parent', aParent);
        end
    end
    
    methods
        function setImage(obj, imFile)
            %setImage - set the image property on the peer
                
            validateattributes(imFile, {'char'}, {});
            if ~isempty(imFile) && exist(imFile, 'file')
                obj.Peer.Visible = 'on';
            else
                obj.Peer.Visible = 'off';
            end
            obj.Peer.ImageSource = imFile;
        end
    end
    
    methods(Access = protected)
        function validateImage(~, imFile)
            %validateImage - verify if the supplied image file is valid.
            
            validateattributes(imFile, {'char'}, {});
            
            %If the specified image file does not exist, set the file
            %to be empty and warn the user.
            if ~isempty(imFile) && ~exist(imFile, 'file')
                error(message('hwsetup:widget:EntityDoesNotExist', imFile));
            end
            
            if ~isempty(imFile)
                matlab.ui.internal.IconUtils.validateIcon(imFile);
            end
        end
        
        function setScaleMethod(obj, method)
            %setScaleMethod - sets the ScaleMethod property on peer -
            %uiimage.
            
            obj.Peer.ScaleMethod = method;
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = Image(varargin)
            %Image constructor
            
            obj@matlab.hwmgr.internal.hwsetup.Image(varargin{:});
            obj.ScaleMethod = 'fit';
        end
    end
end

% LocalWords:  hwmgr hwsetup appdesigner uiimage
