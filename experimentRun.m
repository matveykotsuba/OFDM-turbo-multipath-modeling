function results = experimentRun(cfg, cases, snrValues)
    cfg = config(cfg);
    validateattributes(snrValues, {'numeric'}, {'real','finite','vector','nonempty'});
    if ~isstruct(cases) || isempty(cases) || ~all(isfield(cases,{'label','cfg'}))
        error('course:Cases','cases must contain label and cfg fields.');
    end
    for k = 1:numel(cases)
        cases(k).cfg = config(cases(k).cfg);
        if ~ischar(cases(k).label), error('course:Cases','Case labels must be character vectors.'); end
    end
    savedRng = rng;
    restoreRng = onCleanup(@() rng(savedRng));
    rng(cfg.experiment.seed, 'twister');
    results = struct();
    results.cfg = cfg;
    results.snrDb = snrValues(:).';
    results.labels = {cases.label};
    results.cases = cases;
    results.params = cell(1,numel(cases));
    results.channelStats = cell(numel(cases),numel(snrValues)); % First block at each point.
    names = {'BER','BLER','bitErrors','totalBits','crcErrors','totalPackets', ...
        'bitErrorPackets','squaredBitErrors','BLERLower95','BLERUpper95', ...
        'BLERZeroUpper95','BERZeroUpper95','BERStandardError','BERLower95','BERUpper95'};
    for n = 1:numel(names), results.(names{n}) = NaN(numel(cases),numel(snrValues)); end
    results.completed = false(numel(cases),numel(snrValues));
    results.complete = false; results.checkpointFile = '';
    results.statistics = struct('confidence',0.95,'sampling','fixed block count', ...
        'blerInterval','Wilson, pointwise','berInterval','normal approximation over independent blocks', ...
        'zeroBound','exact one-sided, based on independent blocks', ...
        'commonRandomNumbers',logical(cfg.experiment.commonRandomNumbers));
    if cfg.experiment.checkpointEnabled
        folder = fullfile(cfg.experiment.outputDir,'checkpoints');
        if ~exist(folder,'dir'), mkdir(folder); end
        results.checkpointFile = [tempname(folder) '.mat'];
    end
    started = tic;
    totalPoints=numel(cases)*numel(snrValues);
    if cfg.experiment.verbose
        blocks=sum(arrayfun(@(c)c.cfg.experiment.packetsPerPoint,cases))*numel(snrValues);
        bits=sum(arrayfun(@(c)c.cfg.experiment.packetsPerPoint*c.cfg.coding.tbLength,cases))*numel(snrValues);
        fprintf('Planned: %d points, %d transport blocks, %.0f information bits\n', ...
            totalPoints,blocks,bits);
        if min(arrayfun(@(c)c.cfg.experiment.packetsPerPoint,cases)) < 500
            fprintf('PREVIEW sample size: curves may fluctuate; inspect stored uncertainty.\n');
        end
    end
    for k = 1:numel(cases)
        if cfg.experiment.verbose, fprintf('Case %d/%d: %s\n',k,numel(cases),cases(k).label); end
        pointCfg = cases(k).cfg;
        for s = 1:numel(snrValues)
            pointCfg.channel.snrDb = snrValues(s);
            if cfg.experiment.commonRandomNumbers
                rng(cfg.experiment.seed, 'twister');
            end
            point = simulationPoint(pointCfg);
            if s == 1, results.params{k} = point.params; end
            results.channelStats{k,s}=point.channelStats;
            for n = 1:numel(names), results.(names{n})(k,s) = point.(names{n}); end
            results.completed(k,s) = true;
            results.complete = all(results.completed(:));
            results.elapsedSeconds = toc(started);
            if cfg.experiment.checkpointEnabled, saveCheckpoint(results); end
            if cfg.experiment.verbose
                completed=(k-1)*numel(snrValues)+s;
                elapsed=toc(started);remaining=elapsed/completed*(totalPoints-completed);
                fprintf('  SNR=%6.2f dB, BER=%.6g, BLER=%.6g, bitErr=%d/%d, CRC=%d/%d\n', ...
                    snrValues(s),point.BER,point.BLER,point.bitErrors,point.totalBits,point.crcErrors,point.totalPackets);
                fprintf('  Progress %d/%d; elapsed %.1f min; remaining ~%.1f min\n',completed,totalPoints,elapsed/60,remaining/60);
                if ~point.channelStats.payload_cp_sufficient
                    fprintf('  ISI possible: channel exceeds payload CP by %d samples.\n',point.channelStats.payload_excess_delay_samples);
                end
            end
        end
    end
    results.elapsedSeconds = toc(started);
end

function saveCheckpoint(results)
    target = results.checkpointFile;
    pending = [target '.pending'];
    save(pending,'results','-v7');
    [ok,msg] = movefile(pending,target,'f');
    if ~ok, error('course:Checkpoint','%s',msg); end
end
