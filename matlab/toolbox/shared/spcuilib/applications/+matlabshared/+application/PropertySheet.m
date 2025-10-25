classdef PropertySheet < matlabshared.application.UITools & matlab.mixin.Heterogeneous
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties (Dependent)
        Visible
    end
    
    properties (Hidden, SetAccess = protected)
        Dialog
        Panel
        Layout
    end
    
    methods
        function this = PropertySheet(dlg)
            this.Dialog = dlg;
        end
        
        function update(~)
            % NO OP
        end
        
        function set.Visible(this, newVis)
            p = this.Panel;
            if newVis
                if isempty(p) || ~ishghandle(p)
                    p = createPanel(this);
                    this.Panel = p;
                end
                p.Visible = newVis;
            elseif ~isempty(p) && ishghandle(p)
                set(p, 'Visible', newVis);
            end
        end
        
        function vis = get.Visible(this)
            p = this.Panel;
            if isempty(p) || ~ishghandle(p)
                vis = false;
            else
                vis = logical(get(p, 'Visible'));
            end
        end
    end
    
    methods (Access = protected)
        function panel = createPanel(this, varargin)
            if useAppContainer(this.Dialog.Application)
                varargin = [varargin {'AutoResizeChildren', 'off'}];
            end
            panel = uipanel(this.Dialog.Figure, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1], ...
                'Visible', 'off', ...
                'BorderType', 'none', ...
                'Tag', sprintf('%s.PropertySheet', fliplr(strtok(fliplr(class(this)), '.'))), ...
                varargin{:});
        end
    end
    
    methods (Sealed)
        function obj = findobj(this, varargin)
            obj = findobj@handle(this, varargin{:});
        end
    end
end

% [EOF]
