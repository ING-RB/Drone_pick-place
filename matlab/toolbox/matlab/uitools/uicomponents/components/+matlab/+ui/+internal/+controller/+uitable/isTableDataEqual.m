% util method called from c++ model to compare table data.
function isEqual = isTableDataEqual (oldTable, newTable)

    % Step 1: use isequaln to check table equality. 
    % NaN, NaT, missing and undefined values are treated as equal to other
    % such values.
    isEqual = isequaln(oldTable, newTable);

    % Step 2: check meta data for equal tables.
    % - Format property of datetime and duration array.
    if isEqual && istable(oldTable)
        for idx = 1:length(oldTable.Properties.VariableNames)

            oldTableDataAtIdx = oldTable.(idx);
            newTableDataAtIdx = newTable.(idx);
            
            % validate same data type.
            if ~strcmp(class(oldTableDataAtIdx), class(newTableDataAtIdx))
                isEqual = false;
                break;
            end
            
            % validate metadata if same data type.
            switch class(oldTableDataAtIdx)
                % compare Format property for datetime and duration.
                case {'datetime', 'duration', 'calendarDuration'}
                    isEqual = isequal(oldTableDataAtIdx.Format, newTableDataAtIdx.Format);                    
                % compare categories, protected for categorical data.
                % MATLAB isequal() returns equal for two categorical data with
                % different categories. (g2042046)
                case 'categorical'
                    isEqual = isequal(categories(oldTableDataAtIdx), categories(newTableDataAtIdx)) && ...
                              isequal(isprotected(oldTableDataAtIdx), isprotected(newTableDataAtIdx));

                case 'cell'
                    % If both tables are cellstr, we can continue to the next column.
                    if iscellstr(oldTableDataAtIdx) && iscellstr(newTableDataAtIdx)
                        continue;
                    end
                    
                    % Not equal if data types change
                    classOld = cellfun(@class,oldTableDataAtIdx,'UniformOutput',false);
                    classNew = cellfun(@class,newTableDataAtIdx,'UniformOutput',false);
                    if ~isequal(classOld,classNew)
                        isEqual = false;
                        break;
                    end
                                        
                    % Otherwise, we need to check if any categoricals have
                    % different categories or protected status.

                    % Get all categorical cells
                    categoricalIdx = find(cellfun(@iscategorical,newTableDataAtIdx));

                    if ~isempty(categoricalIdx)
                       categoricalFromOld = oldTableDataAtIdx(categoricalIdx);
                       categoricalFromNew = newTableDataAtIdx(categoricalIdx);
                       isEqual = ~(isCategoriesNotEqual(categoricalFromOld, categoricalFromNew) || ...
                           isProtectedNotEqual(categoricalFromOld, categoricalFromNew));
                    end
                    
                otherwise
                    % no op - tables are truly equal.
            end
            
            if ~isEqual
                break; % Done if we found something different.
            end     
        end
    end
end

function categoriesNotEqual = isCategoriesNotEqual(categoricalFromOld, categoricalFromNew)
    % Check if categories are not equal in any cell
    oldCategories = cellfun(@categories,categoricalFromOld,'UniformOutput',false);
    newCategories = cellfun(@categories,categoricalFromNew,'UniformOutput',false);
    categoriesNotEqual = any(~cellfun(@isequal,oldCategories,newCategories));
end

function protectedNotEqual = isProtectedNotEqual(categoricalFromOld, categoricalFromNew)
    % Check if protected is not equal in any cell
    oldProtected= cellfun(@isprotected,categoricalFromOld,'UniformOutput',false);
    newProtected= cellfun(@isprotected,categoricalFromNew,'UniformOutput',false);
    protectedNotEqual = any(~cellfun(@isequal,oldProtected,newProtected));
end