classdef SimulinkAligner < handle
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties
        SpacingY = 30;
        SpacingX = 50;
    end
    
    properties (SetAccess = protected)
        ToMove = [];
        Position = [];
        Source = [];
    end
    
    methods
        function this = setup(this, toMove, source)
            if isPosition(toMove)
                position = toMove;
                toMove = [];
            else
                position = get_param(toMove, 'Position');
            end
            this.ToMove = toMove;
            this.Position = position;
            if nargin > 2
                if ~isPosition(source)
                    source = get_param(source, 'Position');
                end
            else
                source = [];
            end
            this.Source = source;
        end
        
        function varargout = commit(this)
            toMove = this.ToMove;
            if isempty(toMove) || nargout
                varargout = {this.Position};
            else
                set_param(toMove, 'Position', this.Position);
            end
            this.ToMove = [];
            this.Position = [];
            this.Source = [];
        end
        
        function varargout = matchSize(this, varargin)
            [source, position] = parseInputs(this, varargin{:});
            
            h = source(4) - source(2);
            w = source(3) - source(1);
            x = position(1);
            y = position(2);
            
            varargout = setupOutputs(this, x, y, w, h, nargout);
        end
        
        function varargout = alignVerticalCenter(this, varargin)
            [source, position] = parseInputs(this, varargin{:});
            
            h = position(4) - position(2);
            w = position(3) - position(1);
            x = position(1);
            y = source(2) - h / 2 + (source(4) - source(2)) / 2;
            
            varargout = setupOutputs(this, x, y, w, h, nargout);
        end
        
        function varargout = alignHorizontalCenter(this, varargin)
            [source, position] = parseInputs(this, varargin{:});
            
            h = position(4) - position(2);
            w = position(3) - position(1);
            x = source(1) - w / 2 + (source(3) - source(1)) / 2;
            y = position(2);
            
            varargout = setupOutputs(this, x, y, w, h, nargout);
        end
        
        function varargout = alignLeft(this, varargin)
            [source, position] = parseInputs(this, varargin{:});
            
            h = position(4) - position(2);
            w = position(3) - position(1);
            x = source(1);
            y = position(2);
            
            varargout = setupOutputs(this, x, y, w, h, nargout);
        end
        
        function varargout = alignTop(this, varargin)
            [source, position] = parseInputs(this, varargin{:});
            
            h = position(4) - position(2);
            w = position(3) - position(1);
            x = position(1);
            y = source(2);
            
            varargout = setupOutputs(this, x, y, w, h, nargout);
        end
        
        function varargout = alignBottom(this, varargin)
            [source, position] = parseInputs(this, varargin{:});
            
            h = position(4) - position(2);
            w = position(3) - position(1);
            x = position(1);
            y = source(4) - h;
            
            varargout = setupOutputs(this, x, y, w, h, nargout);
        end
        
        function varargout = alignRight(this, varargin)
            [source, position] = parseInputs(this, varargin{:});
            
            h = position(4) - position(2);
            w = position(3) - position(1);
            x = source(3) - w;
            y = position(2);
            
            varargout = setupOutputs(this, x, y, w, h, nargout);
        end
        
        function varargout = placeAbove(this, varargin)
            [source, position] = parseInputs(this, varargin{:});
            
            h = position(4) - position(2);
            w = position(3) - position(1);
            x = position(1);
            y = source(2) - h - this.SpacingY;
            
            varargout = setupOutputs(this, x, y, w, h, nargout);
        end
        
        function varargout = placeBelow(this, varargin)
            [source, position] = parseInputs(this, varargin{:});
            
            h = position(4) - position(2);
            w = position(3) - position(1);
            x = position(1);
            y = source(4) + this.SpacingY;
            
            varargout = setupOutputs(this, x, y, w, h, nargout);
        end
        
        function varargout = placeRight(this, varargin)
            [source, position] = parseInputs(this, varargin{:});
            
            h = position(4) - position(2);
            w = position(3) - position(1);
            x = source(3) + this.SpacingX;
            y = position(2);
            
            varargout = setupOutputs(this, x, y, w, h, nargout);
        end
        
        function varargout = placeLeft(this, varargin)
            [source, position] = parseInputs(this, varargin{:});
            
            h = position(4) - position(2);
            w = position(3) - position(1);
            x = source(1) - w - this.SpacingX;
            y = position(2);
            
            varargout = setupOutputs(this, x, y, w, h, nargout);
        end
    end
    
    methods (Access = protected)
        function [source, position] = parseInputs(this, toMove, source)
            if nargin == 3
                setup(this, toMove, source);
                source = this.Source;
            else
                if nargin == 2
                    source = toMove;
                end
                if nargin == 1
                    source = this.Source;
                elseif ~isPosition(source)
                    source = get_param(source, 'Position');
                end
            end
            position = this.Position;
        end
        
        function out = setupOutputs(this, x, y, w, h, nOutputs)
            this.Position = [x y x + w y + h];
            if nOutputs
                out = {this};
            else
                out = {};
                commit(this);
            end
        end
    end
end

function b = isPosition(input)

b = isnumeric(input) && numel(input) == 4;

end

% [EOF]
