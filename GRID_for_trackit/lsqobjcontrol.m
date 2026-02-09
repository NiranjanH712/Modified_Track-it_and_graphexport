function [costFun, tlCurves, fitCurves]=lsqobjcontrol(result,data)
% Objective function for determining dissociation rate spectra
% The cost function costFun contains the difference between Fit an measured
% values and the regularization for the mean decay rate of the TF
% population

%delete smallest possible point of the shortest timelapse
    if data{1,1}(1)==data{1,3}
        data{1,1}(1)=[];%time-axis
        data{1,2}(1)=[];%survival function
    end

    %Initialization of variables
    %**********************************************************************
    costFun=[];  
    idx=1;
    tlCurves = {};
    fitCurves = {};

    %Assign parameters
    %**********************************************************************
    S=result.S;
    k=result.k;
    a=result.a1;
    numtls=size(data);
    
    
    %Cost function for difference between fit and measurement 
    for m=1:numtls(1)
        %read m-th measured timelapse 
        p=cell2mat(data(m,1));         
        ftarg=cell2mat(data(m,2));     
        n=1:1:length(p);    
        
        %Calculate model function
        %Decay Spectrum
        h=calch(S,k,p);

        %Bleaching
        q=exp(-a*n');
        
        %Calculate differences
        eq0=(q./q(idx)).*h./h(idx)-ftarg./ftarg(idx);
        costFun=[costFun;eq0];  
        fitCurves{m} = [p, q./q(idx).*h./h(idx)];
        tlCurves{m} = [p ftarg./ftarg(idx)];        
    end


end

%Auxilliary functions
%**************************************************************************
function [ h ] = calch( S,k,p )
%CALCh calculate h with Laplacetrafo
%      S Amplitude k decay-rates

    %Transformation-matrix
    A=Transmat(p,k);
    
    %Transformation
    h=A*S';

end

function [ A ] = Transmat( p,k )
%TRANSMAT Transformationmatrix for forward laplace trafo 
%   Transformationmatrix A  MxN-Matrix
    
    %Variablen Starten  
    M=numel(p);
    N=numel(k);
    A=ones(M,N);
     
    %Transformationsmatrix
    for m=1:M
        for n=1:N
            A(m,n)=exp(-k(n)*p(m));
        end
    end

end
