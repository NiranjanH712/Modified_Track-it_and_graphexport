function [para,error]=multiexpwrapper(data,number,ubtemp,bleach)
% Wrapper for startEXPGlob 
% A Fit is performed with number decay rates. The inital conditions are
% scanned with a grid in order to increase the probability to find the
% global minimum

    disp(['---Multiexponential fit with ' num2str(number) ' dissociation rate(s)---'])
    %Define upper bound for the Fit depending on the number of fitted decay Rates
    ub=zeros(1,3+number+number-1);
    ub(1:number)=inf;
    ub(number+1:2*number-1)=1;
    ub(end-2:end)=ubtemp;

    %Fit of Timelapses to decay rates with bleaching rates
    %**********************************************************************
    %Options for fitting with lsqnonlin
    options=optimoptions('lsqnonlin','algorithm','trust-region-reflective'...
        ,'Tolfun',10^-6,'MaxFunEvals',400,'Display','off','diagnostics','off'...
        ,'jacobian','off');
    
    %Prepare a grid for the search of the global minimum
    for q=1:number
        grids{q}=logspace(-3,1,2);
    end
    x0_all=creategrid(grids);
    
    %delete smallest possible point of the shortest timelapse
    if data{1,1}(1)==data{1,3}
        data{1,1}(1)=[];%time-axis
        data{1,2}(1)=[];%survival function
        disp(['First point deleted in the ' num2str(data{1,3}) ' timelapse'])
    end
    
    %Fit
    disp(['Total Fits:' num2str(size(x0_all,1))])
    fprintf('Current Fit #: ')
    for q=1:size(x0_all,1)
        fprintf(num2str(q))
        x0=[x0_all(q,:),linspace(0.3,0.7,number-1),0.1,10,0];
        if isempty(bleach)
            [para_all{q},SSE(q),~,~,fit_out,~,J{q}]=lsqnonlin(@(para)objEXPGlob(para,data,number),x0,zeros(1,numel(x0)),ub,options);
            %Delete fixed rates
            J{q}(:,end-1:end)=[];
        else
            [para_temp,SSE(q),~,~,fit_out,~,J{q}]=lsqnonlin(@(para)objEXPGlobFixed(para,data,number,bleach),x0(1:end-3),zeros(1,numel(x0)-3),ub(1:end-3),options);
            para_all{q}=[para_temp,bleach];
        end
        for back_idx=1:numel(num2str(q))
        fprintf('\b')
        end
    end

    %Get the starting point with the smallest error
    [~,minidx]=min(SSE);
    para=para_all{minidx};
    %Calculate Confidence-Intervals for the Fitting parameters
    if isempty(bleach)
        [confint,R] = lsqnonlinerror(para(1:end-2),SSE(minidx),J{minidx},cell2mat(data(:,1)),cell2mat(data(:,2)));
        %Calculate Relative Errors
        temp_error=confint'./para(1:end-2);
    else
        [confint,R] = lsqnonlinerror(para(1:end-3),SSE(minidx),J{minidx},cell2mat(data(:,1)),cell2mat(data(:,2)));
        %Calculate Relative Errors
        temp_error=confint'./para(1:end-3);
        temp_error=[temp_error,0];
    end
        
    %Renormalize S
    temp_S=[0.01,para(number+1:(2*number)-1)]/sum([0.01,para(number+1:(2*number)-1)]);
    temp_S(1)=1-sum(temp_S(2:end));
    %Sort Amplitudes according to k
    [temp_k,idx]=sort(para(1:number));
    para=[temp_k,temp_S(idx),para(end-2)];
    %Sort Errors
    temp_error_k=temp_error(1:number);
    temp_error_S=[0,para(number+1:(2*number)-1)];
    error=[temp_error_k(idx),temp_error_S(idx),temp_error(end)];
    error=error.*para;
    
    disp('RESULTS:')
    for q=1:numel(error)
        if q<=number
         disp(['k' num2str(q) ': ' num2str(para(q)) '+-' num2str(error(q))]) 
        end
        
        if and(q>number,q~=numel(error))
         disp(['S' num2str(q-number) ': ' num2str(para(q)) '+-' num2str(error(q))]) 
        end
        
        if q==numel(error)
         disp(['a: ' num2str(para(q)) '+-' num2str(error(q))])  
        end
    end
    
end

%Auxilliary functions
%**************************************************************************
function [ d,J ] = objEXPGlob( para,data,numer )
%Global fit of a multiexponential model to measured data

    %Initialize
    d=[];
    J=[];
    l=size(data);

    %Extract parameters
    k=para(1:numer);
    S=para(numer+1:2*numer-1);
    S=[0.01,S];
    a1=para(end-2);
    a2=para(end-1);
    A=para(end);
    
    
    %Equations for the distance between fit and measurements
    for i=1:l(1)
        %Get measurement
        p=data{i,1};
        ftarg=data{i,2};
        tl=data{i,3};
        
        %Equations
        %Bleaching
        q=(1-A)*exp(-a1/tl*p)+A*exp(-a2/tl*p);
        %Dissociation
        h=0;
        for w=1:numer
            h=h+S(w)*exp(-k(w)*p);
        end
        
        %Combine bleaching and dissociation
        f=q.*h;
        dtemp=f/f(1)-ftarg/ftarg(1);
        %Delete first equation (already used for normalization)
        dtemp(1)=[];
        %Crate array of equations with squared difrences
        d=[d;dtemp];
        
    end
        
end

function [ d,J ] = objEXPGlobFixed( para,data,numer,bleach )
%Global fit of a multiexponential model to measured data with already
%determined bleaching rates

    %Initialize
    d=[];
    J=[];
    l=size(data);

    %Get parameters
    k=para(1:numer);
    S=para(numer+1:2*numer-1);
    S=[0.01,S];
    a1=bleach(1);
    a2=bleach(2);
    A=bleach(3);

    %Equations for the distance between fit and measurements
    for i=1:l(1)
        %Get measurement
        p=data{i,1};
        ftarg=data{i,2};
        tl=data{i,3};

        %Equations
        %Bleaching
        q=(1-A)*exp(-a1/tl*p)+A*exp(-a2/tl*p);
        %Dissociation
        h=0;
        for w=1:numer
            h=h+S(w)*exp(-k(w)*p);
        end

        %Combine bleaching and dissociation
        f=q.*h;
        dtemp=f/f(1)-ftarg/ftarg(1);
        %Delete first equation (already used for normalization)
        dtemp(1)=[];
        %Crate array of equations with squared difrences
        d=[d;dtemp];
    end
    
end

function [paramsets] = creategrid(grid_vals)

        %Create n-dimensional body with mutual combinations of all parameters
        a=cell(1,numel(grid_vals));
        [a{:}]=ndgrid(grid_vals{:});
        paramsets=reshape(cat(numel(grid_vals),a{:}),[],numel(grid_vals));

end
