function [ d,grad ]=lsqobj(para,k,data,E,tau,idx)
% Objective function for determining dissociation rate spectra
% The cost function d contains the difference between Fit an measured
% values and the regularization for the mean decay rate of the TF
% population

    %Initialization of variables
    %**********************************************************************
    d=0;  
    ceq=0;    
    gradceq=zeros(numel(para),1);
    gradreg=zeros(numel(para),1);

    %Assign parameters
    %**********************************************************************
    S=para(1:length(k));
    a=para(length(k)+1);
    
    %Constraints for Global Fit
    %**********************************************************************
    numtls=size(data);
    start=1;
    
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

        %Calculate squared differences
        eq0=q./q(idx).*h./h(idx)-ftarg./ftarg(idx);
        ceqt=eq0.^2;
        
        %Delete First Equation (yields 1=1 due to normalization)

        %Generate Gradient
        gradh1=gradh(eq0,q,h,p,k,start,idx);
        gradq1=gradq( eq0,q,h,a,start,idx);
        gradceqt=[gradh1;gradq1];

        %Bind Constraint and Gradient
        ceq=ceq+sum(ceqt); 
        gradceq=gradceq+gradceqt;
    end


    %Regularization for the dead time
    %**********************************************************************
    %Initialize variables
    A=Transmat(tau,k);
    %Calculate mean decay-rate at borders t
    kquer=A*(k.*S)'./(A*S');

    %Regularisation
    reg=0.5*(kquer(1)-kquer(2))^2;

    %Gradient of Regularisation
    temp1=A(1,:)'/(A(1,:)*S').*(k-kquer(1))';
    temp2=A(2,:)'/(A(2,:)*S').*(k-kquer(2))';
    gradreg(1:numel(S))=(kquer(1)-kquer(2))*(temp1'-temp2');


    %Calculate complete cost function 
    %**********************************************************************
    d=ceq+E*reg;
    grad=gradceq+E*gradreg;


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

function [ gradS ] = gradh( eq0,q,h,p,k,start,idx )
%GRADH Calculate gradient for the decay of population
    
    %Derivative with respect to Si
    A=Transmat(p,k)';
    
    gradS=zeros(numel(k),1);
    
    %Derivative
    for n=start:numel(p)
        gradS=gradS+2*eq0(n)*q(n)/q(idx)*(A(:,n)/(h(idx))-A(:,idx)*(h(n))/(h(idx))^2);
    end
    
    
    
end

function [ gradq ] = gradq( eq0,q,h,a,start,idx )
%GRADQ   Gradient for bleaching
%        n:row vector
%        eq0:collumnvector
%        gradq: 3xj     j=length(n)   

    gradq=0;    

    for n=start:numel(eq0)
        %gradq=gradq+2*eq0(n)*(h(n))/(h(norm(n))).*(-n*exp(-a*n)/q(norm(n))+norm(n)*q(n)/q(norm(n))^2*exp(-norm(n)*a));
        gradq=gradq+2*eq0(n)*(h(n))/(h(idx)).*(idx-n)*exp(a*(-n+idx));
    end

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
