function curveQualitySelfTest(outputDir)
    if nargin<1, outputDir=fullfile(tempdir,'curve-quality-tests'); end
    if ~exist(outputDir,'dir'), mkdir(outputDir); end
    c=config(); c.experiment.outputDir=outputDir;
    c.experiment.packetsPerPoint=3; c.experiment.verbose=false;
    c.experiment.modulations={'QPSK'}; c.experiment.snrTdlDb=[0 10 60];
    a=snrRun(c); saved=load(a.checkpointFile);
    assert(saved.results.complete && all(saved.results.completed(:)));
    assert(isequaln(saved.results.BER,a.BER));
    c.experiment.snrTdlDb=[60 0 10]; before=rng; b=snrRun(c);
    assert(isequal(before,rng));
    assert(isequal(a.bitErrors,b.bitErrors(:,[2 3 1])));
    assert(isequal(a.crcErrors,b.crcErrors(:,[2 3 1])));
    assert(all(a.totalPackets(:)==3));
    s=errorRateStatistics(0,10000,0,10,0,0);
    assert(abs(s.BLERZeroUpper95-(1-0.05^(1/10)))<1e-12);
    assert(s.BERZeroUpper95==s.BLERZeroUpper95 && isnan(s.BERUpper95));
    s=errorRateStatistics(150,4000,2,4,2,12500);
    assert(abs(s.BERStandardError-std([0 0 0.1 0.05])/sqrt(4))<1e-12);
    raw=a; a.BER=[0.1 0 0.001]; a.BLER=[1 0 1/3];
    legacy=legacyResultFields(a);
    assert(isnan(legacy.ber_plot(2)) && isnan(legacy.bler_plot(2)));
    f=berPlot(a); ax=findobj(f,'Type','axes'); curves=findobj(ax,'Type','line');
    assert(isequaln(get(curves(1),'YData'),[0.1 NaN 0.001]));
    close(f);
    f=blerPlot(raw,struct('showConfidence',true,'zeroDisplay','upperBound'));
    savePlot(f,outputDir,'confidence_check'); close(f);
    c=config(); p=frameParameters(c); c.modulation='64QAM'; q=frameParameters(c);
    assert(p.bits_per_symbol==2 && q.bits_per_symbol==6);
    c.coding.tbLength=16; q=frameParameters(c); assert(q.tb_len==16);
    c.fftSize=1024; q=frameParameters(c); assert(q.N==1024);
    c.coding.enabled=false; q=frameParameters(c); assert(~q.coding_enabled);
    c.receiver.equalizerEnabled=false; q=frameParameters(c); assert(~q.equalizer_enabled);
    bad=c; bad.fftSize=-1; rejected=false;
    try, config(bad); catch, rejected=true; end; assert(rejected);
    fprintf('CURVE_QUALITY_SELF_TEST_PASS\n');
end
