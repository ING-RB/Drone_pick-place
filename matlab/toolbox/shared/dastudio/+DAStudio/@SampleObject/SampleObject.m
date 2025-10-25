classdef SampleObject < handle
%    DAStudio.SampleObject properties:
%       Path - Property is of type 'ustring'  (read only) 
%       mass - Property is of type 'string'  
%       massUnits - Property is of type 'MassUnitsEnumType enumeration: {'kg','g','mg','slug','lbm'}'  
%       inertia - Property is of type 'string'  
%       inertiaUnits - Property is of type 'InertiaUnitsEnumType enumeration: {'kg*m^2','g*cm^2','slug*ft^2','slug*in^2','lb*ft^2','lb*in^2'}'  
%       positionSchema - Property is of type 'handle vector'  

properties (SetObservable)
    %MASS Property is of type 'string' 
    mass string = '';
    %MASSUNITS Property is of type 'MassUnitsEnumType enumeration: {'kg','g','mg','slug','lbm'}' 
    massUnits DAStudio.Enums.MassUnitsEnumType = DAStudio.Enums.MassUnitsEnumType.kg;
    %INERTIA Property is of type 'string' 
    inertia string = '';
    %INERTIAUNITS Property is of type 'InertiaUnitsEnumType enumeration: {'kg*m^2','g*cm^2','slug*ft^2','slug*in^2','lb*ft^2','lb*in^2'}' 
    inertiaUnits DAStudio.Enums.InertiaUnitsEnumType = DAStudio.Enums.InertiaUnitsEnumType.kgm2;
    %POSITIONSCHEMA Property is of type 'handle vector' 
    positionSchema (1, 3) DAStudio.PositionSchema
end

    methods  % constructor block
        function this = SampleObject()      
        end       
    end

    methods
    end   % set and get functions 

    methods (Hidden) % possibly private or hidden
       %----------------------------------------
       function dlg = getDialogSchema(h, name)
       % ========================================================================= 
       % description group box
       % =========================================================================
       
       txtDescription.Type = 'text';
       txtDescription.Name = sprintf([ 'Represents a user defined rigid body.  Body defined' ...
                                     'by mass m, inertial tensor I, and coordinate origins and' ...
                                     'axes for center of gravity (CG) and other user-specified' ...
                                     'Body coordinate systems.  This dialog sets Body initial' ...
                                     'position and orientation, unless Body and/or connected' ...
                                     'Joints are actuated separately']);
       txtDescription.WordWrap = true;

       grpDescription.Name = 'Body';
       grpDescription.Type = 'group';
       grpDescription.Items = {txtDescription};
       grpDescription.RowSpan = [1 1];
       grpDescription.ColSpan = [1 1];
       
       % ========================================================================= 
       % mass properties group box
       % =========================================================================
       lblMass.Type = 'text';
       lblMass.Name = 'Mass';
       lblMass.RowSpan = [1 1];
       lblMass.ColSpan = [1 1];
       
       txtMass.Type = 'edit';
       txtMass.ObjectProperty = 'mass';
       txtMass.RowSpan = [1 1];
       txtMass.ColSpan = [2 2];
       
       cmbMUnit.Type = 'combobox';
       cmbMUnit.ObjectProperty = 'massUnits';
       cmbMUnit.RowSpan = [1 1];
       cmbMUnit.ColSpan = [3 3 ];
       cmbMUnit.Entries = cellstr(enumeration('DAStudio.Enums.MassUnitsEnumType'));
       
       pnlSpacer.Type = 'panel';
       pnlSpacer.RowSpan = [1 1];
       pnlSpacer.ColSpan = [4 4];
       
       lblIner.Type = 'text';
       lblIner.Name = 'Inertia';
       lblIner.RowSpan = [2 2];
       lblIner.ColSpan = [1 1];
       
       txtIner.Type = 'edit';
       txtIner.ObjectProperty = 'inertia';
       txtIner.RowSpan = [2 2];
       txtIner.ColSpan = [2 2];
       
       cmbIUnit.Type = 'combobox';
       cmbIUnit.ObjectProperty = 'inertiaUnits';
       cmbIUnit.RowSpan = [2 2];
       cmbIUnit.ColSpan = [3 3];
       cmbIUnit.Entries = cellstr(arrayfun(@(x) x.value, enumeration('DAStudio.Enums.InertiaUnitsEnumType')));
       
       txtInerDesc.Type = 'text';
       txtInerDesc.Name = '* with respect to the Center of Gravity CG Body coordinate system';
       txtInerDesc.RowSpan = [2 2];
       txtInerDesc.ColSpan = [4 4];

       grpMassProp.Name = 'Mass properties';
       grpMassProp.Type = 'group';
       grpMassProp.LayoutGrid = [2 4];
       grpMassProp.ColStretch = [0 0 0 1];
       grpMassProp.Items = {lblMass, txtMass, cmbMUnit, pnlSpacer,...
                            lblIner, txtIner,  cmbIUnit, txtInerDesc};
       grpMassProp.RowSpan = [2 2];
       grpMassProp.ColSpan = [1 1];
       
       % ========================================================================= 
       % Body coordinate systems group box
       % ========================================================================= 
       tblPos.Tag  = 'tablePos';
       tblPos.Type = 'table';
       tblPos.Size = [length(h.positionSchema) 9];
       tblPos.Grid = true;
       tblPos.HeaderVisibility = [0 1];
       tblPos.RowHeader = {'col 1', 'col 2', 'col 3'};
       tblPos.ColHeader =  {sprintf('Show\n port'),...
                            sprintf(' Port\n side'),...
                            sprintf('\nName'),...
                            sprintf('Origin position \n vector [x y z]'),...
                            sprintf('\nUnits'),...
                            sprintf('Translated from\n     origin of'),...
                            sprintf('Components in\n     axes of'),...
                            sprintf('Button actions'),...
                            sprintf('Hyperlink actions')}; 
       
       
       tblPos.ColumnCharacterWidth = [4 5 4 11 4 12 11]; 
       tblPos.ColumnHeaderHeight = 2;
       tblPos.ReadOnlyColumns = 2;
       %tblPos.ReadOnlyRows = [0 1];
       
       tblPos.Editable = true;
       tblPos.ValueChangedCallback = @onValueChanged;
       %tblPos.CurrentItemChangedCallback = @onCurrentChanged;
       
       data = {};
       for i=1:length(h.positionSchema)
           s = h.positionSchema(i);
       
           % position rows
           chkShowPort.Type = 'checkbox';
           chkShowPort.ObjectProperty = 'showPort';
           chkShowPort.Source = s;
           data{i, 1} = chkShowPort;
           
           % port side
           cmbPortSide.Type = 'combobox';
           cmbPortSide.ObjectProperty = 'portSide';
           cmbPortSide.Source = s;
           cmbPortSide.Entries = cellstr(enumeration('DAStudio.Enums.PortSide'));
           data{i, 2} = cmbPortSide;
           
           % name
           strName.Type = 'edit';
           strName.ObjectProperty = 'name';
           strName.Source = s;
           data{i, 3} = strName;
           
           % origin position vector
           strOriginPos.Type = 'edit';
           strOriginPos.ObjectProperty = 'originPosVector';
           strOriginPos.Source = s;
           data{i, 4} = strOriginPos;
       
           % units
           cmbUnits.Type = 'combobox';
           cmbUnits.ObjectProperty = 'units';
           cmbUnits.Source = s;
           cmbUnits.Entries = cellstr(enumeration('DAStudio.Enums.Units'));
           data{i, 5} = cmbUnits;
           
           % origin
           cmbOrigin.Type = 'combobox';
           cmbOrigin.ObjectProperty = 'origin';
           cmbOrigin.Source = s;
           cmbOrigin.Entries = cellstr(enumeration('DAStudio.Enums.Space'));
           data{i, 6} = cmbOrigin;
           
           % axes
           cmbAxes.Type = 'combobox';
           cmbAxes.ObjectProperty = 'axes';
           cmbAxes.Source = s;
           cmbAxes.Entries = cellstr(enumeration('DAStudio.Enums.Space'));
           data{i, 7} = cmbAxes;
           
           %button actions
           button.Name = 'My button';
           button.Type = 'pushbutton';
           button.Enabled = true;
           data{i, 8} = button;
       
           %hyperlink actions
           link.Name = 'My Hyperlink';
           link.Type = 'hyperlink';
           link.Enabled = true;
           data{i, 9} = link;
       
       end
       
       tblPos.Data = data;
       tblPos.SelectedRow = 2;
       tblPos.ItemClickedCallback = @ItemClicked;
       
       % ========================================================================= 
       % Tab widget example
       % ========================================================================= 
       pnlPosition.Name  = 'Position';
       pnlPosition.Items = {tblPos};
       
       pnlOrientation.Name = 'Orientation';
       
       tabBodyCoord.Type = 'tab';
       tabBodyCoord.Tabs = {pnlPosition, pnlOrientation};
       
       grpBodyCoord.Name = 'Body coordinate systems';
       grpBodyCoord.Type = 'group';
       grpBodyCoord.Items = {tabBodyCoord};
       grpBodyCoord.ColSpan = [1 1];
       grpBodyCoord.RowSpan = [3 3];
       
       % ========================================================================= 
       % Main dialog
       % ========================================================================= 
       dlg.DialogTitle = 'Block Parameters: Body';
       dlg.DialogTag = 'SampleObject_Dialog';
       dlg.HelpMethod  = 'doc';
       dlg.HelpArgs    = {'simulink'};
       dlg.Items       = {grpDescription, grpMassProp, grpBodyCoord};
       dlg.LayoutGrid  = [3 1];
       dlg.RowStretch  = [0 0 1];
       end  % getDialogSchema
       
       
       % ========================================================================= 
       % value changed callback
       % ========================================================================= 

        %----------------------------------------
       function getPropertyStyle(h, name, retVal)
       if strcmp(name, 'mass')
           massN = str2num(h.mass);
           if massN < 0        
               retVal.ForegroundColor = [1 .5 0];
               retVal.BackgroundColor = [0 .7 .1];
               retVal.Tooltip = 'Mass cannot be negative';
               retVal.Icon = 'toolbox/shared/dastudio/resources/warning.bmp';        
           else
               retVal.BackgroundColor = [1 0 0];
               retVal.Tooltip = 'Mass is ok';
           end
       end
       
       if strcmp(name, 'Name')
           retVal.ForegroundColor = [1 0 0];
       end
       
       if strcmp(name, 'Path')
           retVal.BackgroundColor = [1 0 0];
       end
       
       if strcmp(name, 'massUnits')
           retVal.Tooltip = 'Units of mass!';
       end
       
       if strcmp(name, 'inertia')
           retVal.Icon = 'toolbox/shared/dastudio/resources/info.png';
           retVal.IconAlignment = 'right';
       end
       
       end  % getPropertyStyle
       
        %----------------------------------------
       function sampleMethod(h, prop1, prop2, prop3)
         disp(prop1)
         disp(prop2)
         disp(prop3)
       end  % sampleMethod
       
end  % possibly private or hidden 

end  % classdef

function onValueChanged(d, r, c, val)

if isstr(val) 
  disp(sprintf('item at (%d, %d) changed to ''%s''', r,c,val));
else
  disp(sprintf('item at (%d, %d) changed to %d', r,c,val));
end
end  % onValueChanged


% ========================================================================= 
% current changed callback
% =========================================================================
function onCurrentChanged(d, r, c)
  disp(sprintf('selected item at (%d, %d)', r,c));
end  % onCurrentChanged


function ItemClicked(d, r,c, str)
disp('in ItemClickedCallback')
disp(sprintf('item ''%s'' at (%d, %d) is clicked.', str, r, c));
end  % ItemClicked


