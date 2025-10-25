classdef ObjectArrayDisp < matlab.mixin.CustomDisplay
%ObjectArrayDisp   Custom display methods.

    methods (Sealed, Access = protected)
        function displayNonScalarObject(obj)
            try
                isdesktop = desktop('-inuse');
            catch
                isdesktop = false;
            end
            
            if ~isrow(obj) || ~isdesktop
                displayNonScalarObject@matlab.mixin.CustomDisplay(obj);
                return;
            end
            
            DispInfo = getDispInfo(obj);
            dispHeader(DispInfo,numel(obj));
            obj.displayVariableBody(DispInfo);
            displayFooter(DispInfo);
        end
    end

    methods (Abstract, Access = 'protected')
        DispInfo = getDispInfo(obj);
    end

    methods (Access = 'protected')
        function C = postProcessFields(~,C,~)
            % No Op unless overridden
        end
    end
    
    methods (Access = 'private')
        function d = displayVariableBody(obj,DisplayInfo)
            data = DisplayInfo.Data;
            prodSymb = matlab.internal.display.getDimensionSpecifier;
            fields = fieldnames(data);
            
            C = permute(struct2cell(data),[1,3,2]);
            % for cell variables, we want to keep the {}
            classes = cellfun(@class,C,'UniformOutput',false);
            
            % convert cell to string
            isEmptyCell = cellfun(@isempty,C);
            C(isEmptyCell) = {''};
            % any cell of size > 1 needs to be converted to char array before
            % converting to string
            idx = cellfun(@iscellstr,C);
            idx = find(idx == 1);
            
            singleCells = zeros(numel(idx),1);
            for ii = 1 : numel(idx)
                [m,n] = size(C{idx(ii)});
                if m == 1 && n == 1
                    singleCells(ii) = idx(ii);
                    C{idx(ii)} = ['', C{idx(ii)}{1},''];
                else
                    C{idx(ii)} = ['',num2str(m), prodSymb, num2str(n),' cell'];
                end
            end
            singleCells(singleCells == 0) = [];
            C = string(C);
            
            % truncate string scalar values to 30 characters,
            % and replace newline characters with their display equivalent
            idx = [find(contains(C,{newline,char(13)})); find(strlength(C) > 30)];
            % Check if MATLAB desktop is available and pass this
            % information to truncateLine API to make sure the API does not
            % have to query this on every iteration of the for loop
            doesMATLABUseDesktop = matlab.internal.display.isDesktopInUse;
            for ii = 1 : numel(idx)
                C(idx(ii)) = matlab.internal.display.truncateLine(C(idx(ii)),30,doesMATLABUseDesktop);
            end
            
            C(singleCells) = "'" + C(singleCells) + "'";
            C(classes == "cell") = "{" + C(classes == "cell") + "}";
            
            C = obj.postProcessFields(C,data);
            
            
            C(classes == "char") = "'" + C(classes == "char") + "'";
            C(C == "") = "{}";
            % construct the variable index headers (1),(2),(3), ...
            C = [compose("(%d)",1:size(data,2));C];
            for ii = 1 : size(C,2)
                C(:,ii) = pad(C(:,ii),max(strlength(C(:,ii))),"left");
            end
            
            % get the variable names (Name, Type, FillValue, etc.)
            d = [""; string(fields) + ":"];
            d = pad(d,max(strlength(d(:)))+2,"left");
            fprintf("%s\n",join(d + " " + join(C," | ",2),newline));
        end
    end
end

function dispHeader(DispInfo,n)
if matlab.internal.display.isHot()
    name = "<a href=""matlab:helpPopup "+DispInfo.LongName+""" style=""font-weight:bold"">"+DispInfo.ShortName+"</a>";
else
    name = DispInfo.ShortName;
end
d = "  1"+ matlab.internal.display.getDimensionSpecifier;
fprintf("  %s",getString(message('MATLAB:ObjectText:DISPLAY_AND_DETAILS_ARRAY_WITH_PROPS', d + n,name)));
if isfield(DispInfo,'Title')
    fprintf("\n\n   %s:\n",DispInfo.Title);
end
end

function displayFooter(DispInfo)
if isfield(DispInfo,'Footer')
    fprintf('%s',DispInfo.Footer);
end
end

%   Copyright 2022-2024 The MathWorks, Inc.