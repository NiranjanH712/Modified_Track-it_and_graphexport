function [dataSim]=tlsimulation_timedep(parameters)
    %Extract parameters
    S=parameters.S;
    a=parameters.a;
    mu=paramters.k;
    tls=parameters.tls;
    N=parameters.N;
    type=parameters.type;

    %Simulation
    dataSim={};
    switch type
        case 'classic'
            for q=1:numel(tls)
                [tl,h]=tlsimulation_log(S,a,mu,0:tls(q):300*tls(q),N,[]);
                dataSim(q,:)={tl(2:end)',h(2:end)',0.05};
            end
        case 'ITM'
            for q=1:numel(tls)
                timeseq=genitm(0.01,tls(q));
                [tl,h]=tlsimulation_log(S,a,timeseq,N,[]);
                dataSim(q,:)={tl(3:end)',h(3:end)',1};       
            end
        otherwise
            disp('Argument not recognized')
    end

end

% -------------------------------------------------------------------------
function t=genitm(ti,ttl)
    %Generate itm time series
    t=[0,0.04,0.16];
    for q=4:3:300
        t([q:q+2])=t(q-1)+ttl+[0,0.04,0.16]; 
    end
 
end

% -------------------------------------------------------------------------
function [tl,h]=tlsimulation_log(S,a,mu,tl,N)
%All input have to be row vectors. The simulation can be performed
%according to measured probabilities of dissociation rates or to a model
%distribution depending on the association rates

    %Prepare and extract variables 
    h=zeros(1,numel(tl));
    
    %Simulate until N events have been recorded
    count=0;
    while h(2)<N
        [h]=determinesingle(tl,h,mu(choose(S)),a);
        count=count+1;
        if count>10^8
           disp('Maximum Simulation Time Exceeded') 
           break
        end
    end 
end

% -------------------------------------------------------------------------
function [h]=determinesingle(tl,h,mu,a)

    flag=0;
    frameidx=2;
    %Roll dice until dissociation or bleaching event happes 
    while and(flag==0,frameidx<=numel(tl))
        dt=tl(frameidx)-tl(frameidx-1);
        if or(rand>exp(-a),-log(rand)/mu<dt)
            %Save binding time
            h(1:frameidx-1)=h(1:frameidx-1)+1;
            flag=1;
        else
             frameidx=frameidx+1;
        end     
    end
    
    %Case: molecule survived the whole movie
    if frameidx>numel(tl)
        h(1:frameidx-1)=h(1:frameidx-1)+1; 
    end

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





