classdef Canvas < matlabshared.application.AxesTooltip
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties (SetAccess = protected, Hidden)
        
        InButtonDown = false;
        InMouseMove  = false;
        InButtonUp   = false;
        
        ButtonDownConfiguring = false;
        ButtonUpWaiting = false;
        MouseMoveWaiting = false;
        ButtonUpInputs = {};
        MouseMoveInputs = {};
        HighlightLine;
        CallbackQueue = struct('type', {}, 'inputs', {});
        IsBusy = false;
    end
    
    properties (Hidden)
        InitialPoint;
    end
    
    methods
        
        function this = Canvas()
            % Wire the mouse calbacks
            fig = getFigure(this);
            fig.WindowButtonMotionFcn = @this.onMouseMove;
            fig.WindowButtonUpFcn     = @this.onButtonUp;
        end
        
        function highlightCanvas(this)
            hLine = this.HighlightLine;
            if isempty(hLine) || ~ishghandle(hLine)
                hAxes = getAxes(this);
                hLine = line(hAxes, ...
                    'LineWidth', 2, ...
                    'Color', [0 154 225]/255);
                this.HighlightLine = hLine;
                setappdata(hLine, 'LimitListener', event.proplistener(hAxes, ...
                    [findprop(hAxes, 'XLim') findprop(hAxes, 'YLim')], ...
                    'PostSet', @this.onAxesLimitChanged));
            end
            hLine.Visible = 'on';
            updateHighlightXYData(this);
        end
        
        function removeHighlightCanvas(this)
            hLine = this.HighlightLine;
            if ~isempty(hLine) && ishghandle(hLine)
                delete(hLine);
            end
            this.HighlightLine = [];
        end
        
        function c = disableAxesToolbar(this)
            a = getAxes(this);
            t = a.Toolbar;
            oldVis = t.Visible;
            t.Visible = false;
            
            % Create a clean up object to make sure the disable only lasts
            % inside a single function call.
            c = onCleanup(@() setVisible(t, oldVis));
        end
    end
    
    methods (Hidden)
        
        function onAxesLimitChanged(this, ~, ~)
            updateHighlightXYData(this);
        end
        
        function updateHighlightXYData(this)
            hAxes = getAxes(this);
            xLim = hAxes.XLim;
            yLim = hAxes.YLim;
            set(this.HighlightLine, ...
                'XData', [xLim xLim(2) xLim(1) xLim], ...
                'YData', [yLim(2) yLim(2) yLim(1) yLim yLim(2)]);
        end
        
        function onButtonDown(this, varargin)
            % Set a flag to let onButtonUp know to wait.
%             disp('buttondown start')
            if this.IsBusy
                this.addToMouseActionQueue('buttonDown', varargin);
                return;
            end
            c = onCleanup(@() finishMouseCallback(this));
            this.IsBusy = true;
            this.InButtonDown = true;
            
            this.InitialPoint = getCurrentPoint(this);
            performButtonDown(this, varargin{:});
%             disp('buttondown done')
        end
        
        function onButtonUp(this, varargin)
%             disp('buttonup start')
            if this.IsBusy
%                 disp('buttonup queued')
                addToMouseActionQueue(this, 'buttonUp', varargin);
                return;
            end
            c = onCleanup(@() finishMouseCallback(this));
            this.IsBusy = true;
            this.InButtonUp = true;
            performButtonUp(this, varargin{:});
%             disp('buttonup done')
        end
        
        function onMouseMove(this, varargin)
            if this.IsBusy
                addToMouseActionQueue(this, 'mouseMove', varargin);
                return;
            end
            c = onCleanup(@() finishMouseCallback(this));
            this.IsBusy = true;
            this.InMouseMove = true;
            performMouseMove(this, varargin{:});
        end
        
        function finishMouseCallback(this)
            try
                flushMouseActionQueue(this);
            catch ME %#ok<NASGU>
            end
            this.InButtonDown = false;
            this.InButtonUp   = false;
            this.InMouseMove  = false;
            this.IsBusy       = false;
		end

        function addToMouseActionQueue(this, type, inputs)
            new = struct('type', type, 'inputs', {inputs});
            if strcmp(type, 'mouseMove') && ~isempty(this.CallbackQueue) && strcmp(this.CallbackQueue(end).type, 'mouseMove')
                
                % Throw away subsequent mouse moves, only use the last
                % one.+
                this.CallbackQueue(end) = new;
            else
                this.CallbackQueue(end+1) = new;
            end
        end
        
        function flushMouseActionQueue(this)
            % If we find a single buttonUp, then all mouseMoves should be
            % discarded
            
            while ~isempty(this.CallbackQueue)
                
                item = this.CallbackQueue(1);
                this.CallbackQueue(1) = [];
%                 disp([item.type 'queue'])
                if strcmp(item.type, 'mouseMove')
                    
                    % Might need to check if we are coming from button down
                    % before we throw out the move
                    if any(strcmp({this.CallbackQueue.type}, 'buttonUp'))
                        continue;
                    end
                    performMouseMove(this, item.inputs{:});
                elseif strcmp(item.type, 'buttonDown')
                    performButtonDown(this, item.inputs{:});
                elseif strcmp(item.type, 'buttonUp')
                    if this.InButtonDown
                        % If we are coming out of a button down callback
                        % and we have a button up, then the up was too
                        % fast, do not honor the current mouse position and
                        % just cancel any down modes.
                        cancelButtonDown(this);
                        % Remove any mouse moves that are on the queue
                        % after us until we hit another kind of event
                        while ~isempty(this.CallbackQueue) && strcmp(this.CallbackQueue(1).type, 'mouseMove')
                            this.CallbackQueue(1) = [];
                        end
                    end
                    performButtonUp(this, item.inputs{:});
                end
            end
        end
    end
    
    methods (Access = protected)
        
        function performMouseMove(varargin)
            % NO OP
        end
        
        function performButtonDown(varargin)
            % NO OP
        end
        
        function performButtonUp(varargin)
            % NO OP
        end
        
        function cancelButtonDown(varargin)
            % NO OP
        end
    end
    
    methods (Abstract)
        hAxes = getAxes(this)
    end
end

function setVisible(obj, vis)
obj.Visible = vis;
end

% [EOF]
