classdef AbstractTool < handle
% AbstractTool is the super-class of "FigureTool" and "DocumentTool"    

% Author(s): Rong Chen
% Copyright 2019-2020 The MathWorks, Inc.

    properties (SetAccess = protected)
        % Property "Tag"
        %   Assigned to Document.Tag and used to generate tags for
        %   contextual tabs
        %   It must be unique during the life cycle of the AppContainer
        %   It must be provided to the constructor.
        Tag                 
        % Property "Document"
        %   Store the handle of "matlab.ui.internal.FigureDocument"
        %   It is created by the constructor
        Document
    end
    
    properties (Access = {?controllib.ui.internal.figuretool.AbstractManager})
        % Property "LastSelectedTab"
        %   Store the last tab selection before the document is unselected.
        %
        %   If the last selection is a tab in the contextual TabGroup,
        %   "LastSelectedTab" stores the handle of that tab.  
        %
        %   If the last selection is a global tab outside the contextual
        %   TabGroup, "LastSelectedTab" stores a struct produced by
        %   "Appcontainer.SelectedToolstripTab"
        %
        %   Do not touch this property in any sub-classe of
        %   FigureToolManager and DocumenttoolManager.
        LastSelectedTab
    end
    
    methods(Access = protected)
        
        function this = AbstractTool(tag, varargin)
            % Constructor "AbstractTool": 
            %
            %   AbstractTool(tag) create Tool with a new FigureDocument.
            %
            %   AbstractTool(tag, document) create Tool with a given FigureDocument.
            this.Tag = tag;
            if nargin == 1
                this.Document = matlab.ui.internal.FigureDocument();
                this.Document.Tag = tag;
            else
                document = varargin{1};
                if isa(document,'matlab.ui.internal.FigureDocument')
                    this.Document = document;
                    this.Document.Tag = tag;
                else
                    error('Controllib:FigureTool:WrongDocumentObj','The 2nd input must be a "matlab.ui.internal.FigureDocument" object.');
                end
            end
        end
        
    end

end