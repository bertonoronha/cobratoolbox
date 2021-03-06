% The COBRAToolbox: testMOMA.m
%
% Purpose:
%     - tests the functions of MOMA and linearMOMA based on the paper
%       "Analysis of optimality in natural and perturbed metabolic networks"
%       (http://www.pnas.org/content/99/23/15112.full)
%       MOMA employs quadratic programming to identify a point in flux space,
%       which is closest to the wild-type point, compatibly with the gene deletion constraint.
%       In other words, through MOMA, we test the hypothesis that the real
%       knockout steady state is better approximated by the flux minimal
%       response to the perturbation than by the optimal one
%
% Authors:
%     - Adapted by MBG - 02/10/2017
%     - CI integration: Laurent Heirendt February 2017
%
% Note:
%     - A valid QP solver must be available

global CBTDIR

% save the current path
currentDir = pwd;

% initialize the test
fileDir = fileparts(which('testMOMA'));
cd(fileDir);

% load model
model = getDistributedModel('ecoli_core_model.mat');

% test solver packages
solverPkgs = {'mosek', 'ibm_cplex', 'tomlab_cplex', 'gurobi'};

% define solver tolerances
QPtol = 0.02;
LPtol = 0.0001;

for k = 1:length(solverPkgs)
    fprintf(' -- Running testMOMA using the solver interface: %s ... ', solverPkgs{k});

    solverQPOK = changeCobraSolver(solverPkgs{k}, 'QP', 0);
    solverLPOK = changeCobraSolver(solverPkgs{k}, 'LP', 0);

    if solverLPOK && solverQPOK
        % test deleteModelGenes
        [modelOut, hasEffect, constrRxnNames, deletedGenes] = deleteModelGenes(model, 'b3956'); % gene for reaction PPC

        % run MOMA
        sol = MOMA(model, modelOut);

        if sol.stat == 1
            assert(abs(0.8463 - sol.f) < QPtol)
        end
        
        % run linearMOMA
        sol = linearMOMA(model, modelOut);

        assert(abs(0.8608 - sol.f) < LPtol)
        
        %run linear moma with minimal fluxes
        solMin = linearMOMA(model, modelOut,'max',1);
        assert(abs(0.8608 - solMin.f) < LPtol)
        
        %We know that at least in this case, the flux sum is actually
        %smaller.
        assert(sum(abs(sol.x)) > sum(abs(solMin.x)))
    else
        fprintf('\nMOMA requires a QP solver to be installed. QPNG does not work.\n');
    end

    % output a success message
    fprintf('Done.\n');
end

%return to original directory
cd(currentDir)
