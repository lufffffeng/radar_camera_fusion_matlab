%% Adaptive Cruise Control with Sensor Fusion
% This example shows how to implement a sensor fusion based automotive
% adaptive cruise controller for a vehicle traveling on a curved road using
% sensor fusion.
%
% In this example, you will:
%
% # Review a control system that combines sensor fusion and an adaptive
% cruise controller (ACC). Two variants of ACC are provided: a classical
% controller and a model predictive control (MPC) controller.
% # Test the control system in a closed-loop Simulink model using synthetic
% data generated by the Automated Driving System Toolbox.
% # Configure the code generation settings for Software-in-the-Loop
% simulation and automatically generate code for the control algorithm.
 
% Copyright 2017 The MathWorks, Inc.
 
 
%% Introduction
% An adaptive cruise control system is a control system that modifies the
% speed of the ego car in response to conditions on the road. As in regular
% cruise control, the driver sets a desired speed for the car; in addition,
% the adaptive cruise control system can slow the ego car down if there is
% another vehicle moving slower in the lane in front of it.
%
% For the ACC to work correctly, the ego car has to determine how the lane
% in front of it curves, and which car is the 'lead car', that is, in front
% of the ego car in the lane. A typical scenario from the viewpoint of the
% ego car is shown in the figure below. The ego car (blue) travels along a
% curved road. At the beginning, the lead car is the pink car. Then the
% purple car cuts into the lane of the ego car and becomes the lead car.
% After a while, the purple car changes to another lane and the pink car
% becomes the lead car again. The pink car remains the lead car afterwards.
% The ACC design must react to the change in the lead car on the road.
% 
% <<scenario.png>>
% 
% 
%% 
% Current ACC designs rely mostly on range and range rate measurements
% obtained from radar, and are designed to work best along straight roads.
% An example of such a system is given in
% <https://www.mathworks.com/examples/mpc/mw/mpc_featured-ex34380139-adaptive-cruise-control-system-using-model-predictive-control
% Adaptive Cruise Control System Using Model Predictive Control> and in
% <matlab:web(fullfile(docroot,'phased','examples','automotive-adaptive-cruise-control-using-fmcw-technology.html'))
% Automotive Adaptive Cruise Control Using FMCW Technology>. Moving from
% ADAS designs to more autonomous systems, the ACC must address the
% following challenges:
%
% # Estimating the relative positions and velocities of the cars that are
%   near the ego car and that have significant lateral motion relative to 
%   the ego car.
% # Estimating the lane ahead of the ego car to find which car in front of
% the ego car is the closest one in the same lane.
% # Reacting to aggressive maneuvers by other vehicles in the environment,
% in particular, when another vehicle cuts into the ego car lane.
%
%% 
% This example demonstrates two main additions to existing ACC designs that
% meet the challenges listed above: adding a sensor fusion system and
% updating the controller design based on model predictive control (MPC).
% A sensor fusion and tracking system that uses both vision and radar
% sensors provide the following benefits:
% 
% # It combines the better lateral measurement of position and velocity
% obtained from vision sensors with the range and range rate measurement
% from radar sensors.
% # A vision sensor can detect lanes, provide an estimate of the lateral
% position of the lane relative to the ego car, and position the other cars
% in the scene relative to the ego lane. In this example, we consider an
% ideal lane detection.
% 
% An advanced MPC controller adds the ability to react to more aggressive
% maneuvers by other vehicles in the environment. In contrast to a
% classical controller that uses a PID design with constant gains, the MPC
% controller regulates the velocity of the ego car while maintaining a
% strict safe distance constraint. Therefore, the controller can apply more
% aggressive maneuvers when the environment changes quickly in a similar
% way to what a human driver would do.
%
%% Overview of the Test Bench Model and Simulation Results
open_system('ACCTestBenchExample')
%%
% The model contains three main components:
% 
% # ACC with Sensor Fusion, which models the sensor fusion and controls the
% longitudinal acceleration of the vehicle. This component allows you to
% select either a classical or model predictive control version of the
% design.
% # A Vehicle and Environment subsystem, which models the motion of the ego 
% car and models the environment. A simulation of radar and vision sensors
% provides synthetic data to the control subsystem.
% # A Bird's-Eye Plot display, which plots the results of the simulation 
% and depicts the ego car's surrounding and tracked objects. 
%
%%
% Before running the model, in the Simulink model, click the *Run Setup
% Script* button to run the associated initialization script or type the
% next line in the command prompt.

%%
% 
%   helperACCSetUp
% 

helperACCSetUp;

%%
% The script loads certain constants needed by the Simulink model, such as
% the vehicle and ACC design parameters. The default ACC is the classical
% controller. The script also creates buses that are required for defining
% the inputs into and outputs for the control system referenced model.
% These buses must be defined in the workspace prior to model compilation.
% When the model compiles, additional Simulink buses are automatically
% generated by their respective blocks.

sim('ACCTestBenchExample','StopTime','15'); %Simulate 15 seconds to snap
snapnow
sim('ACCTestBenchExample'); %Simulate to end of scenario

%%
% The bird's-eye plot shows the results of the sensor fusion. It shows how
% the radar and vision sensors detect the vehicles within their sensors
% coverage areas. It also shows the tracks maintained by the Multi-Object
% Tracker block. The yellow track shows the most important object (MIO):
% the closest track in front of the ego car in its lane. We see that at the
% beginning of the scenario, the most important object is the fast-moving
% car ahead of the ego car. When the passing car gets closer to the
% slow-moving car, it crosses to the left lane, and the sensor fusion
% system recognizes it to be the MIO. This car is much closer to the ego
% car and much slower than it. Thus, the ACC must slow the ego car down.
%
%% 
% In the following results for the classical ACC system, the:
%%
% 
% * Top plot shows the ego car velocity.
% * Middle plot shows the relative distance between the ego car and lead
% car.
% * Bottom plot shows the ego car acceleration.
% 

% In this example, the raw data from the Tracking and Sensor Fusion system
% is used for ACC design without post-processing. You can expect to see
% some `spikes' (middle plot) due to the uncertainties in the sensor model
% especially when another car cuts into or leaves the ego car lane.
helperPlotACCResults(logsout);
%% 
%
% * In the first 11 seconds, the lead car is far ahead of the ego car
% (middle plot). The ego car accelerates and reaches the driver-set
% velocity V_set (top plot).
% * Another car becomes the lead car from 11 to 20 seconds when the car
% cuts into the ego car lane (middle plot). When the distance between the
% lead car and the ego car is large (11-15 seconds), the ego car still
% travels at the driver-set velocity. When the distance becomes small
% (15-20 seconds), the ego car decelerates to maintain a safe distance from
% the lead car (top plot).
% * From 20 to 34 seconds, the car in front moves to another lane, and a
% new lead car appears (middle plot). Because the distance between the lead
% car and the ego car is large, the ego car accelerates until it reaches
% the driver-set velocity at 27 seconds. After this, the ego car continues
% to travel at the driver-set velocity (top plot).
% * The bottom plot demonstrates that the acceleration is within the range
% [-3,2] m/s^2. The smooth transient behavior indicates that the driver
% comfort is satisfactory.

%% 
% In the MPC-based ACC design, the underlying optimization problem is
% formulated by tracking the driver-set velocity subject to enforcing a
% safe distance from the lead car. The MPC controller design is described
% in the Adaptive Cruise Controller section. The design is saved in
% |mpcACC.mat| . To run the model with the MPC design, first activate the
% MPC variant and then load the MPC controller using the following
% commands. This step requires Model Predictive Control Toolbox software.
%%
%
%   hasMPCLicense = license('checkout','mpc_toolbox');
%   if hasMPCLicense
%       controller_type = 2;
%       load mpcACC;
%       if isa(mpc1,'mpc') % The MPC controller was loaded correctly
%           sim('ACCTestBenchExample'); %Simulate to end of scenario
%       else
%           load data_mpc
%       end
%   end
%

hasMPCLicense = license('checkout','mpc_toolbox');
if hasMPCLicense
    controller_type = 2;
    load mpcACC;
    if isa(mpc1,'mpc') % The MPC controller was loaded correctly
        sim('ACCTestBenchExample','StopTime','15'); %Simulate 15 seconds to snap
        snapnow
        sim('ACCTestBenchExample'); %Simulate to end of scenario
    else
        load data_mpc
    end
end
 
%%
% In the simulation results for the MPC-based ACC, like for the classical
% ACC design, the objectives of speed and spacing control are achieved.
% Compared to the classical ACC design, the MPC-based ACC is more
% aggressive as it uses full throttle or braking for acceleration or
% deceleration. This behavior is due to the explicit constraint on the
% relative distance. The aggressive behavior may be preferred when sudden
% changes on the road occur, such as when the lead car changes to be a slow
% car. The controller can be less aggressive by increasing the weight in
% ManipulatedVariablesRate. As noted above, the spikes in the middle plot
% are due to the uncertainties in the sensor model.

helperPlotACCResults(logsout);

%% 
% In the following, the functions of each subsystem in the Test Bench Model
% are described in more details. The ACC with Sensor Fusion subsystem. It
% contains two main parts: 1) Tracking and sensor fusion and 2) Adaptive
% cruise controller.

open_system('ACCTestBenchExample/ACC with Sensor Fusion')
 
 
%% Tracking and Sensor Fusion
% The Tracking and Sensor Fusion subsystem processes vision and radar
% detections coming from the Vehicle and Environment subsystem and
% generates a comprehensive situation picture of the environment around the
% ego car. Also, it provides the ACC with an estimate of the closest car in
% the lane in front of the ego car.
 
open_system('ACCWithSensorFusion/Tracking and Sensor Fusion')
 
%%
% The main block of the Tracking and Sensor Fusion subsystem is the
% <matlab:web(fullfile(docroot,'driving','ref','multiobjecttracker.html'))
% Multi Object Tracker> block, whose inputs are the combined list of
% all the sensor detections and the prediction time. The output from the
% Multi-Object Tracker block is a list of confirmed tracks.
%
% The <matlab:web(fullfile(docroot,'driving','ref','detectionconcatenation.html'))
% Detection Concatenation> block concatenates the vision and radar
% detections. The prediction time is driven by a clock in the Vehicle and
% Environment subsystem.
%
% The Detection Clustering block clusters multiple radar
% detections, since the tracker expects at most one detection per object
% per sensor.
% 
% The |findLeadCar| MATLAB function block finds which car is closest to the
% ego car and ahead of it in same the lane using the list of confirmed
% tracks and the curvature of the road. This car is referred to as the lead
% car, and may change when cars move into and out of the lane in front of
% the ego car. The function provides the position and velocity of the lead
% car relative to the ego car as well as an index to the most important
% object (MIO) track.
 
%% Adaptive Cruise Controller
% The adaptive cruise controller has two variants: a classical (default)
% and an MPC-based design. For both designs, the following design
% principles are applied. An ACC equipped vehicle (ego car) uses sensor
% fusion to estimate the relative distance and relative velocity to the
% lead car. The ACC makes the ego car travel at a driver-set velocity while
% maintaining a safe distance from the lead car. The safe distance between
% lead car and ego car is defined as
%
% $D_{safe} = D_{default} + h \cdot V_x$
%
% where the default spacing $D_{default}$, and time gap $h$ are design
% parameters and $V_x$ is the longitudinal velocity of the ego car. The ACC
% generates the longitudinal acceleration for the ego car based on the
% following inputs:
%
% * Longitudinal velocity of ego car
% * Relative distance between lead car and ego car (from the Tracking and
% Sensor Fusion system)
% * Relative velocity between lead car and ego car (from the Tracking and
% Sensor Fusion system)
% 
% Considering the physical limitations of the ego car, the longitudinal
% acceleration is constrained to be within [-3,2] $m/s^2$.
 
%%
% In the classical ACC design, if the relative distance is less than the
% safe distance, then the primary goal is to slow down and maintain safe
% distance. If the relative distance is greater than the safe distance,
% then the primary goal is to reach driver-set velocity while maintaining a
% safe distance. These design principles are achieved through the Min and
% Switch Blocks.
open_system('ACCWithSensorFusion/Adaptive Cruise Controller/ACC Classical')
 
 
%% 
% In the MPC-based ACC design, the underlying optimization problem is
% formulated by tracking the driver-set velocity subject to a constraint.
% The constraint enforces that relative distance is always greater than
% safe distance.
% 
% <<optimizationEqn.png>>
% 
% More details on the MPC design for ACC can be found in
% <https://www.mathworks.com/examples/mpc/mw/mpc_featured-ex34380139-adaptive-cruise-control-system-using-model-predictive-control
% (Adaptive Cruise Control System Using Model Predictive Control)>. The
% nominal values and scaling factors have been modified according to the
% driving scenario when designing the MPC controller for this example. 
 
%% Vehicle and Environment
% The Vehicle and Environment subsystem is comprised of two parts: (1)
% Vehicle Dynamics and Global Coordinates and (2) Actor and Sensor
% Simulation.
open_system('ACCTestBenchExample/Vehicle and Environment')
 
%% 
% The vehicle dynamical model applies the ''bicycle mode'' of lateral
% vehicle dynamics and approximates the longitudinal dynamics using a time
% constant $\tau$.  The vehicle dynamics, with input $u$ (longitudinal
% acceleration) and front steering angle $\delta$, are described by:
% 
% <<dynamicsEqn.png>>
% 
% In the state vector, $V_y$ denotes the lateral velocity, $V_x$ denotes 
% the longitudinal velocity and $\psi$ denotes the yaw angle. The vehicle
% parameters are provided in the |helperACCSetUp| file.
 
%% 
% The outputs from the vehicle dynamics (such as longitudinal velocity
% $V_x$ and lateral velocity $V_y$) are based on body fixed coordinates. To
% obtain the trajectory traversed by the vehicle, the body fixed
% coordinates are converted into global coordinates through the following
% relations:
%
% $$\dot{X} = V_x\cos(\psi)-V_y\sin(\psi),\quad \dot{Y} = V_x\sin(\psi)+V_y\cos(\psi)$$
% 
% The yaw angle $\psi$ and yaw angle rate $\dot{\psi}$ are also converted
% into the units of degrees.
%% 
% The goal for the driver steering model is to keep the vehicle in its lane
% and follow the curved road by controlling the front steering angle $\delta$.
% This goal is achieved by driving the yaw angle error $e_2$ and lateral
% displacement error $e_1$ to zero (see the figure below), where
%
% $$\dot{e_1} = V_xe_2+V_y,\quad e_2 = \psi - \psi_{des}$$
%
% The desired yaw angle rate is given by $Vx/R$ ($R$ denotes the radius for
% the road curvature).
% 
% <<steeringError.png>>
% 
 
%% 
% The Actors and Sensor Simulation subsystem generates the synthetic sensor
% data required for tracking and sensor fusion. Prior to running this
% example, the
% <matlab:web(fullfile(docroot,'driving','ref','drivingscenario-class.html'))
% drivingScenario> was used to create a simulation environment with a
% curved road and multiple actors moving on the road. The scenario was
% saved to a file. To see how you can define the scenario, see the Scenario
% Authoring section.
open_system('ACCTestBenchExample/Vehicle and Environment/Actors and Sensor Simulation')
 
%%
% The motion of the ego car is controlled by the control system and is not
% recorded as part of the recorded scenario. Instead, the ego car position,
% velocity, yaw angle, and yaw rate are received as inputs from the Vehicle
% Dynamics block and are packed into a single actor pose structure using
% the |packEgo| MATLAB function block.

%%
% The Scenario Reader block reads the actor pose data and the road boundary
% data from the file that was used to save the scenario. The block converts
% both the actor poses and the road boundaries from scenario coordinates to
% the ego car coordinates. The actor poses are streamed on a bus generated
% by the block. In this example, you use a
% <matlab:web(fullfile(docroot,'driving','ref','visiondetectiongenerator.html'))
% Vision Detection Generator> block and
% <matlab:web(fullfile(docroot,'driving','ref','radardetectiongenerator.html'))
% Radar Detection Generator> block. Both sensors are long-range and
% forward-looking, and provide good coverage of the front of the ego car,
% as needed for ACC. The sensors use the actor poses in ego coordinates to
% generate lists of detections of the vehicles in front of the ego car.
% Finally, a clock block is used as an example of how the vehicle would
% have a centralized time source. The time is used by the Multi-Object
% Tracker block.
 
%% Scenario Authoring 
% The scenario was authored using the |helperScenarioAuthoring| function.
% To open the function, click on the *Edit Scenario* in the main
% model or run the following command to open the function:

%%
%
%   edit helperScenarioAuthoring
%
 
%%
% The function creates a <matlab:web(fullfile(docroot,'driving','ref','drivingscenario-class.html'))
% drivingScenario>. The driving scenario allows you to define roads and
% vehicles moving on the roads. For this example, you define two parallel
% roads of constant curvature. To define the road, you define the road
% centers, the road width, and banking angle (if needed). The road centers
% were chosen by sampling points along a circular arc, spanning a turn of
% 60 degrees of constant radius of curvature.
%
% You define all the other vehicles in the scenario, excluding the ego car
% to be controlled by the model. To define the motion of the vehicles, you
% define their path by a set of waypoints and speeds. A quick way to define
% the waypoints is by choosing a subset of the road centers defined
% earlier, with an offset to the left or right of the road centers to
% control the lane in which the vehicles travel.
% 
% This example shows 4 vehicles: a fast-moving car in the left lane, a
% slow-moving car in the right lane, a car approaching on the opposite side
% of the road, and a car that starts on the right lane, but then moves to
% the left lane to pass the slow-moving car.
% 
% Finally, the driving scenario must be saved to a file. The function uses
% the
% <matlab:web(fullfile(docroot,'driving','ref','drivingscenario.record.html'))
% drivingScenario/record> method to obtain the actor poses relative to the
% scenario coordinates at every sample time. The function obtains the road
% boundaries as a cell array using the
% <matlab:web(fullfile(docroot,'driving','ref','roadboundaries.html'))
% drivingScenario/roadBoundaries> function. Due to code generation
% limitations, it then converts the cell array to a structure to allow it
% to be loaded by the Scenario Reader block.
%
% This |helperScenarioAuthoring| allows you to:
% 
% # Modify the road radius of curvature, which is the first input to the
% function. The default is |760| meters.
% # Modify the file name used when saving the driving scenario. The default
% is |'scenario'| .
% # Visualize the scenario by setting the third input to the helper
% function to |true| . The default is |false| . You can edit the helper
% function and create your own scenarios.
%%
% 
% <<ACCScenario.png>>
% 

 
%% Generating Code for the Control Algorithm 
% The |ACCWithSensorFusion| model is configured to support generating C
% code using <matlab:web(fullfile(docroot,'ecoder','index.html')) Embedded
% Coder>. To check if you have access to Embedded Coder , run:

%%
%
%   hasEmbeddedCoderLicense = license('checkout','RTW_Embedded_Coder')
%

%%
% By default, Embedded Coder disables dynamic memory allocation in MATLAB
% Function blocks. However, the Multi-Object Tracker block used in this
% design requires dynamic memory allocation. You can verify that this
% option is enabled by running:

%%
%
%   get_param('ACCTestBenchExample','MATLABDynamicMemAlloc')
%

%%
% You can generate a C function for the model and explore the code
% generation report by running:

%%
%
%   if hasEmbeddedCoderLicense
%       rtwbuild('ACCWithSensorFusion')
%   end
%
 
%%
% You can verify that the compiled C code behaves as expected using
% Software-In-the-Loop (SIL) simulation. To simulate the
% |ACCWithSensorFusion| referenced model in SIL mode, use:

%%
%
%   if hasEmbeddedCoderLicense
%       set_param('ACCTestBenchExample/ACC with Sensor Fusion',...
%           'SimulationMode','Software-in-the-loop (SIL)')
%   end
%
 
%%
% When you run the |ACCTestBenchExample| model, code is generated,
% compiled, and executed for the |ACCWithSensorFusion| model. This enables
% you to test the behavior of the compiled code through simulation.
 
%% Conclusions
% This example shows how to implement an integrated adaptive cruise
% controller (ACC) on a curved road with sensor fusion, test it in Simulink
% using synthetic data generated by the Automated Driving System Toolbox,
% componentize it, and automatically generate code for it.

controller_type = 1; % Set the variant back to be classical ACC
bdclose all;