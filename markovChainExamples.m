close all

s1 = state('A', 1, [], []);
s2 = state('B', 2, [], []);
s3 = state('C', 3, [], []);
s4 = state('C', 4, [], []);
s5 = state('D', 5, [], []);
s6 = state('E', 6, [], []);

params.its = 200;
params.plotOn = true;
mod = markovChain({s1, s2, s3, s4, s5, s6}, params);
mod = mod.run(250);

return
mod = mod.addIterations(10);