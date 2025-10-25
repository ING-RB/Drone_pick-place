classdef CommonHTMLTable < handle
    properties
        TableData
        TableChangedFcn = []
    end
    properties (Dependent)
        Layout
    end
    properties (SetAccess = protected,Hidden)
        % assumes the HTML object is built upon construction
        HTML
    end
    properties (Access = protected)
        % received a response by from JS by pushing data
        ReceivedCBResponse (1,1) logical = false
    end
    methods (Access = protected)
        function data = validateTableDataImpl(this,data)  %#ok<INUSL>
        end
        function createHTMLObj(this,parent,path)
            % create the uihtml object given a parent container and path to
            % the HTML file
            html = uihtml("Parent",parent,"HTMLSource",path,....
                "Data",this.TableData,....
                "DataChangedFcn",@(src,ed) htmlCBBridge(this,src,ed));
            matlab.ui.internal.HTMLUtils.enableTheme(html);
            this.HTML = html;
            % add a listener when the html obj is deleted
            addlistener(html,'ObjectBeingDestroyed',@(src,ed) delete(this));
        end
    end
    methods
        function delete(this)
            delete(this.HTML);
        end
        function set.Layout(this,val)
            this.HTML.Layout = val;
        end
        function val = get.Layout(this)
            val = this.HTML.Layout;
        end
        function set.TableData(this,data)
            arguments
                this (1,1)
                data (1,1) controllib.widget.internal.accordiontable.CommonHTMLData
            end
            data = validateTableDataImpl(this,data);
            this.TableData = data;
        end
        function set.TableChangedFcn(this,f)
            if isempty(f)
                f = [];
            else
                validateTableChangeFcn(this,f)
            end
            this.TableChangedFcn = f;
        end
        function updateUI(this)
            % revert the received response flag
            this.ReceivedCBResponse = false;
            % push changes to the data onto the html object
            this.HTML.Data = this.TableData;
        end
    end
    methods (Hidden)
        function waitUntilBuilt(this)
            % wait until the HTML object is built. Useful for qe methods.
            while ~isHTMLBuilt(this)
                drawnow();
            end
        end
        function qeSimulateElementChange(this,elementID,v)
            % QE helper method to simulate element changes in the UI
            
            % make sure the accordtable is built
            waitUntilBuilt(this);
            
            % push changes onto the QEHTMLData field
            this.TableData.QEHTMLData = struct(...
                'Type','change',...
                'Data',struct(...
                    'ElementID',elementID,...
                    'Value',v));
            % update the UI
            updateUI(this);
            % make sure callback is fired
            drawnow();
            % after pushing, make sure the qe data is reset
            this.TableData.QEHTMLData = [];
        end
        function qeSimulateElementClick(this,elementID)
            % QE helper method to simulate element clicks in the UI
            
            % make sure the accordtable is built
            waitUntilBuilt(this);
            
            % push changes onto the QEHTMLData field
            this.TableData.QEHTMLData = struct(...
                'Type','click',...
                'Data',struct(...
                    'ElementID',elementID));
            % update the UI
            updateUI(this);
            % make sure callback is fired
            drawnow();
            % after pushing, make sure the qe data is reset
            this.TableData.QEHTMLData = [];
        end
        function val = isHTMLBuilt(this)
            val = this.TableData.HTMLIsBuilt;
        end
    end
    methods (Access = protected)
        function validateTableChangeFcn(this,f)
            arguments
                this (1,1) %#ok<INUSA> 
                f (1,1) function_handle %#ok<INUSA> 
            end
        end
        function executeCB(this,js_ed)
            % overloadable
            feval(this.TableChangedFcn,this,this.TableData,js_ed);
        end
        function htmlCBBridge(this,~,ed)
            % HTML callback bridge. Will redirect to user defined callback
            if ~isHTMLBuilt(this)
                this.TableData.HTMLIsBuilt = ed.Data.HTMLIsBuilt;
            end
            if ~isempty(this.TableChangedFcn) && numel(fields(ed.Data.JSEventData))
                executeCB(this,ed.Data)
                this.ReceivedCBResponse = true;
            end
        end
    end
end