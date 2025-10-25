classdef ToolGroupCutCopyPaste < handle
    %ToolGroupCutCopyPaste
    
    %   Copyright 2017 The MathWorks, Inc.

    properties (SetAccess = protected, Hidden)
        CopyPasteBuffer
    end
    
    properties (Access = protected)
        ComponentActivatedListener
    end
    
    methods
        function this = ToolGroupCutCopyPaste
            
            this.ComponentActivatedListener = event.listener(this, 'ComponentActivated', @this.onComponentActivated);
            
            addQabButton(this, 'paste', @this.pasteCallback, 'Enabled', false);
            addQabButton(this, 'copy',  @this.copyCallback, 'Enabled', false);
            addQabButton(this, 'cut',   @this.cutCallback, 'Enabled', false);
            
            addApplicationKeyPress(this, 'x', @this.cutCallback,   {'control'});
            addApplicationKeyPress(this, 'c', @this.copyCallback,  {'control'});
            addApplicationKeyPress(this, 'v', @this.pasteCallback, {'control'});
        end
    end
    
    methods (Hidden)
        function [cut, copy, paste] = createCutCopyPasteMenus(this, h, canvas)
            sep = 'on';
            if isempty(h.Children)
                sep = 'off';
            end
            if nargin < 3
                canvas = this;
            end
            cut = uimenu(h, ...
                'Separator', sep, ...
                'Tag', 'CutItem', ...
                'Label', getString(message('Spcuilib:application:Cut')), ...
                'Callback', @this.cutCallback);
            copy = uimenu(h, ...
                'Tag', 'CopyItem', ...
                'Label', getString(message('Spcuilib:application:Copy')), ...
                'Callback', @this.copyCallback);
            paste = uimenu(h, ...
                'Tag', 'PasteItem', ...
                'Label', getString(message('Spcuilib:application:Paste')), ...
                'Callback', @canvas.pasteCallback);
        end
        
        function cutItem(this)
            item = cutItemImpl(this);
            if ~isempty(item)
                this.CopyPasteBuffer = item;
            end
        end
        
        function copyItem(this)
            item = copyItemImpl(this);
            if ~isempty(item)
                this.CopyPasteBuffer = item;
            end
        end
        
        function pasteItem(this, varargin)
            pasteItemImpl(this, this.CopyPasteBuffer, varargin{:});
        end
        
        function b = isCopyEnabled(~)
            b = false;
        end

        function b = isCutEnabled(this)
            b = isCopyEnabled(this);
        end

        function b = isPasteEnabled(this)
            b = ~isempty(this.CopyPasteBuffer);
        end
    end
    
    methods (Access = protected)
        
        function item = cutItemImpl(~)
            item = [];
        end
        function item = copyItemImpl(~)
            item = [];
        end
        function pasteItemImpl(~,~)
            % NO OP
        end
        
        function updateCutCopyPasteQab(this)
            setQabEnabled(this, 'copy',  isCopyEnabled(this));
            setQabEnabled(this, 'cut',   isCutEnabled(this));
            setQabEnabled(this, 'paste', isPasteEnabled(this));
        end
        
        function updateCutCopyPasteQAB(this)
            updateCutCopyPasteQab(this);
        end
        
        function cutCallback(this, ~, ~)
            if isCutEnabled(this)
                cutItem(this);
                updateCutCopyPasteQab(this);
            end
        end
        
        function copyCallback(this, ~, ~)
            if isCopyEnabled(this)
                copyItem(this);
                updateCutCopyPasteQab(this);
            end
        end
        
        function pasteCallback(this, ~, ~)
            if isPasteEnabled(this)
                pasteItem(this);
            end
        end
        
        function onComponentActivated(this, ~, ~)
            updateCutCopyPasteQab(this);
        end
    end
end

% [EOF]
