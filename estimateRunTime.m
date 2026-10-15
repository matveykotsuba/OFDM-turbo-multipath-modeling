function estimate = estimateRunTime(cfg, scenario, pilotPackets)
    if nargin<1||isempty(cfg),cfg=config();else,cfg=config(cfg);end
    if nargin<2||isempty(scenario),scenario='snr';end
    if nargin<3||isempty(pilotPackets),pilotPackets=3;end
    validateattributes(pilotPackets,{'numeric'},{'scalar','real','integer','>=',2,'finite'});
    plan=simulationPlan(cfg,scenario);
    saved=rng;restore=onCleanup(@()rng(saved));
    rng(cfg.experiment.seed,'twister');
    seconds=zeros(1,numel(plan.cases));pointCounts=seconds;samples=cell(size(seconds));
    for k=1:numel(plan.cases)
        row=plan.cases(k);c=row.cfg;c.experiment.verbose=false;
        c.channel.snrDb=row.snrDb(ceil(numel(row.snrDb)/2));
        main(c,[]); % Warm each case; exclude cold first-call/JIT overhead.
        values=zeros(1,pilotPackets);
        for n=1:pilotPackets
            started=tic;main(c,[]);values(n)=toc(started);
        end
        seconds(k)=mean(values);pointCounts(k)=numel(row.snrDb);samples{k}=values;
    end
    secondsPerPass=sum(seconds.*pointCounts);margin=1.2;
    estimate=struct('plan',plan,'pilotPacketsPerCase',pilotPackets,'samplesSeconds',{samples}, ...
        'secondsPerPacketByCase',seconds,'pointCounts',pointCounts,'safetyFactor',margin, ...
        'rawEstimatedMinutes',secondsPerPass*plan.packetsPerPoint/60, ...
        'estimatedMinutes',margin*secondsPerPass*plan.packetsPerPoint/60, ...
        'packetsFor30Minutes',max(1,floor(30*60/(margin*secondsPerPass))), ...
        'packetsFor60Minutes',max(1,floor(60*60/(margin*secondsPerPass))), ...
        'timestamp',datestr(now,30));
    fprintf('%s: %d points x %d blocks = %d TB = %.0f information bits\n', ...
        scenario,plan.points,plan.packetsPerPoint,plan.transportBlocks,plan.informationBits);
    fprintf('Estimate with 20%% margin: %.2f min; 30 min: %d blocks/point; 60 min: %d blocks/point\n', ...
        estimate.estimatedMinutes,estimate.packetsFor30Minutes,estimate.packetsFor60Minutes);
end
