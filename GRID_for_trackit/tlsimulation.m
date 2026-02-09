function [data]=tlsimulation(para,mu,tl,N,la)
%All input have to be row vectors. The simulation can be performed
%according to measured probabilities of dissociation rates or to a model
%distribution depending on the association rates

    %Prepare and extract variables
    data={};
    S=para(1:numel(mu));
    a1=para(end-2)./tl;
    a2=para(end-1)./tl;
    A=para(end);
    
    %Generate Probabilities according to spectra or equilibrium
    if isempty(la)
        p=S/sum(S);
    else
        p=la.*mu/sum(la.*mu);
    end
    
    %Simulate all timelapses
    for q=1:numel(tl)
        
        %Effective rates and distribution due to bleaching
        peff=[(1-A)*p,A*p];
        mueff=[a1(q)+mu,a2(q)+mu];
        
        %Perform simulation for a single timelapse
        [t,binding]=singletlsimulation(peff,mueff,tl(q),N(q));
        
        %A single datapoint is not enough
        if numel(t)>1
            data{q,1}=t';
            data{q,2}=binding';
            data{q,3}=tl(q);
        else
            disp('Simulation did not contain enough points. Trying again...')
        end
        disp('Simulation finished')    
    end
end

%**************************************************************************
function [t,binding]=singletlsimulation(p,mu,tl,N)
    
    %Evaluate partition of TF on sites
    count=0;
    t=tl:tl:1000*tl;
    binding=zeros(1,length(t));
    
    %Simulate until enough points have been captured or comutation time is
    %exeeded
    while and(sum(binding)<N,count<10^7)
        %Throw dice to determine current TF binding type
        %type=choose(p);
        type=choose(p);
        
        %Dice binding time
        tau=-log(rand)/mu(type);

        if tau>t(1)
            binding(sum(tau>t))=binding(sum(tau>t))+1;
        else
            count=count+1;
        end
    end
    
    %Cumulate for survival function
    binding=fliplr(cumsum(fliplr(binding)));
    
    %Delete empty fields
    t(binding==0)=[];
    binding(binding==0)=[];

end


%Choose a random element from a probability distribution
function [ choice ]=choose(vector)

    %random number
    z=rand(1);
    
    %decision
    for n=1:numel(vector)
        if z<=vector(n)
            choice=n;
            break
        else
            vector(n+1)=vector(n+1)+vector(n);
        end
    end
    
end
