function summary=runtimeSelfTest(outputDir)
    if nargin<1,outputDir=fullfile(tempdir,'course-runtime-tests');end
    cfg=config();cfg.experiment.verbose=false;
    scenarios={'snr','mcs','delaySpread','ber','reportBler','reportMcs','16qamDelay'};
    expected=[36 90 90 93 270 81 60];
    for k=1:numel(scenarios)
        p=simulationPlan(cfg,scenarios{k});
        assert(p.points==expected(k)&&p.transportBlocks==cfg.experiment.packetsPerPoint*expected(k));
        assert(p.informationBits==p.transportBlocks*1000);
    end
    cfg.experiment.packetsPerPoint=2;cfg.coding.tbLength=16;
    cfg.coding.enabled=false;cfg.receiver.equalizerEnabled=false;
    cfg.experiment.snrAwgnDb=[10 100];cfg.experiment.snrTdlDb=[10 100];
    cfg.experiment.snrDb=[10 100];cfg.experiment.separateSnrDb=[10 100];
    cfg.experiment.modulations={'QPSK'};cfg.experiment.mcs=cfg.experiment.mcs(1);
    cfg.experiment.delaySpreadsNs=120;cfg.experiment.legacy16qamDelaySpreadsNs=120;
    cfg.experiment.outputDir=outputDir;
    p=simulationPlan(cfg,'ber');
    assert(p.points==4&&p.transportBlocks==8&&p.informationBits==128);
    before=rng;e=estimateRunTime(cfg,'snr',2);assert(isequal(before,rng));
    assert(e.estimatedMinutes>0&&numel(e.samplesSeconds{1})==2);
    assert(e.packetsFor30Minutes>=1&&e.packetsFor60Minutes>=e.packetsFor30Minutes);
    assert(~e.plan.cases(1).cfg.coding.enabled&&~e.plan.cases(1).cfg.receiver.equalizerEnabled);
    s=snrRun(cfg);check(s,simulationPlan(cfg,'snr'));
    s=mcsRun(cfg);check(s,simulationPlan(cfg,'mcs'));
    s=delaySpreadRun(cfg);check(s,simulationPlan(cfg,'delaySpread'));
    b=berRun(cfg);checkReports({b.experiments.awgn,b.experiments.tdl},simulationPlan(cfg,'ber'));
    b=rx_report_bler_graphs(cfg);
    checkReports({b.experiments.mcs,b.experiments.qpskDelaySpread,b.experiments.qam64DelaySpread},simulationPlan(cfg,'reportBler'));
    b=rx_report_mcs_separate(cfg);check(b.experiment,simulationPlan(cfg,'reportMcs'));
    b=plot_16qam_ber_vs_snr_ds(cfg);check(b,simulationPlan(cfg,'16qamDelay'));
    assert(isequal(before,rng));close all;
    summary=struct('defaultPlans',7,'runnersAndReports',7,'rngRestored',true,'fullConfigPreserved',true);
    fprintf('RUNTIME_SELF_TEST_PASS\n');
end
function check(r,p)
    assert(numel(r.totalPackets)==p.points);
    assert(sum(r.totalPackets(:))==p.transportBlocks&&sum(r.totalBits(:))==p.informationBits);
    assert(~r.cfg.coding.enabled&&~r.cfg.receiver.equalizerEnabled);
end
function checkReports(reports,p)
    blocks=0;bits=0;points=0;
    for k=1:numel(reports)
        r=reports{k};blocks=blocks+sum(r.totalPackets(:));bits=bits+sum(r.totalBits(:));points=points+numel(r.totalPackets);
        assert(~r.cfg.coding.enabled&&~r.cfg.receiver.equalizerEnabled);
    end
    assert(blocks==p.transportBlocks&&bits==p.informationBits&&points==p.points);
end
