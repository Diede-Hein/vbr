
vbr_init
addpath(['vbr', filesep, 'testing'])
addpath(['Projects', filesep, 'vbr_core_examples'])

TestResults = run_tests();

if TestResults.failedCount > 0
    error('At least one test failed, check log.')
    quit(1)
elseif TestResults.n_tests == 0
    error('No tests collected.')
    quit(1)
end
