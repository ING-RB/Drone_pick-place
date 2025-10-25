classdef DataspaceMixin < handle
     %

     % Copyright 2017 The MathWorks, Inc.
    methods
        function  addPolarProperties(this, obj, hasVariables)
            props = {'RData','ThetaData','ThetaDataMode','RDataSource','ThetaDataSource'};
            if nargin>2 && hasVariables
                props = [props 'RDataMode' 'RVariable' 'ThetaVariable'];
            end
            this.addDynamicProps(obj,props);
        end
        
        function addCartesianProperties(this, obj, hasVariables)
            props = {'XData','XDataMode','YData','ZData','XDataSource','YDataSource','ZDataSource'};
            if nargin>2 && hasVariables
                props = [props 'YDataMode' 'ZDataMode' 'XVariable' 'YVariable' 'ZVariable'];
            end
            this.addDynamicProps(obj,props);
        end
        
        function addGeoProperties(this, obj, hasVariables)
            props = {'LatitudeData','LongitudeData','LatitudeDataSource','LongitudeDataSource'};
            if nargin>2 && hasVariables
                props = [props 'LatitudeDataMode' 'LongitudeDataMode' 'LatitudeVariable' 'LongitudeVariable'];
            end
            this.addDynamicProps(obj,props);
        end  
        
        function addDataTipDynamicProperties(this,objs,props)
            obj = objs(1);
            for i = 1:numel(props)
                pi = this.addprop(props{i});
                this.(pi.Name) = obj.(pi.Name);
            end
        end
        
        function addDynamicProps(this,objs,props)
            % if there are multiple objects, take the first one and add the
            % properties to the view class
            obj = objs(1);
            for i = 1:numel(props)
                pi = this.addprop(props{i});
                this.(pi.Name) = obj.(pi.Name);
                
                if endsWith(pi.Name, "DataMode")
                    xdmProp = findprop(obj,pi.Name);
                    % Need to explicitly set the property type in the inspector's PropertyTypeMap because you can't set the type of a dynamically added property
                    this.PropertyTypeMap(pi.Name)= xdmProp.Type;
                end
            end
        end
    end
end

