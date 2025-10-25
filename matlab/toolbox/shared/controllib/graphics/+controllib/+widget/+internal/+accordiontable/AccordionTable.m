classdef AccordionTable < controllib.widget.internal.accordiontable.CommonHTMLTable
    % AccordionTable class for pushing data to a accordiontable webpage. Relies on
    % TableAccordionData to populate/edit the appearance of the table
    properties (Access = private)
        DataListeners
    end
    methods (Access = protected)
        function tad = validateTableDataImpl(accordTable,tad)
            arguments
                accordTable (1,1) %#ok<INUSA>
                tad (1,1) controllib.widget.internal.accordiontable.TableAccordionData
            end
        end
        function executeCB(this,js_ed)
            % keep certain UI actions in sync with data automatically (e.g.
            % collapsing accordions)
            ed = js_ed.JSEventData;
            switch ed.Type
                case "AccordionCollapsed"
                    a = ed.Data.AccordIdx;
                    v = ed.Data.Collapsed;
                    setAccordionCollapsed(this.TableData,a,v);
            end
            executeCB@controllib.widget.internal.accordiontable.CommonHTMLTable(this,js_ed);
        end
    end
    methods
        function this = AccordionTable(parent,tableData,tableChangedFcn)
            arguments
                parent
                tableData (1,1) controllib.widget.internal.accordiontable.TableAccordionData
                tableChangedFcn = []
            end
            
            path = fullfile(matlabroot,"toolbox","shared",...
                "controllib","graphics","web","accordiontable","accordiontable.html");
            
            this.TableData = tableData;
            createHTMLObj(this,parent,path);
            this.TableChangedFcn = tableChangedFcn;
            
            %% setup listeners
            this.DataListeners    = addlistener(this.TableData,'TableUpdated',@(src,ed) updateUI(this));
            this.DataListeners(2) = addlistener(this.TableData,'ObjectBeingDestroyed',@(src,ed) delete(this));
        end
        function delete(this)
            delete(this.DataListeners);
            delete@controllib.widget.internal.accordiontable.CommonHTMLTable(this);
        end
    end
end