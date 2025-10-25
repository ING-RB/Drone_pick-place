classdef TextEditDialog < handle  
    properties (Constant)
        CUSTOM_COLOR_ITEM = 0;
    end

    properties(SetObservable=true)
        canvas = []; 
        cab = [];
    end
    
    methods (Static)

        function list = getColorNameList()
            list = {...
                DAStudio.message('mg:textedit:ColorCustom'),...
                DAStudio.message('mg:textedit:ColorNone'),...
                DAStudio.message('mg:textedit:ColorWhite'),...
                DAStudio.message('mg:textedit:ColorBlack'),...
                DAStudio.message('mg:textedit:ColorDarkRed'),...
                DAStudio.message('mg:textedit:ColorRed'),...
                DAStudio.message('mg:textedit:ColorOrange'),...
                DAStudio.message('mg:textedit:ColorYellow'),...
                DAStudio.message('mg:textedit:ColorBrightGreen'),...
                DAStudio.message('mg:textedit:ColorLightGreen'),...
                DAStudio.message('mg:textedit:ColorGreen'),...
                DAStudio.message('mg:textedit:ColorLightBlue'),...
                DAStudio.message('mg:textedit:ColorBrightBlue'),...
                DAStudio.message('mg:textedit:ColorBlue'),...
                DAStudio.message('mg:textedit:ColorDarkBlue'),...
                DAStudio.message('mg:textedit:ColorTurquoise'),...
                DAStudio.message('mg:textedit:ColorPink'),...
                DAStudio.message('mg:textedit:ColorPurple') };
        end
        
        function name = getIndexColorName(index)
            if index == -1
                name = DAStudio.message('mg:textedit:ColorUndefined');
            else
                list = TextEdit.TextEditDialog.getColorNameList();
                name = list{index + 1};
            end
        end
        
        function index = getColorNameIndex(name)
            if ~ischar(name)
                index = 0;
            else
                list = TextEdit.TextEditDialog.getColorNameList();
                for k = 1:length(list)
                    if strcmp(list{k}, name)
                        index = k - 1;
                        return;
                    end
                end
                index = -1;
            end
        end
        
    end
end
