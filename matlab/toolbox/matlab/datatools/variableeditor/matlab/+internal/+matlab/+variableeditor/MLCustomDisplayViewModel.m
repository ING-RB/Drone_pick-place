classdef MLCustomDisplayViewModel < internal.matlab.variableeditor.ViewModel

    %  MATLAB Custom Object Display Variable Editor ViewModel

    % Copyright 2022 The MathWorks, Inc.
    events
        DataChange;
    end

    properties
        userContext char = ' ';
        % EmbeddedFigure
        EmbeddedFigureCanvas
        % EmbeddedFigureID
        EmbeddedAxes
    end

    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = MLCustomDisplayViewModel(dataModel, viewID, userContext)
            this@internal.matlab.variableeditor.ViewModel(dataModel);
            % Commenting out EmbeddedFigure usage.
            % this.EmbeddedFigure = matlab.ui.internal.embeddedfigure(); % Use matlab.ui.internal.divfigure for handle creation
            % this.DataModel.embedCustomDisplay(this.EmbeddedFigure);
            % efPacket = matlab.ui.internal.FigureServices.getEmbeddedFigurePacket(this.EmbeddedFigure); % matlab.ui.internal.FigureServices.getDivFigurePacket for packet fetching
            % this.EmbeddedFigureID = mls.internal.toJSON(efPacket);

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
            displaySize = this.getDisplaySize@internal.matlab.variableeditor.ViewModel;
        end

        % updateData
        function data = updateData(this, varargin)
            data = this.DataModel.updateData(varargin{:});
        end

        function renderedData = getRenderedData(this)
            renderedData = this.EmbeddedFigureID;
        end
    end

end
