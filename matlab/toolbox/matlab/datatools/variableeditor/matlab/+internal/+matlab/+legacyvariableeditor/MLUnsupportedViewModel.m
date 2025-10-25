classdef MLUnsupportedViewModel < internal.matlab.legacyvariableeditor.ViewModel
    %MLUnsupportedViewModel
    %   Unsupported View Model

    % Copyright 2013-2019 The MathWorks, Inc.

    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = MLUnsupportedViewModel(dataModel)
            this@internal.matlab.legacyvariableeditor.ViewModel(dataModel);
        end
        
        % getSupportedActions
        function actionList = getSupportedActions(~,varargin)
            actionList = [];
        end

        % isActionAvailable
        function isAvailable = isActionAvailable(~,~,varargin)
            isAvailable = false;
        end

        % isSelectable
        function selectable = isSelectable(~)
            selectable = false;
        end
        
        % isEditable
        function editable = isEditable(~)
            editable = false;
        end

        % getData
        function varargout = getData(this,varargin)
            varargout{1} = this.DataModel.getData(varargin{:});
        end

        % setData
        function varargout = setData(~,varargin)
            varargout{1} = [];
        end

        % getSize
        function size = getSize(this)
            size=this.DataModel.getSize();
        end       
        
        % getDisplaySize overridden from ViewModel. Returns the displaySize
        % for tall variables, falls back to ViewModel for other unsupported
        % types.
        function displaySize = getDisplaySize(this)            
            data = this.DataModel.Data;
            if isa(data, 'tall')
                % Special handling for tall variables, because the size of
                % a tall variable may not be known.
                tallInfo = matlab.bigdata.internal.util.getArrayInfo(data);
                displaySize = internal.matlab.datatoolsservices.FormatDataUtils.getTallInfoSize(tallInfo);
            else                
                displaySize = this.getDisplaySize@internal.matlab.legacyvariableeditor.ViewModel;
            end
        end       
        
        % updateData
        function data = updateData(this, varargin)
            data = this.DataModel.updateData(varargin{:});
        end
        
        function renderedData = getRenderedData(this,~,~,~,~)
            data = this.DataModel.Data; 
            if isa(data, 'tall') || isa(data, 'dlarray')
                % Special handling for tall variables - call their display
                % method without hotlinks, so no hyperlinks show up in the
                % display.  (For example, they have a 'Learn More' link which
                % doesn't make much sense if it is not a link). Similarly,
                % dlarrays have links in their displays.
                renderedData = evalc(['oldVal = feature(''hotlinks'', false);', ...
                    'restore = onCleanup(@() feature(''hotlinks'', oldVal));', ...
                    'display(data)']);
            elseif isempty(meta.class.fromName(class(data)))
                renderedData = evalc('display(data)');
            else
                renderedData = evalc('disp(data)');
            end
            % sometimes the disp returns empty. Ex: 0x0 struct
            if isempty(renderedData)
                renderedData = evalc('data');
            end
        end
    end
    
end
            

