function [confint,R] = lsqnonlinerror(para,SSE,J,x,y)

    %Prepare degrees of freedom 
    numf=numel(x);
    nump=numel(para);
    %Prepare measure for distance between fit and model
    SST=var(y);
    %Prepare diagonal of inverse designmatrix
    J=full(J);
    invdesign=inv(J'*J);
    invdesign=diag(invdesign);
    
    %Adjusted R-squared
    R=1-SSE/(SST*(numf-nump));  
    
    %Error of coeficients
    confint=tinv(1-0.05/2,numf-nump)*sqrt(invdesign*SSE/(numf-nump));

end

