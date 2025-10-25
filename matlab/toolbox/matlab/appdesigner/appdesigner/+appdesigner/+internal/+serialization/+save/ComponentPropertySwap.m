classdef ComponentPropertySwap < appdesigner.internal.serialization.save.interface.DecoratorComponentDataAdjuster
    %COMPONENTPROPERTYSWAP A decorator class that swaps component
    %properties.  This is useful for swapping/porting Alaised Property Values
    %into real Property Values

    % Copyright 2021-2024 The MathWorks, Inc.

    methods
        function obj = ComponentPropertySwap(dataAdjuster)
            obj@appdesigner.internal.serialization.save.interface.DecoratorComponentDataAdjuster(dataAdjuster);
        end

        function componentsStructure = adjustComponentDataPreSave(obj)
            nargoutchk(1,1);

            componentsStructure = obj.DataAdjuster.adjustComponentDataPreSave();

            componentsStructureUIFigure = componentsStructure.UIFigure;

            % For UIFigure, the AD_AliasedThemeChangedFcn property allows
            % customization of the ThemeChangedFcn callback at design time.
            % The AD_AliasedThemeChangedFcn property is not saved (it is transient).
            % Before saving, we reassign the non-default AD_AliasedThemeChangedFcn
            % property values to the real ThemeChangedFcn property of the UIFigure.
            if isprop(componentsStructureUIFigure, 'AD_AliasedThemeChangedFcn') && ... 
                    ~isempty(componentsStructureUIFigure.AD_AliasedThemeChangedFcn)
                componentsStructureUIFigure.ThemeChangedFcn = componentsStructureUIFigure.AD_AliasedThemeChangedFcn;
                componentsStructureUIFigure.AD_AliasedThemeChangedFcn = '';
            end

            % For UIAxes, the AD_AliasedVisible Property facilitates custom
            % design-time opacity/transparency when the user sets the
            % UIAxes Visible off.  The AliasedVisible property is not saved
            % (it is transient).  Before saving, we reassign the non-default
            % AliasedVisible property values to the real Visible property of the UIAxes.
            allInvisibleAxes = findall(componentsStructureUIFigure, 'Type', 'Axes', 'AD_AliasedVisible', 'off');
            if ~isempty(allInvisibleAxes)
                [allInvisibleAxes.Visible] = deal('off');
            end
            
        end

        function adjustComponentDataPostSave(obj, componentsStructure)

            componentsStructureUIFigure = componentsStructure.UIFigure;

            % After saving, restore the design-time state of the UIFigure by
            % swaping the AD_AliasedThemeChangedFcn property with actual callback 
            % and ThemeChangedFcn property to empty. This ensures that any
            % design-time customizations to the ThemeChangedFcn callback are
            % preserved and the ThemeChangedFcn is cleared, maintaining the
            % transient nature of the aliased property.
            if isprop(componentsStructureUIFigure, 'ThemeChangedFcn') && ... 
                    ~isempty(componentsStructureUIFigure.ThemeChangedFcn)
                componentsStructureUIFigure.AD_AliasedThemeChangedFcn = componentsStructureUIFigure.ThemeChangedFcn;
                componentsStructureUIFigure.ThemeChangedFcn = '';
            end
            
            % After saving, turn all design-time UIAxes Visible properties
            % back to 'on'.  The AD_AliasedVisible property is unchanged.
            % Note: The code below is faster than having a more specific
            % findall call.
            allAxes = findall(componentsStructureUIFigure, 'Type', 'Axes');
            if ~isempty(allAxes)
                [allAxes.Visible] = deal('on');
            end

            obj.DataAdjuster.adjustComponentDataPostSave(componentsStructure);
        end
    end
end
