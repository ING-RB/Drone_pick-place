classdef UpdateSection < handle
    %
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties(Access = protected)
        Mode           %Mode this section is part of
        Section = [];  %Toolstrip section
        Panel   = [];  %Toolstrip panel
        Widgets = [];  %Panel widgets
    end
    
    properties(GetAccess = public, SetAccess = protected)
        SaveAsEnabled
    end
    
    methods
        function obj = UpdateSection(varargin)
            %UPDATESECTION
            %(Mode,SaveAsEnabled)
            
            %Set object properties
            if nargin > 0
                obj.Mode = varargin{1};
            end
            if nargin > 1
                obj.SaveAsEnabled = varargin{2};
            else
                obj.SaveAsEnabled = true;
            end
        end
        function sec = getSection(this)
            %GETSECTION
            %
            
            if isempty(this.Section)
                createSection(this)
                connectGUI(this)
            end
            sec = this.Section;
        end
        function setEnabled(this,val)
            %SETENABLED
            %
            
            this.Widgets.btnSave.Enabled = val;
        end
    end
    
    %Testing API
    methods(Hidden = true)
        function wdgts = getWidgets(this)
            %GETWIDGETS
            %
            
            wdgts = this.Widgets;
        end
    end
    
    methods(Access = protected)
        function createSection(this)
            %CREATESECTION
            %
            
            %Create section for update
            import matlab.ui.internal.toolstrip.*
            secTitle = getString(message('Controllib:dataprocessing:lblUpdate'));
            ApplyStr = getString(message('Controllib:dataprocessing:lblUpdate'));

            if this.SaveAsEnabled
                btnSave = SplitButton(ApplyStr, Icon('greenCheck'));
            else
                btnSave = Button(ApplyStr, Icon('greenCheck'));
            end
            btnSave.Tag = 'btnSave';
            sec = Section(secTitle); %#ok<CPROP>
            sec.Tag = 'secUpdate';
            Col1 = Column('HorizontalAlignment','left');
            Col1.addEmptyControl();
            Col = Column('HorizontalAlignment','center');
            Col.add(btnSave);
            Col2 = Column('HorizontalAlignment','left');
            Col2.addEmptyControl();
            sec.add(Col1);
            sec.add(Col);
            sec.add(Col2);

            % Store the widgets for later use
            this.Section = sec;
            this.Widgets = struct(...
                'btnSave',        btnSave);
        end
        function connectGUI(this)
            %CONNECTGUI
            %
            
            %Add listener to btnSave events
            hBtn = this.Widgets.btnSave;
            PushEvt = 'ButtonPushed';
            if this.SaveAsEnabled
                addlistener(hBtn,PushEvt,@(hSrc,hData) cbApply(this));
                createSaveAsMenuItems(this, hBtn);
            else
                addlistener(hBtn,PushEvt,@(hSrc,hData) cbApply(this));
            end
        end
        function mnu = createSaveAsMenuItems(this,hBtn)
            %CREATESAVEASMENUITEMS Create SaveAs menu items
            %

            %Create menu
            mnu = matlab.ui.internal.toolstrip.PopupList;
            mnu.Tag = 'mnuSave';
            %Add "Apply" item
            item = matlab.ui.internal.toolstrip.ListItem;
            item.Tag           = 'itemApply';
            item.Text          = getString(message('Controllib:dataprocessing:lblUpdate'));
            item.Description   = getString(message('Controllib:dataprocessing:lblUpdate_Description'));
            item.Icon          = matlab.ui.internal.toolstrip.Icon('greenCheck');
            item.ItemPushedFcn = @(source,data) cbApply(this);
            add(mnu,item);
            %Add "SaveAs" item
            item = matlab.ui.internal.toolstrip.ListItem;
            item.Tag           = 'itemSaveAs';
            item.Text          = getString(message('Controllib:dataprocessing:lblSaveAs'));
            item.Description   = getString(message('Controllib:dataprocessing:lblSaveAs_Description'));
            item.Icon          = matlab.ui.internal.toolstrip.Icon('saved');
            item.ItemPushedFcn = @(source,data) cbSaveAs(this);
            add(mnu,item);
            
            %Install the menu on the button
            hBtn.Popup = mnu;
        end
        
        function cbSaveAsMenuItemSelected(this,hSrc)
            %CBSAVEASMENUITEMSELECTED
            %
            item = hSrc.Items(hSrc.SelectedIndex);
            name = item.Name;
            switch name
                case 'itemApply'
                    cbApply(this);
                case 'itemSaveAs'
                    cbSaveAs(this);
            end
        end
        
        function cbApply(this)
            %CBAPPLY Apply
            %
            
            save(this.Mode)
        end
        
        function cbSaveAs(this)
            %SAVEAS Save-As
            %
            saveAs(this.Mode);
        end
        
    end
end