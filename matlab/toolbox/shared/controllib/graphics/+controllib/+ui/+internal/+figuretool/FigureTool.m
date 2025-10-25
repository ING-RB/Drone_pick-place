classdef FigureTool < controllib.ui.internal.figuretool.AbstractTool
% FigureTool is the super-class of your FigureTool subclass.

% Author(s): Rong Chen
% Copyright 2019-2020 The MathWorks, Inc.
    
    properties (SetAccess = protected)
        % Property "Tabs"
        %   Store the contextual tabs associated with this document.  A
        %   document can have 0, 1 or more contextual tabs.
        Tabs matlab.ui.internal.toolstrip.Tab
    end
    
    methods(Access = protected)
        
        function this = FigureTool(tag, NorTabs, varargin)
            % Constructor "FigureTool": 
            %
            %   FigureTool(tag) creates a tool with a new FigureDocument
            %   tagged as "tag" and a new Tab tagged as "tag1".
            %
            %   FigureTool(tag, N) creates a tool with a new FigureDocument
            %   tagged as "tag" and N new Tabs tagged as "tag1", "tag2",
            %   and so on.  "N" can be any non-negative integer, including
            %   0 (i.e. no Tab)
            %
            %   FigureTool(tag, tabs) creates a tool with a new
            %   FigureDocument tagged as "tag" and given Tabs re-tagged as
            %   "tag1", "tag2", and so on.  "tabs" is an array of
            %   "matlab.ui.internal.toolstrip.Tab" objects
            %
            %   FigureTool(tag, N, document) or FigureTool(tag, tabs,
            %   document) creates a tool with given FigureDocument tagged
            %   as "tag".
            this = this@controllib.ui.internal.figuretool.AbstractTool(tag, varargin{:});
            if nargin==1
                NorTabs = 1;
            end
            if isa(NorTabs,'matlab.ui.internal.toolstrip.Tab')
                this.Tabs = NorTabs;
            else
                for ct=1:NorTabs
                    this.Tabs(ct) = matlab.ui.internal.toolstrip.Tab();
                end
            end
            for ct=1:length(this.Tabs)
                if isstring(tag)
                    this.Tabs(ct).Tag = tag + num2str(ct);
                else
                    this.Tabs(ct).Tag = [tag num2str(ct)];
                end
            end
        end
        
    end
    
end