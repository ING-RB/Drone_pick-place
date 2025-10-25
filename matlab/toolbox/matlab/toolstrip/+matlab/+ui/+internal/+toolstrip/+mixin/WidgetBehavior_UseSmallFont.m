classdef (Abstract) WidgetBehavior_UseSmallFont < handle
    % Mixin class inherited by Slider
    
    % Author(s): Rong Chen
    % Copyright 2013 The MathWorks, Inc.
    
    % ----------------------------------------------------------------------------
    properties (Dependent, Access = public)
        % Property "UseSmallFont": 
        %
        %   Whether or not use small font size for slider labels.  If there
        %   are other widgets in the same column, set it to "true" to avoid
        %   label clipping in the swing rendering.
        %   It is a logical and the default value is false.
        %   It is writable.
        %
        %   Example:
        %       slider = matlab.ui.internal.toolstrip.Slider()
        %       slider.UseSmallFont = true;
        UseSmallFont
    end
    
    properties (Access = {?matlab.ui.internal.toolstrip.base.Component})
        UseSmallFontPrivate = false;
    end
    
    % ----------------------------------------------------------------------------
    methods (Abstract, Access = protected)
        
        setPeerProperty(this)
        
    end
    
    % Public methods
    methods
        
        %% Public API: Get/Set
        function value = get.UseSmallFont(this)
            % GET function
            value = this.UseSmallFontPrivate;
        end
        function set.UseSmallFont(this, value)
            % SET function
            if ~islogical(value)
                error(message('MATLAB:toolstrip:control:invalidUseSmallFont'))
            end
            this.UseSmallFontPrivate = value;
            this.setPeerProperty('useSmallFont',value);
        end
    end
    
    methods (Access = protected)
        
        function [mcos, peer] = getWidgetPropertyNames_UseSmallFont(this)
            mcos = {'UseSmallFontPrivate'};
            peer = {'useSmallFont'};
        end
        
    end
    
end

