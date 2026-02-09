function parameter=GRIDparameter(varargin)
%Generate Standard parameters for GRID
%Replace default values from name/value arguments in varargin

    parameter=struct(...
        'kSpec',logspace(-3,2,100),...
        'E',1e-2,...
        'lbq',0,...
        'ubq',0.5,...
        'x0',0.001,...
        'b',[]);
    try
        for q=1:2:numel(varargin)
            parameter.(varargin{q})=varargin{q+1};
        end
    catch
        disp('Specified option does not exist')
    end
   
end