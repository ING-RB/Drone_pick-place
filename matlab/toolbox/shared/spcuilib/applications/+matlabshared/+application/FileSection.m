classdef FileSection < matlab.ui.internal.toolstrip.Section
    %
    
    %   Copyright 2020-2024 The MathWorks, Inc.
    
    properties (SetAccess = protected)
        Controller
    end

    properties (Hidden)
        UseSvgIcons = false;
        CompactMode = false;
    end

    properties (SetAccess = protected, Hidden)
        SaveSplitButton
        SaveButton
        OpenButton
        NewButton
        ImportButton
        UsingLargeSaveIcons = false;
        DropDownPerformedListener;
        NewPopup
        OpenPopup
        SavePopup
        ImportPopup;
    end
    
    methods
        function this = FileSection(file, varargin)
            
            this@matlab.ui.internal.toolstrip.Section();
            for indx = 1:2:numel(varargin)
                this.(varargin{indx}) = varargin{indx + 1};
            end
            
            import matlab.ui.internal.toolstrip.*;
            
            this.Controller = file;
            this.Title = getString(message('Spcuilib:application:FileSectionTitle'));
            this.Tag   = 'file';

            useSvg = this.UseSvgIcons;
            
            % Add code for new session vs new app.
            newInfo = getNewSpecification(file);
            if useSvg
                icon = Icon('new');
            else
                icon = Icon.NEW_24;
            end
            if isscalar(newInfo)
                new = Button(getString(message('Spcuilib:application:NewText')), icon);
                new.Tag = ['New' upper(newInfo.tag(1)) newInfo.tag(2:end)];
                
            else
                new = SplitButton(getString(message('Spcuilib:application:NewText')), icon);
                new.Tag = 'NewSplitButton';
                new.DynamicPopupFcn = @this.newDynamicPopupFcn;
            end
            defaultNewTag = getDefaultNewTag(file);
            new.ButtonPushedFcn = file.initCallback(@this.newCallback, defaultNewTag);
            
            this.NewButton = new;

            setDefaultDescription(new, defaultNewTag, newInfo);
            
            openInfo = getOpenSpecification(file);
            openText = getString(message('Spcuilib:application:OpenText'));
            if useSvg
                icon = Icon('openFolder');
            else
                icon = Icon.OPEN_24;
            end

            if showRecentFiles(file)
                
                % If we are showing recent files, we are always using a
                % dynamic split button.
                open = SplitButton(openText, icon);
                open.DynamicPopupFcn = @this.openSplitCallback;
                this.DropDownPerformedListener = event.listener(open, 'DropDownPerformed', @this.dropDownPerformedCallback);
            elseif ~isscalar(openInfo)
                
                % If we have multiple open options but no recent files use
                % a static split button
                open = SplitButton(openText, icon);
                open.DynamicPopupFcn = @this.basicOpenDynamicPopupFcn;
            else
                
                % If single open option and no recent files, then use a
                % standard button.
                open = Button(openText, icon);
            end
            this.OpenButton = open;
            open.Tag = 'open';
            open.ButtonPushedFcn = file.initCallback(@this.openCallback);
            setDefaultDescription(open, getDefaultOpenTag(file), openInfo);
            
            defaultTag = getDefaultSaveTag(file);
            
            if useSvg
                icon = Icon('saved');
            else
                icon = Icon.SAVE_24;
            end
            save = SplitButton(getString(message('Spcuilib:application:SaveText')), icon);
            save.Tag = 'save';
            save.ButtonPushedFcn = file.initCallback(@this.saveCallback, defaultTag);
            save.DynamicPopupFcn = @this.saveDynamicPopupFcn;

            this.SaveSplitButton = save;

            if this.CompactMode
              col = addColumn(this);
              add(col, new);
              add(col, open);
              add(col, save);
            else
              add(addColumn(this), new);
              add(addColumn(this), open);
              add(addColumn(this), save);
            end

            imprtInfo = getImportSpecification(file);
            if ~isempty(imprtInfo)

                info = getImportDescription(file);
                imprt = DropDownButton(info.text, info.icon);
                imprt.Description = info.description;
                imprt.Tag = info.tag;
                imprt.DynamicPopupFcn = @this.importDynamicPopupFcn;
                add(addColumn(this), imprt);
                this.ImportButton = imprt;
            end

            
            % Single column support.
            %             column.add(new);
            %             column.add(open);
            %             column.add(save);
        end
        
        function updateSaveIcons(this)
            import matlab.ui.internal.toolstrip.Icon;
            useSvg = this.UseSvgIcons;
            if this.Controller.IsDirty
                if useSvg
                    splitIcon = Icon('unsaved');
                else
                    splitIcon = Icon.SAVE_DIRTY_24;
                end
                if this.UsingLargeSaveIcons || useSvg
                    saveIcon = splitIcon;
                else
                    saveIcon = Icon.SAVE_DIRTY_16;
                end
            else
                if useSvg
                    splitIcon = Icon('saved');
                else
                    splitIcon = Icon.SAVE_24;
                end
                if this.UsingLargeSaveIcons || useSvg
                    saveIcon = splitIcon;
                else
                    saveIcon = Icon.SAVE_16;
                end
            end
            this.SaveSplitButton.Icon = splitIcon;
            this.SaveButton.Icon      = saveIcon;
        end
    end

    methods (Hidden)

        % Helper for tests to create all available popups immediately.
        function attachAllPopups(this)
            new = this.NewButton;
            if isa(new, 'matlab.ui.internal.toolstrip.SplitButton')
                new.Popup = new.DynamicPopupFcn();
            end
            this.SaveSplitButton.Popup = this.SaveSplitButton.DynamicPopupFcn();
            open = this.OpenButton;
            if isa(open, 'matlab.ui.internal.toolstrip.SplitButton')
                open.Popup = open.DynamicPopupFcn();
            end
            import = this.ImportButton;
            if ~isempty(import)
                import.Popup = import.DynamicPopupFcn();
            end
        end
    end
    
    methods (Access = protected)

        function openPopup = basicOpenDynamicPopupFcn(this, ~, ~)
            import matlab.ui.internal.toolstrip.*;
            openPopup = this.OpenPopup;
            if isempty(openPopup)
                openPopup = PopupList;
                openInfo = getOpenSpecification(this.Controller);
                if this.UseSvgIcons
                    icon = Icon('openFolder');
                else
                    icon = Icon.OPEN_16;
                end
                addSubItems(this.OpenButton, openPopup, openInfo, @this.openCallback, icon, 'Open');
                this.OpenPopup = openPopup;
            end
        end

        function newPopup = newDynamicPopupFcn(this, ~, ~)
            import matlab.ui.internal.toolstrip.*;
            newPopup = this.NewPopup;
            if isempty(newPopup)

                newPopup = PopupList;
                newInfo = getNewSpecification(this.Controller);
                if this.UseSvgIcons
                    icon = Icon('new');
                elseif hasDescription(newInfo)
                    icon = Icon.NEW_24;
                else
                    icon = Icon.NEW_16;
                end
                addSubItems(this, newPopup, newInfo, @this.newCallback, icon, 'New');
                this.NewPopup = newPopup;
            end
        end

        function savePopup = saveDynamicPopupFcn(this, ~, ~)
            import matlab.ui.internal.toolstrip.*;
            savePopup = this.SavePopup;
            if isempty(savePopup)
                file = this.Controller;
                saveInfo = getSaveSpecification(file);
                savePopup = PopupList;
                savePopup.Tag = 'savePopup';
                defaultTag = getDefaultSaveTag(file);
                setDefaultDescription(this.SaveSplitButton, defaultTag, saveInfo);

                if numel(saveInfo) == 1

                    if this.UseSvgIcons
                        saveIcon = Icon('saved');
                        saveAsIcon = Icon('saveAs');
                    else
                        saveIcon = Icon.SAVE_16;
                        saveAsIcon = Icon.SAVE_AS_16;
                    end
                    saveItem = ListItem(getString(message('Spcuilib:application:SaveText')), saveIcon);
                    saveItem.Tag = 'saveItem';
                    saveItem.ItemPushedFcn = file.initCallback(@this.saveCallback, saveInfo(1).tag);
                    saveItem.ShowDescription = false;

                    saveAsItem = ListItem(getString(message('Spcuilib:application:SaveAsText')), saveAsIcon);
                    saveAsItem.Tag = 'saveAsItem';
                    saveAsItem.ItemPushedFcn = file.initCallback(@this.saveAsCallback, saveInfo(1).tag);
                    saveAsItem.ShowDescription = false;

                    savePopup.add(saveItem);
                    savePopup.add(saveAsItem);
                    this.SaveButton = saveItem;
                else
                    %                 saveAsIndex = find(cellfun(@iscell, {saveInfo.text}));
                    %                 if numel(saveAsIndex) == 1
                    %                     % If there is exactly 1 save as option, it always goes
                    %                     % to the end.
                    %                     saveInfo = [saveInfo(1:saveAsIndex-1) saveInfo(saveAsIndex+1:end) saveInfo(saveAsIndex)];
                    %                 end
                    if iscell(saveInfo)
                        for indx = 1:numel(saveInfo)
                            add(savePopup, PopupListHeader(saveInfo{indx}{1}));
                            addSaveItems(this, savePopup, saveInfo{indx}{2}, defaultTag);
                        end
                    else
                        addSaveItems(this, popup, saveInfo, defaultTag);
                    end
                end
                this.SavePopup = savePopup;
            end
        end

        function importPopup = importDynamicPopupFcn(this, ~, ~)
            import matlab.ui.internal.toolstrip.*;
            importPopup = this.ImportPopup;
            if isempty(importPopup)
                importInfo = getImportSpecification(this.Controller);
                importPopup = PopupList;
                importPopup.Tag = 'importPopup';

                if this.UseSvgIcons
                    icon = Icon('import_data');
                else
                    icon = Icon.IMPORT_16;
                end

                if iscell(importInfo)
                    for indx = 1:numel(importInfo)
                        add(importPopup, PopupListHeader(importInfo{indx}{1}));
                        addSubItems(this, importPopup, importInfo{indx}{2}, ...
                            @this.importCallback, icon, 'Import');
                    end
                else
                    addSubItems(this, importPopup, importInfo, ...
                        @this.importCallback, icon, 'Import');
                end
                this.ImportPopup = importPopup;
            end
        end
        
        function addSaveItems(this, popup, saveInfo, defaultTag)
            import matlab.ui.internal.toolstrip.*;
            file = this.Controller;
            if this.UseSvgIcons
                saveIcon = Icon('saved');
                saveAsIcon = Icon('saveAs');
            elseif hasDescription(saveInfo)
                this.UsingLargeSaveIcons = true;
                saveIcon = Icon.SAVE_24;
                saveAsIcon = Icon.SAVE_AS_24;
            else
                saveIcon = Icon.SAVE_16;
                saveAsIcon = Icon.SAVE_AS_16;
            end
            for indx = 1:numel(saveInfo)
                if iscell(saveInfo(indx).text)

                    saveItem = ListItem(saveInfo(indx).text{1}, saveIcon);
                    saveAsItem = ListItem(saveInfo(indx).text{2}, saveAsIcon);
                    saveAsItem.ItemPushedFcn = file.initCallback(@this.saveAsCallback, saveInfo(indx).tag);
                    saveAsItem.Tag = ['SaveAs' upper(saveInfo(indx).tag(1)) saveInfo(indx).tag(2:end)];
                    saveAsItem.ShowDescription = false;
                else
                    if isfield(saveInfo(indx), 'icon') && ~isempty(saveInfo(indx).icon)
                        icon = Icon(saveInfo(indx).icon);
                    end
                    saveItem = ListItem(saveInfo(indx).text, icon);
                end
                saveItem.ItemPushedFcn = file.initCallback(@this.saveCallback, saveInfo(indx).tag);
                saveItem.Tag = ['Save' upper(saveInfo(indx).tag(1)) saveInfo(indx).tag(2:end)];
                if isfield(saveInfo, 'description') && ~isempty(saveInfo(indx).description)
                    saveItem.Description = saveInfo(indx).description;
                    saveItem.ShowDescription = true;
                else
                    saveItem.ShowDescription = false;
                end
                popup.add(saveItem);
                if iscell(saveInfo(indx).text)
                    popup.add(saveAsItem);
                end
                if strcmp(defaultTag, saveInfo(indx).tag)
                    this.SaveButton = saveItem;
                end
            end
        end
        
        function newCallback(this, ~, ~, tag)
            new(this.Controller, tag);
        end
        
        function saveCallback(this, ~, ~, tag)
            try
                saveFile(this.Controller, '', tag);
            catch ME
                errorMessage(this.Controller, ME, getString(message('Spcuilib:application:SaveErrorTitle')));
            end
        end
        
        function saveAsCallback(this, ~, ~, tag)
            try
                saveFileAs(this.Controller, tag);
            catch ME
                errorMessage(this.Controller, ME, getString(message('Spcuilib:application:SaveErrorTitle')));
            end
        end
        
        function openCallback(this, ~, ~, varargin)
            try
                openFile(this.Controller, '', varargin{:});
            catch ME
                errorMessage(this.Controller, ME, getString(message('Spcuilib:application:OpenErrorTitle')));
            end
        end
        
        function popup = openSplitCallback(this, ~, ~)
            
            file = this.Controller;
            openSplitOpening(file);
            
            import matlab.ui.internal.toolstrip.*;
            
            popup = PopupList;
            
            openSpec = getOpenSpecification(file);
            
            if ~iscell(openSpec)
                popup.add(PopupListHeader(getString(message('Spcuilib:application:OpenHeaderTitle'))));
            end
            
            if this.UseSvgIcons
                icon = Icon('openFolder');
            elseif hasDescription(openSpec)
                icon = Icon.OPEN_24;
            else
                icon = Icon.OPEN_16;
            end
            
            addSubItems(this, popup, openSpec, @this.openCallback, icon, 'Open');
            
            popup.add(PopupListHeader(getString(message('Spcuilib:application:RecentFilesHeaderTitle'))));
            
            fileInfo = getRecentFiles(file);
            
            if isempty(fileInfo)
                item = ListItem(getString(message('Spcuilib:application:NoRecentFilesText')));
                item.Enabled = false;
                item.ShowDescription = false;
                popup.add(item);
            else
                % Never put up more than 10.
                for indx = 1:min(size(fileInfo, 1), 10)
                    [icon, label] = getInfoForRecentFile(file, fileInfo{indx, :});
                    item = ListItem(label);
                    item.Tag = fileInfo{indx, 1};
                    item.ItemPushedFcn = file.initCallback(@this.recentFileOpen);
                    item.Icon = icon;
                    item.ShowDescription = false;
                    popup.add(item);
                end
            end
        end
        
        function dropDownPerformedCallback(this, ~, ~)
            openSplitOpened(this.Controller);
        end
        
        function recentFileOpen(this, hcbo, ~)
            file     = this.Controller;
            fileInfo = getRecentFiles(file);
            fileName = getRecentFileNameFromText(file, hcbo.Text);
            index = strcmp(string(fileInfo(:, 1)), fileName);
            openFile(file, fileName, fileInfo{index, 2});
        end
        
        function importCallback(this, ~, ~, varargin)
            try
                importItem(this.Controller, varargin{:});
            catch ME
                if isvalid(this.Controller)
                    errorMessage(this.Controller, ME, getString(message('Spcuilib:application:ImportErrorTitle')));
                end
            end
        end
        
        function addSubItems(this, popup, info, callback, icon, tag)
            if iscell(info)
                for indx = 1:numel(info)
                    add(popup, matlab.ui.internal.toolstrip.PopupListHeader(info{indx}{1}));
                    addSubItems(this, popup, info{indx}{2}, callback, icon, tag);
                end
                return;
            end
            file = this.Controller;
            for indx = 1:numel(info)
                if isfield(info(indx), 'icon') && ~isempty(info(indx).icon)
                    iconI = info(indx).icon;
                else
                    iconI = icon;
                end
                item = matlab.ui.internal.toolstrip.ListItem(info(indx).text, iconI);
                item.ItemPushedFcn = file.initCallback(callback, info(indx).tag);
                item.Tag = [tag upper(info(indx).tag(1)) info(indx).tag];
                if isfield(info, 'description') && ~isempty(info(indx).description)
                    item.Description = info(indx).description;
                    item.ShowDescription = true;
                else
                    item.ShowDescription = false;
                end
                popup.add(item);
            end
        end
    end
end

function b = hasDescription(info)

b = false;
if iscell(info)
    for indx = 1:numel(info)
        b = hasDescription(info{indx}{2});
        if b
            return;
        end
    end
    return;
end

b = isfield(info, 'description') && ~all(cellfun(@isempty, {info.description}));

end

function setDefaultDescription(widget, tag, info)

str = getDefaultDescription(tag, info);

if ~isempty(str)
    widget.Description = str;
end

end

function str = getDefaultDescription(tag, info)

str = '';
if iscell(info)
    for indx = 1:numel(info)
        str = getDefaultDescription(tag, info{indx}{2});
        if ~isempty(str)
            return;
        end
    end
else
    
    found = find(strcmp({info.tag}, tag), 1, 'first');
    if ~isempty(found) && isfield(info(found), 'description')
        str = info(found).description;
    end
end

end

% [EOF]
