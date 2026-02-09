function [result,output]=spectrumfitwrapper(parameter,dataFit,simuMode)
% start code for spectral analysis of tls
%      fit with fmincon 
%      optimized for use with gradient
%      needs input: dataFit -- cellarray with p,n-vectors and tls
%                   parameter -- struct with solver parameters
%                   SimuMode -- Mode for simulation with less detailed
%                               Outputfcn
%
%      For use without GUI, simumode must be set to 1

%disp('This is the Solver for the spectrum + bleaching rate')  

%Initialize
%**************************************************************************
%Determine discrete fixed k-Values
k=parameter.kSpec;
%Options for fmincon
options = optimoptions('fmincon','Algorithm','sqp','GradObj','on','GradConstr','on','Display','off'...
    ,'CheckGradients',false,'MaxIterations',1000,'FiniteDifferenceType','central');
switch simuMode
    case 1
        options.OutputFcn=[];
    case 0
        options.OutputFcn=@DispStatus;
end

%Regularisation
%**************************************************************************
N=numel(k);
S=zeros(1,N);
%Lower and Upper bounds for Amplitudes
lb=[S,parameter.lbq];
ub=[S+1,parameter.ubq];

%Add individual parameters
x0=[S+1/N,0.01];

%Normalization of Amplitudes
Aeq=zeros(1,numel(x0));
Aeq(1:N)=1;

%Weight of the Death Time Regularization
E=parameter.E;
%Extract Death time from Dataset
tau=[dataFit{1,3},2*dataFit{1,3}];
%Set normalization position
idx=1;

%**************************************************************************
%delete smallest possible point of the shortest timelapse
if dataFit{1,1}(1)==dataFit{1,3}
    dataFit{1,1}(1)=[];%time-axis
    dataFit{1,2}(1)=[];%survival function
    disp(['First point deleted in the ' num2str(dataFit{1,3}) ' timelapse'])
end


%Perform Fitting
%**************************************************************************
[paraopt,~,~,output]=fmincon(@(para)lsqobj(para,k,dataFit,E,tau,idx),x0,[],[],Aeq,1,lb,ub,@(para)constr(para,parameter.b),options);

%Struct for output 
result=struct('k',k,'S',paraopt(1:numel(k)),'a1',paraopt(end));

%Calculate error
output.error=lsqobj(paraopt,k,dataFit,0,tau,idx);
output.residuals=lsqobjcontrol(result,dataFit);

end

function [c,ceq,gc,gceq]=constr(para,b)
    ceq=[];
    gceq=[];
    c=[];
    gc=[];
    if not(isempty(b))
        S=para(1:end-1);
        c=sum(S.^2)-b;
        gc=2*S';
        gc=[gc;0];
    end
end

