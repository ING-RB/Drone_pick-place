classdef MLUnsupportedViewModel < internal.matlab.variableeditor.ViewModel
    %MLUnsupportedViewModel
    %   Unsupported View Model

    % Copyright 2013-2025 The MathWorks, Inc.
    events
        DataChange;
    end
    
    properties
        userContext char = ' ';
    end    
    
    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = MLUnsupportedViewModel(dataModel, viewID, userContext)
            this@internal.matlab.variableeditor.ViewModel(dataModel);
            if nargin >= 2
                this.viewID = viewID;
                if (nargin == 3)
                    this.userContext = userContext;
                end
            end
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
                displaySize = this.getDisplaySize@internal.matlab.variableeditor.ViewModel;
            end
        end       
        
        % updateData
        function data = updateData(this, varargin)
            data = this.DataModel.updateData(varargin{:});
        end
        
        function renderedData = getRenderedData(this,~,~,~,~)
            data = this.DataModel.Data; 
            renderedData = [];
            try
                if isa(data, 'tall') || isa(data, 'dlarray') || isa(data, 'eventtable') || isempty(meta.class.fromName(class(data)))
                    % Special handling for tall variables - call their display
                    % method without hotlinks, so no hyperlinks show up in the
                    % display.  (For example, they have a 'Learn More' link which
                    % doesn't make much sense if it is not a link). Similarly,
                    % dlarrays/eventtable have links in their displays.
                    renderedData = evalc('feature(''hotlinks'', false);display(data)');
                elseif internal.matlab.variableeditor.MLManager.isSupportedOptimvarType(data)
                    renderedData = evalc('feature(''hotlinks'', false);show(data)');
                else
                    renderedData = evalc('feature(''hotlinks'', false);disp(data)');
                end
            catch
            end

            % sometimes the disp returns empty. Ex: 0x0 struct
            % Evalc usecases do not honor hotlinks feature, so strip regex
            % manually.
            if isempty(renderedData)
                try
                    renderedData = evalc('feature(''hotlinks'', false);data');
                catch e
                    renderedData = e.message;
                end
            end
        end
    end
    
end
            

