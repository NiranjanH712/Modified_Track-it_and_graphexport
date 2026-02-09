function [para,errors,m,b]=keffanalysis(ax,data,N,mode)
    %Perform N-exp-fit to individual time-lapses
    for q=1:size(data,1)
        [para(q,:),errors(q,:)]=multiexpwrapper(data(q,:),N,[1,0,0],[0,0,0]);
    end
    
    %Transform x,y axis to schow keff for framewise or time effects
    if mode
        x=1./cell2mat(data(:,3));
    else
        x=cell2mat(data(:,3));
        for q=1:N
            para(:,q)=para(:,q).*x;
            errors(:,q)=errors(:,q).*x;
        end
    end
    
    %Regression
    for q=1:N
        [r(q),m(q),b(q)] = regression(x',para(:,q)'); 
    end
    
    %Plot fit results
    if not(isempty(ax))
        hold(ax,'on')
        for q=1:N
        errorbar(ax,x,para(:,q),errors(:,q),'b+')
        end
        for q=1:N
            plot(x,m(q)*x+b(q))
        end
        if mode
            xlabel('\tau_{tl}^{-1}')
            ylabel('k_{eff}')
        else
            xlabel('\tau_{tl}')
            ylabel('k_{eff}\cdot\tau_{tl}')
        end
    end
    
    
    
    
end



