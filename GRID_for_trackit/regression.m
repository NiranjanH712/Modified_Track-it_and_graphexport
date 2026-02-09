function [d,m,b]=regression(x,T)

    A=zeros(2,2);
    A(1,1)=sum(x);
    A(1,2)=numel(x);
    A(2,1)=sum(x.^2);
    A(2,2)=sum(x);
    
    b(1,1)=sum(T);
    b(2,1)=sum(T.*x);
    
    r=A\b;
    
    m=r(1);
    b=r(2);
    
    d=norm(T-m*x+b);
    
%     figure
%     plot(x,T,'+')
%     hold on
%     plot(x,m*x+b)

end