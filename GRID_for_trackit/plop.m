classdef plop
    %Predition of LOss Probability
    
    properties
        para                    % Tracking Parameters
        batch                   % batch-file 
        subRegionNum            % Sub-region number (leave empty to use all tracks)
        subRoiBorderHandling = 'Assign by first appearance';    % Defines how tracks touching sub-region borders should be handled
        data                    % GRID-Format for binding times
        data_diff               % GRID-Format for jump histogram                  
        rho                     % Effective mobility
        txt_out
        rho_bit=false;
        
        %Algorithm options
        f=0.7348;  %Nearest neighbour integral value
        mdstart=[0.1,6]; %Search window for z
        op_z_max_iteration=20; %maximum tracking iterations
        op_z_tol=1e-2; %tolerace in search for z
    end
  
    methods
        %------------------------------------------------------------------
        function obj = plop(batch1, subRegionNum)
            %Constructor
            obj.batch=batch1;
            obj.subRegionNum = subRegionNum;
            if not(isempty(batch1))  
                %Convert to GRID dataset
                obj.data = create_grid_data_from_batch_file(obj.batch, obj.subRegionNum);
                %Initialize tracking parameters for all timelapses
                obj.para = plop.initialize_para(cell2mat(obj.data(:,3))');
                obj.rho=zeros(1,numel(obj.para.tls));
            end
        end
        
        %------------------------------------------------------------------
        function obj = find_spots(obj,folder)
            %Get settings for spot detection
            trackingPara.boolFindSpots = true;            
            trackingPara.thresholdFactor = obj.para.SNR(1);
            
            %Get settings for tracking
            tls=obj.para.tls*1000;  %Convert tl to ms
            trackingPara.tlConditions = tls';
            trackingPara.trackingRadius = obj.para.maxdisp';
            trackingPara.minTrackLength = obj.para.shortest_track';
            trackingPara.gapFrames = obj.para.darkframe;
            trackingPara.minLengthBeforeGap = obj.para.minSegLength';            
            trackingPara.frameRange = [1 inf];
            trackingPara.trackingMethod = 'Nearest neighbour';
            trackingPara.subRoiBorderHandling = obj.subRoiBorderHandling;
            trackingPara.trackItVersion = '';
            
            %Start main tracking routine
            obj.batch = tracking_routine(obj.batch, trackingPara, [], obj.txt_out);
            
            %Initialize rho
            obj.rho=zeros(1,numel(obj.para.tls)); 
        end
        
        %------------------------------------------------------------------
        function obj = tracking(obj)
            
            %Get settings for spot detection
            trackingPara.boolFindSpots = false;            
            trackingPara.thresholdFactor = obj.para.SNR(1);
            
            %Get settings for tracking
            tls=obj.para.tls*1000;  %Convert tl to ms
            trackingPara.tlConditions = tls';
            trackingPara.trackingRadius = obj.para.maxdisp';
            trackingPara.minTrackLength = obj.para.shortest_track';
            trackingPara.gapFrames = obj.para.darkframe;
            trackingPara.minLengthBeforeGap = obj.para.minSegLength';            
            trackingPara.frameRange = [1 inf];
            trackingPara.trackingMethod = 'Nearest neighbour';
            trackingPara.subRoiBorderHandling = obj.subRoiBorderHandling;
            trackingPara.trackItVersion = '';
            
            %Start main tracking routine
            obj.batch = tracking_routine(obj.batch, trackingPara, [], obj.txt_out);

            %Convert to GRID dataset
            obj.data = create_grid_data_from_batch_file(obj.batch, obj.subRegionNum);
        end
        
        %------------------------------------------------------------------
        function obj=run(obj,p_loss)

            %Calculate suggested trackingradius
            [obj.para.maxdisp,~]=get_maxdisp_op(obj,p_loss);
            
            %Get settings for spot detection
            trackingPara.boolFindSpots = false;            
            trackingPara.thresholdFactor = obj.para.SNR(1);
            
            %Get settings for tracking
            tls=obj.para.tls*1000;  %Convert tl to ms
            trackingPara.tlConditions = tls';
            trackingPara.trackingRadius = obj.para.maxdisp';
            trackingPara.minTrackLength = obj.para.shortest_track';
            trackingPara.gapFrames = obj.para.darkframe;
            trackingPara.minLengthBeforeGap = obj.para.minSegLength';
            trackingPara.subRoiBorderHandling = obj.subRoiBorderHandling;
            trackingPara.frameRange = [1 inf];
            trackingPara.trackingMethod = 'Nearest neighbour';
            trackingPara.trackItVersion = '';
            
            %Start main tracking routine
            obj.batch = tracking_routine(obj.batch, trackingPara, [], obj.txt_out);

            %Convert to GRID dataset
            obj.data = create_grid_data_from_batch_file(obj.batch, obj.subRegionNum);
        end
        
        %------------------------------------------------------------------
        function [s,p_loss]=get_maxdisp_op(obj,p_loss_tl)
            %Calculate p_loss for longest timelapse
            z_m=log(1/p_loss_tl);
            p_loss=obj.p_loss_forward(z_m,numel(obj.para.tls));

            %Calculate z0 for other timelapses
            for q=1:numel(obj.para.tls)
                z(q)=obj.solve_p2z(p_loss,q);
            end

            %Calculate tracking radius from z
            for q=1:numel(obj.para.tls)
                s(q)=obj.op_z(z(q),q);
            end
        end
        
        %------------------------------------------------------------------
        function [z2]=solve_p2z(obj,p_loss_target,idx)
            %Start point
            z2=log(1/p_loss_target);
            z1=0;
            count=0;

            %Iteration until stepsize smaller than 1e-8
            while abs(z1-z2)>1e-8
                z1=z2;
                if obj.para.darkframe(idx)
                    p_dark=plop.df_loss(sqrt(z1),obj.para.tls(idx));
                else
                    p_dark=1;
                end
                p_loss=(p_loss_target-pi*obj.f*obj.rho(idx))...
                    /(1-pi*obj.f*obj.rho(idx));
                z2=log(p_dark/p_loss);
                count=count+1;
                %Break if iteration does not converge
                if count>100
                    disp('Max. Iteration count exeeded. Stopping...')
                    disp(['Final step size: ' num2str(abs(z1-z2))])
                    break
                end
            end

        end

        %------------------------------------------------------------------
        function [md_m,count]=op_z(obj,z_t,idx)

            %Filter for tl
            batchF=plop.filter_batch_for_tl(obj.batch,obj.para.tls(idx));
            pa=obj.get_tl_para(idx);

            %Correct cut jump distribution
            g=1;
            z_t=(1/z_t-g/(exp(g*z_t)-1))^-1;

            %Initialize Iteration      
            z_m=2*z_t;
            count=0;
            md=obj.mdstart;
            
            %Search for tracking radius and z_t
            while and(abs(z_m-z_t)>obj.op_z_tol,count<obj.op_z_max_iteration)
                md_m=(md(2)-md(1))/2+md(1);
                pa.maxdisp=md_m;
                
                %----------------------------------------
                %Get settings for spot detection
                trackingPara.boolFindSpots = false;
                trackingPara.thresholdFactor = obj.para.SNR(1);
                
                %Get settings for tracking
                tls=pa.tls*1000;  %Convert tl to ms
                trackingPara.tlConditions = tls';
                trackingPara.trackingRadius = pa.maxdisp';
                trackingPara.minTrackLength = pa.shortest_track';
                trackingPara.gapFrames = pa.darkframe;
                trackingPara.minLengthBeforeGap = pa.minSegLength';
                trackingPara.frameRange = [1 inf];
                trackingPara.trackingMethod = 'Nearest neighbour';
                trackingPara.subRoiBorderHandling = obj.subRoiBorderHandling;
                trackingPara.trackItVersion = '';
                
                %Start main tracking routine
                batchF = tracking_routine(batchF, trackingPara, [], obj.txt_out);
                
                %----------------------
                jumps=plop.getdiffusion(batchF,obj.para.tls(idx),obj.subRegionNum);
                y=mean(jumps.^2);
                z_m=md_m^2/y;
                if z_m-z_t<0
                    md=[md_m,md(2)];
                else
                    md=[md(1),md_m];
                end
                count=count+1;
            end
            
            %Report
            disp(['Iteration stopped at '...
                num2str(count) '. Accuracy is ' num2str(abs(z_m-z_t))])
            
        end
        
        %------------------------------------------------------------------
        function pa=get_tl_para(obj,idx)
            %Convert to single timelapse parameters
            pa=obj.para;
            h=fieldnames(pa);
            for q=1:numel(h)
                pa.(h{q})=pa.(h{q})(idx);
            end
        end
        
        %------------------------------------------------------------------
        function p_loss=p_loss_forward(obj,z_m,idx)
            %Calculate p_loss
            A=1;
            if obj.para.darkframe(idx)
                A=plop.df_loss(sqrt(z_m),obj.para.tls(idx))...
                    *(1-pi*obj.f*obj.rho(idx)*(1+z_m));
            end
            p_loss=pi*obj.f*obj.rho(idx)+exp(-z_m)*A;
        end
        
        %------------------------------------------------------------------
        function []=zofs(obj,idx,x)   
            %Plot the dependence z(s)
            batchF=plop.filter_batch_for_tl(obj.batch,obj.para.tls(idx));
            parameters=obj.get_tl_para(idx);
            %Vary tracking radius
            for q=1:numel(x)
                parameters.maxdisp=x(q);
                
                
                %----------------------------------------
                %Get settings for spot detection
                trackingPara.boolFindSpots = false;
                trackingPara.thresholdFactor = obj.para.SNR(1);
                
                %Get settings for tracking
                tls=parameters.tls*1000;  %Convert tl to ms
                trackingPara.tlConditions = tls';
                trackingPara.trackingRadius = parameters.maxdisp';
                trackingPara.minTrackLength = parameters.shortest_track';
                trackingPara.gapFrames = parameters.darkframe;
                trackingPara.minLengthBeforeGap = parameters.minSegLength';
                trackingPara.frameRange = [1 inf];
                trackingPara.trackingMethod = 'Nearest neighbour';
                trackingPara.subRoiBorderHandling = obj.subRoiBorderHandling;
                trackingPara.trackItVersion = '';
                
                %Start main tracking routine
                batchF = tracking_routine(batchF, trackingPara, [], obj.txt_out);
                
                
                %----------------------
                
                %Calculate sigma squared
                jumps=plop.getdiffusion(batchF,obj.para.tls(idx),obj.subRegionNum);
                y=mean(jumps.^2);
                z(q)=x(q)^2/y;
            end
            %Generate Figure
            figure
            ax=gca;hold(ax,'on');
            plot(x,z)
        end
        
        %------------------------------------------------------------------
        function data_res=resampling(obj,N,p)
            %Moviewise resampling
            used=floor(p*numel(obj.batch));
            for idx=1:N
                batch1=obj.batch;
                for q=1:(numel(obj.batch)-used)
                    del_idx=ceil(rand*numel(batch1));
                    batch1(del_idx)=[];
                end
                data_res{idx}=create_grid_data_from_batch_file(batch1, obj.subRegionNum);
            end
        end
    end
    
    methods(Static)
        
        %------------------------------------------------------------------
        function para = initialize_para(tls)
            %Initialize parameters with standard values
            temp=ones(1,numel(tls));
            para=struct( 'maxdisp',1*temp,...
                'darkframe',0*temp,...
                'shortest_track',2*temp,...
                'SNR',1.2*temp,...
                'minSegLength',2*temp,...
                'tls',tls);
            
        end
        
        %------------------------------------------------------------------
        function jumps=getdiffusion(batch,tl,subRegionNum)
            %Get all jumpdistances for single tl condition
            jumps=[];
            
            for q=1:numel(batch)
                if tl*1000==batch(q).movieInfo.frameCycleTime
                    
                    if isempty(subRegionNum)
                        res = batch(q).results;
                    else
                        res = batch(q).results.subRegionResults(subRegionNum);
                    end
                    for w=1:numel(res.jumpDistances)
                        jumps=[jumps;res.jumpDistances{w}];
                    end
                end
            end
        end
        
        
        %------------------------------------------------------------------
        function rho=get_density(batch,tl)
            %Get density
            rho=[];
            for q=1:numel(batch)
               if tl*1000==batch(q).movieInfo.frameCycleTime
                   res=batch(q).results;
                   for w=1:numel(res.spotsAll)
                        %Normalize all spots by ROI
                        rho=[rho,size(res.spotsAll{w},1)/res.roiSize];
                   end
               end
            end 
        end
        
        %------------------------------------------------------------------
        function rho_eff=get_eff_density(batch,tl)
            %Density * surface coverage
            for q=1:numel(tl)
                rho=plop.get_density(batch,tl(q));
                jumps=plop.getdiffusion(batch,tl(q));
                rho_eff(q)=mean(jumps.^2)*mean(rho);
            end
        end
        
        %------------------------------------------------------------------
        function vector=get_field(batch,fieldname,tl)
            %Get all jumpdistances for single tl condition
            vector=[];
            for q=1:numel(batch)
                if tl*1000==batch(q).movieInfo.frameCycleTime
                    res=batch(q).results;
                    if iscell(res.(fieldname))
                        for w=1:numel(res.(fieldname))
                            vector=[vector;res.(fieldname){w}];
                        end
                    else
                        vector=[vector;res.(fieldname)];
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function batchF=filter_batch_for_tl(batch,tl)
            %Filter batch for a single tl condition
            tl=tl*1000;
            count=1;
            for q=1:numel(batch)
                if batch(q).movieInfo.frameCycleTime==tl
                    batchF(count)=batch(q);
                    count=count+1;
                end
            end
        end
        
        %------------------------------------------------------------------
        function p=df_loss(s,tl)
            %Calculate tracking loss for tracking with 1 darkframe and
            %minseglength=2
            %Integration borders
            c=0.5-tl/(1+2*tl);
            A=(1-c)/(1+c);
            
            %Contributions from different areas
            I1=A*integral3(@(r,phi,rs)integrand(r,phi,rs,A),...
                2*s,inf,0,2*pi,0,s/(1-c));
            I2=2*A*integral3(@(r,phi,rs)integrand(r,phi,rs,A),...
                s,2*s,@(r)ymin(r,s),pi,0,s/(1-c));
            I3=2*A*integral3(@(r,phi,rs)integrand(r,phi,rs,A),...
                s,2*s,0,@(r)ymin(r,s),0,@(r,phi)(r./(2*cos(phi)))/(1-c));
            
            %Factor by which loss probability changes
            p=1-(I1+I2+I3)*exp(s^2);
            
            %Function for Integration border
            function b=ymin(r,s)
                b=(acos(r/2/s));
            end
            
            %Integrand
            function y=integrand(r,phi,rs,A)
                y=exp(-(r.^2+rs.^2-2.*r.*rs.*cos(phi))*A-r.^2).*r.*rs*2/pi;
            end
        end
        
        %------------------------------------------------------------------
        function [result,tr_mean]=compare_constructs(experiment,rho_bit,p_loss)
            %Analyse a set of constructs
            %Search best tracking parameters 
            for idx=1:numel(experiment)
%                 experiment(idx).rho=plop.get_eff_density(...
%                     experiment(idx).batch,experiment(idx).para.tls);
%                 experiment(idx)=experiment(idx).run(p_loss);
%                 experiment(idx).rho=plop.get_eff_density(...
%                     experiment(idx).batch,experiment(idx).para.tls);
                experiment(idx)=experiment(idx).run(p_loss);
                tr(idx,:)=experiment(idx).para.maxdisp;
            end
            
            tr_mean=mean(tr,1);

            for idx=1:numel(experiment)
                
                for idx2=1:numel(experiment(idx).para.tls)
                    flag=0;
                    for idx3=1:numel(experiment)
                        if experiment(idx).para.tls(idx2)~=experiment(idx3).para.tls(idx2)
                            flag=1;
                        end
                    end
                    if flag==1
                        experiment(idx).para.maxdisp(idx2)=tr(idx,idx2);
                    else
                        experiment(idx).para.maxdisp(idx2)=tr_mean(idx2);
                    end
                end

                experiment(idx)=experiment(idx).tracking();
            end

            %Report
%             figure
%             axGRID=gca;
%             hold(axGRID,'on')
             paras=GRIDparameter();
%             paras.kSpec=logspace(-4,2,150);
%             axGRID.XScale='log';
                for idx=1:numel(experiment)
                [result(idx),~]=spectrumfitwrapper(paras,experiment(idx).data,1); 
              % plot(axGRID,result(idx).k,result(idx).S./result(idx).k)
                end
            
        end
        
        %------------------------------------------------------------------
        function result=fit_two_state_paths(jumps,T)
            [y,r]=hist(jumps,linspace(min(jumps),max(jumps),200));
            y=fliplr(cumsum(fliplr(y)));
            y=y/y(1);

            [para,d]=fmincon(@(para)dist(para,r,y,T),[1,1,1,1],[],[],[],[],[0.1,1,0,0.001],[10,10,10,10]);
            
            result.para=para;
            result.d=d;
            result.ytarget=y;
            
            %Report
            figure
            plot(r,y,'+')
            hold on
            plot(r,plop.twostate_diff_paths(para(1),para(2),para(3),para(4),r,T))
            
            function d=dist(para,r,y,T)
                p=plop.twostate_diff_paths(para(1),para(2),para(3),para(4),r,T);
                p=1-p;
                d=sum((p-y).^2);
            end
        end
        
        %------------------------------------------------------------------
        function p=twostate_diff_paths(la,mu,D1,D2,r,T)
            %Calculate transient jump distances in a two state model

            %Calculate Path Integral foreach r
            for q=1:numel(r)
                %initial=mu/(la+mu)*exp(-mu*T)*(1-exp(-r(q)^2./(4.*D2.*T)))+la/(la+mu)*exp(-la*T)*(1-exp(-r(q)^2./(4.*D1.*T)));
                initial=exp(-mu*T)*(1-exp(-r(q)^2./(4.*D2.*T)));
                p(q)=integral(@(t)integrand(t,T,la,mu,r(q),D1,D2),0,T)+initial;
            end

            p=1-p;

            %--------------------------------------
            function I=integrand(t,T,la,mu,r,D1,D2)
                u=sqrt(mu.*la.*t.*(T-t));
                f=exp(-mu.*t-la.*(T-t)).*(mu.*besseli(0,2.*u)+u./(T-t).*besseli(1,2.*u));
                I=f.*(1-exp(-r^2./(4.*D1.*t+4.*D2.*(T-t))));
            end
            %--------------------------------------

        end
  
    end
    
end

